-- À exécuter une fois dans le SQL Editor de votre projet Supabase — pose le
-- circuit de relecture du futur CMS Bibliothèque : un texte importé ou
-- corrigé vit dans un brouillon séparé (legal_document_drafts) jusqu'à son
-- approbation par un legal_reviewer, qui seule le recopie dans les tables
-- lues par l'app (legal_documents / legal_articles, migration_010). Le
-- corpus déjà publié n'est donc jamais retiré ni bloqué pendant qu'une
-- correction est en relecture. Sans risque à réexécuter (idempotent).
-- Nécessite migration_006 (rôles, jurisia_is_staff/jurisia_has_role),
-- migration_008 (jurisia_admin_log) et migration_010 (legal_documents).
--
-- Forme de `payload` : identique au JSON produit par
-- `tools/legal_import` (ImportedDocument.toJson()) — un brouillon saisi à
-- la main dans la console et un texte sorti du pipeline en ligne de
-- commande sont donc interchangeables.

-- ---------------------------------------------------------------------
-- Brouillons
-- ---------------------------------------------------------------------

create table if not exists public.legal_document_drafts (
  id             uuid primary key default gen_random_uuid(),
  document_id    text not null,  -- correspond à payload->>'id' ; peut être un texte déjà publié (correction) ou nouveau
  status         text not null default 'draft'
    check (status in ('draft', 'in_review', 'changes_requested', 'published', 'archived')),
  payload        jsonb not null,
  created_by     uuid references auth.users (id),
  submitted_at   timestamptz,
  reviewed_by    uuid references auth.users (id),
  reviewed_at    timestamptz,
  review_reason  text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index if not exists legal_document_drafts_document_idx on public.legal_document_drafts (document_id);
create index if not exists legal_document_drafts_status_idx   on public.legal_document_drafts (status);

alter table public.legal_document_drafts enable row level security;

drop policy if exists "Le personnel lit les brouillons" on public.legal_document_drafts;
create policy "Le personnel lit les brouillons"
  on public.legal_document_drafts for select
  using (public.jurisia_is_staff());

-- Aucune politique insert/update/delete : toute écriture passe par les
-- fonctions ci-dessous, qui vérifient elles-mêmes l'appelant et tracent
-- chaque transition au journal d'audit.

-- ---------------------------------------------------------------------
-- Lecture avec e-mails résolus (auth.users n'est pas exposé au client).
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_list_document_drafts()
returns table (
  id             uuid,
  document_id    text,
  status         text,
  payload        jsonb,
  created_by     uuid,
  created_by_email    text,
  submitted_at   timestamptz,
  reviewed_by    uuid,
  reviewed_by_email   text,
  reviewed_at    timestamptz,
  review_reason  text,
  created_at     timestamptz,
  updated_at     timestamptz
) as $$
begin
  if not public.jurisia_is_staff() then
    raise exception 'réservé au personnel';
  end if;

  return query
    select
      d.id, d.document_id, d.status, d.payload,
      d.created_by, cu.email::text,
      d.submitted_at,
      d.reviewed_by, ru.email::text,
      d.reviewed_at, d.review_reason,
      d.created_at, d.updated_at
    from public.legal_document_drafts d
    left join auth.users cu on cu.id = d.created_by
    left join auth.users ru on ru.id = d.reviewed_by
    order by d.updated_at desc;
end;
$$ language plpgsql stable security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Garde-fou partagé : qui a le droit de rédiger un texte (mais pas de le
-- publier seul) — content_editor, legal_reviewer, admin, super_admin.
-- ---------------------------------------------------------------------

create or replace function public.jurisia_can_edit_content()
returns boolean as $$
  select public.jurisia_has_role('content_editor')
      or public.jurisia_has_role('legal_reviewer')
      or public.jurisia_has_role('admin')
      or public.jurisia_has_role('super_admin');
$$ language sql stable security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Créer / mettre à jour un brouillon. p_draft_id NULL → nouveau brouillon.
-- Un brouillon déjà en relecture (in_review) ou publié ne se modifie plus
-- directement : il faut d'abord un rejet (changes_requested) ou repartir
-- d'un nouveau brouillon.
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_save_document_draft(
  p_draft_id uuid,
  p_document_id text,
  p_payload jsonb
)
returns uuid as $$
declare
  v_id uuid;
  v_status text;
begin
  if not public.jurisia_can_edit_content() then
    raise exception 'réservé aux éditeurs de contenu';
  end if;

  if p_draft_id is null then
    insert into public.legal_document_drafts (document_id, payload, created_by)
      values (p_document_id, p_payload, auth.uid())
      returning id into v_id;

    perform public.jurisia_admin_log(
      'document_draft.create', 'legal_document_drafts', v_id::text,
      null, jsonb_build_object('document_id', p_document_id), null
    );
    return v_id;
  end if;

  select status into v_status from public.legal_document_drafts where id = p_draft_id;
  if v_status is null then
    raise exception 'brouillon introuvable';
  end if;
  if v_status not in ('draft', 'changes_requested') then
    raise exception 'ce brouillon n''est plus modifiable (statut : %)', v_status;
  end if;

  update public.legal_document_drafts
    set payload = p_payload, updated_at = now()
    where id = p_draft_id;

  perform public.jurisia_admin_log(
    'document_draft.update', 'legal_document_drafts', p_draft_id::text,
    null, jsonb_build_object('document_id', p_document_id), null
  );
  return p_draft_id;
end;
$$ language plpgsql volatile security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Soumettre à la relecture.
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_submit_document_draft(p_draft_id uuid)
returns void as $$
declare
  v_status text;
begin
  if not public.jurisia_can_edit_content() then
    raise exception 'réservé aux éditeurs de contenu';
  end if;

  select status into v_status from public.legal_document_drafts where id = p_draft_id;
  if v_status is null then
    raise exception 'brouillon introuvable';
  end if;
  if v_status not in ('draft', 'changes_requested') then
    raise exception 'ce brouillon ne peut pas être soumis (statut : %)', v_status;
  end if;

  update public.legal_document_drafts
    set status = 'in_review', submitted_at = now(), updated_at = now()
    where id = p_draft_id;

  perform public.jurisia_admin_log(
    'document_draft.submit', 'legal_document_drafts', p_draft_id::text,
    jsonb_build_object('status', v_status), jsonb_build_object('status', 'in_review'), null
  );
end;
$$ language plpgsql volatile security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Relire : approuver (recopie dans legal_documents/legal_articles) ou
-- renvoyer en correction avec un motif obligatoire. Réservé à
-- legal_reviewer / admin / super_admin — pas content_editor.
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_review_document_draft(
  p_draft_id uuid,
  p_decision text,
  p_reason text default null
)
returns void as $$
declare
  v_draft public.legal_document_drafts;
  v_payload jsonb;
  v_doc_id text;
begin
  if not (public.jurisia_has_role('legal_reviewer')
       or public.jurisia_has_role('admin')
       or public.jurisia_has_role('super_admin')) then
    raise exception 'réservé aux relecteurs';
  end if;
  if p_decision not in ('approve', 'request_changes') then
    raise exception 'décision invalide : %', p_decision;
  end if;

  select * into v_draft from public.legal_document_drafts where id = p_draft_id;
  if v_draft.id is null then
    raise exception 'brouillon introuvable';
  end if;
  if v_draft.status <> 'in_review' then
    raise exception 'ce brouillon n''est pas en relecture (statut : %)', v_draft.status;
  end if;

  if p_decision = 'request_changes' then
    if p_reason is null or trim(p_reason) = '' then
      raise exception 'un motif est obligatoire pour renvoyer en correction';
    end if;
    update public.legal_document_drafts
      set status = 'changes_requested', reviewed_by = auth.uid(), reviewed_at = now(),
          review_reason = p_reason, updated_at = now()
      where id = p_draft_id;

    perform public.jurisia_admin_log(
      'document_draft.request_changes', 'legal_document_drafts', p_draft_id::text,
      null, null, p_reason
    );
    return;
  end if;

  -- decision = 'approve' : recopie payload -> legal_documents + legal_articles.
  v_payload := v_draft.payload;
  v_doc_id := coalesce(v_payload->>'id', v_draft.document_id);

  insert into public.legal_documents (
    id, title, type, domain, reference, date_publication, date_entree_en_vigueur,
    status, summary, full_content, outline, summary_only, official_source_name,
    source_url, tags, related_ids, imported_at
  ) values (
    v_doc_id,
    v_payload->>'title',
    v_payload->>'type',
    v_payload->>'domain',
    coalesce(v_payload->>'reference', ''),
    nullif(v_payload->>'date_publication', '')::date,
    nullif(v_payload->>'date_entree_en_vigueur', '')::date,
    coalesce(v_payload->>'status', 'enVigueur'),
    coalesce(v_payload->>'summary', ''),
    coalesce(v_payload->>'full_content', ''),
    coalesce((select array_agg(x) from jsonb_array_elements_text(coalesce(v_payload->'outline', '[]'::jsonb)) x), '{}'),
    coalesce((v_payload->>'summary_only')::boolean, false),
    v_payload->>'official_source_name',
    v_payload->>'source_url',
    coalesce((select array_agg(x) from jsonb_array_elements_text(coalesce(v_payload->'tags', '[]'::jsonb)) x), '{}'),
    coalesce((select array_agg(x) from jsonb_array_elements_text(coalesce(v_payload->'related_ids', '[]'::jsonb)) x), '{}'),
    now()
  )
  on conflict (id) do update set
    title = excluded.title,
    type = excluded.type,
    domain = excluded.domain,
    reference = excluded.reference,
    date_publication = excluded.date_publication,
    date_entree_en_vigueur = excluded.date_entree_en_vigueur,
    status = excluded.status,
    summary = excluded.summary,
    full_content = excluded.full_content,
    outline = excluded.outline,
    summary_only = excluded.summary_only,
    official_source_name = excluded.official_source_name,
    source_url = excluded.source_url,
    tags = excluded.tags,
    related_ids = excluded.related_ids,
    imported_at = excluded.imported_at;

  delete from public.legal_articles where document_id = v_doc_id;
  insert into public.legal_articles (document_id, ord, number, heading, body, path)
  select
    v_doc_id,
    (row_number() over ()) - 1,
    a->>'number',
    coalesce(a->>'heading', ''),
    a->>'body',
    coalesce((select array_agg(x) from jsonb_array_elements_text(coalesce(a->'path', '[]'::jsonb)) x), '{}')
  from jsonb_array_elements(coalesce(v_payload->'articles', '[]'::jsonb)) a;

  update public.legal_document_drafts
    set status = 'published', reviewed_by = auth.uid(), reviewed_at = now(),
        review_reason = null, updated_at = now()
    where id = p_draft_id;

  perform public.jurisia_admin_log(
    'document_draft.approve', 'legal_documents', v_doc_id,
    null, jsonb_build_object('draft_id', p_draft_id), null
  );
end;
$$ language plpgsql volatile security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Archiver un texte publié (abrogé / remplacé) — le texte reste visible,
-- marqué comme tel (réutilise la colonne `status` existante de
-- legal_documents, voir migration_010).
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_archive_document(
  p_document_id text,
  p_reason text default null
)
returns void as $$
begin
  if not (public.jurisia_has_role('legal_reviewer')
       or public.jurisia_has_role('admin')
       or public.jurisia_has_role('super_admin')) then
    raise exception 'réservé aux relecteurs';
  end if;

  update public.legal_documents set status = 'abroge' where id = p_document_id;
  if not found then
    raise exception 'texte introuvable : %', p_document_id;
  end if;

  perform public.jurisia_admin_log(
    'document.archive', 'legal_documents', p_document_id,
    null, jsonb_build_object('status', 'abroge'), p_reason
  );
end;
$$ language plpgsql volatile security definer set search_path = public;
