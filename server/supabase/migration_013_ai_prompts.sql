-- À exécuter une fois dans le SQL Editor de votre projet Supabase — pose le
-- Studio de prompts : les instructions système de l'IA (Litige, Tuteur,
-- Rédaction/Audit/Consultation) deviennent modifiables sans déploiement de
-- code, avec un test obligatoire avant toute publication. Sans risque à
-- réexécuter (idempotent). Nécessite migration_006 (rôles,
-- jurisia_is_staff/jurisia_has_role) et migration_008 (jurisia_admin_log).
--
-- Tant que cette migration n'est pas appliquée (ou que la ligne `published`
-- d'une clé n'existe pas), l'application continue de fonctionner
-- normalement : elle utilise sa constante Dart codée en dur — voir
-- lib/core/ai/ (à brancher lors de l'implémentation cliente).

create table if not exists public.ai_prompts (
  id            uuid primary key default gen_random_uuid(),
  key           text not null,   -- 'litige.system' | 'tuteur.system' | 'redaction.system' | 'audit.system' | 'consultation.system' ...
  content       text not null,
  status        text not null default 'draft'
    check (status in ('draft', 'tested', 'published', 'archived')),
  test_message  text,
  test_response text,
  tested_at     timestamptz,
  created_by    uuid references auth.users (id),
  approved_by   uuid references auth.users (id),
  approved_at   timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists ai_prompts_key_idx    on public.ai_prompts (key);
create index if not exists ai_prompts_status_idx on public.ai_prompts (status);

-- Une seule version publiée par clé à la fois.
drop index if exists ai_prompts_one_published_per_key;
create unique index ai_prompts_one_published_per_key
  on public.ai_prompts (key) where status = 'published';

alter table public.ai_prompts enable row level security;

-- Le prompt ACTIF d'une clé est lisible par n'importe qui (c'est ce que
-- l'app charge au démarrage d'une conversation) ; les brouillons ne le
-- sont que par le personnel.
drop policy if exists "Le prompt publié est public" on public.ai_prompts;
create policy "Le prompt publié est public"
  on public.ai_prompts for select
  using (status = 'published');

drop policy if exists "Le personnel lit tous les prompts" on public.ai_prompts;
create policy "Le personnel lit tous les prompts"
  on public.ai_prompts for select
  using (public.jurisia_is_staff());

-- Aucune politique insert/update/delete : toute écriture passe par les
-- fonctions ci-dessous.

-- ---------------------------------------------------------------------
-- Lecture avec e-mails résolus, pour la console.
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_list_prompts()
returns table (
  id             uuid,
  key            text,
  content        text,
  status         text,
  test_message   text,
  test_response  text,
  tested_at      timestamptz,
  created_by     uuid,
  created_by_email  text,
  approved_by    uuid,
  approved_by_email text,
  approved_at    timestamptz,
  created_at     timestamptz,
  updated_at     timestamptz
) as $$
begin
  if not public.jurisia_is_staff() then
    raise exception 'réservé au personnel';
  end if;

  return query
    select
      p.id, p.key, p.content, p.status, p.test_message, p.test_response, p.tested_at,
      p.created_by, cu.email::text,
      p.approved_by, au.email::text,
      p.approved_at, p.created_at, p.updated_at
    from public.ai_prompts p
    left join auth.users cu on cu.id = p.created_by
    left join auth.users au on au.id = p.approved_by
    order by p.key, p.updated_at desc;
end;
$$ language plpgsql stable security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Créer / mettre à jour un brouillon de prompt. Toute modification du
-- contenu invalide un test précédent (repasse en 'draft', tested_at effacé)
-- — un texte testé doit rester exactement le texte publié.
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_save_prompt_draft(
  p_draft_id uuid,
  p_key text,
  p_content text
)
returns uuid as $$
declare
  v_id uuid;
  v_status text;
begin
  if not public.jurisia_can_edit_content() then
    raise exception 'réservé aux éditeurs de contenu';
  end if;
  if p_key is null or trim(p_key) = '' then
    raise exception 'clé de prompt requise';
  end if;

  if p_draft_id is null then
    insert into public.ai_prompts (key, content, created_by)
      values (p_key, p_content, auth.uid())
      returning id into v_id;

    perform public.jurisia_admin_log(
      'ai_prompt.create', 'ai_prompts', v_id::text, null, jsonb_build_object('key', p_key), null
    );
    return v_id;
  end if;

  select status into v_status from public.ai_prompts where id = p_draft_id;
  if v_status is null then
    raise exception 'brouillon introuvable';
  end if;
  if v_status = 'published' then
    raise exception 'un prompt publié ne se modifie pas directement — repartir d''un nouveau brouillon';
  end if;

  update public.ai_prompts
    set content = p_content, status = 'draft', tested_at = null,
        test_message = null, test_response = null, updated_at = now()
    where id = p_draft_id;

  perform public.jurisia_admin_log(
    'ai_prompt.update', 'ai_prompts', p_draft_id::text, null, jsonb_build_object('key', p_key), null
  );
  return p_draft_id;
end;
$$ language plpgsql volatile security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Enregistrer un test (l'appel au modèle se fait côté client, avec le
-- contenu du brouillon comme prompt système — cette fonction se contente
-- d'archiver le résultat et de faire passer le brouillon en 'tested').
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_record_prompt_test(
  p_draft_id uuid,
  p_test_message text,
  p_test_response text
)
returns void as $$
declare
  v_status text;
begin
  if not public.jurisia_can_edit_content() then
    raise exception 'réservé aux éditeurs de contenu';
  end if;

  select status into v_status from public.ai_prompts where id = p_draft_id;
  if v_status is null then
    raise exception 'brouillon introuvable';
  end if;
  if v_status = 'published' then
    raise exception 'ce prompt est déjà publié';
  end if;

  update public.ai_prompts
    set status = 'tested', test_message = p_test_message, test_response = p_test_response,
        tested_at = now(), updated_at = now()
    where id = p_draft_id;

  perform public.jurisia_admin_log('ai_prompt.test', 'ai_prompts', p_draft_id::text, null, null, null);
end;
$$ language plpgsql volatile security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Publier — réservé à super_admin (le risque touche tous les
-- utilisateurs, immédiatement, pas un seul texte comme au CMS
-- Bibliothèque). Exige qu'un test ait déjà été enregistré un jour
-- (tested_at non nul), ce qui couvre aussi la republication d'une
-- version archivée sans repasser par une nouvelle relecture.
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_publish_prompt_draft(p_draft_id uuid)
returns void as $$
declare
  v_prompt public.ai_prompts;
begin
  if not public.jurisia_has_role('super_admin') then
    raise exception 'réservé aux super administrateurs';
  end if;

  select * into v_prompt from public.ai_prompts where id = p_draft_id;
  if v_prompt.id is null then
    raise exception 'prompt introuvable';
  end if;
  if v_prompt.tested_at is null then
    raise exception 'ce prompt n''a jamais été testé';
  end if;

  update public.ai_prompts
    set status = 'archived', updated_at = now()
    where key = v_prompt.key and status = 'published';

  update public.ai_prompts
    set status = 'published', approved_by = auth.uid(), approved_at = now(), updated_at = now()
    where id = p_draft_id;

  perform public.jurisia_admin_log(
    'ai_prompt.publish', 'ai_prompts', p_draft_id::text, null, jsonb_build_object('key', v_prompt.key), null
  );
end;
$$ language plpgsql volatile security definer set search_path = public;
