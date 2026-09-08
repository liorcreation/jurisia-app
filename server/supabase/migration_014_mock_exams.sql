-- À exécuter une fois dans le SQL Editor de votre projet Supabase — met en
-- place l'examen blanc de fin de niveau (distinct du quiz de fin de module
-- existant) : historique des tentatives et verrou de réécriture de 7 jours
-- en cas d'échec. Sans risque à réexécuter (idempotent).
--
-- Tant que cette migration n'est pas appliquée, l'application continue de
-- fonctionner : la génération et la correction de l'examen restent
-- fonctionnelles côté client, mais le verrou n'est pas persisté (repository
-- silencieux, voir MockExamRepositoryImpl._persistenceEnabled).

create table if not exists public.student_mock_exam_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  level_id text not null,
  mode text not null check (mode in ('qcm_timed', 'written', 'oral')),
  score numeric not null,
  passed boolean not null,
  created_at timestamptz not null default now()
);

alter table public.student_mock_exam_attempts enable row level security;

drop policy if exists "Un utilisateur lit ses propres tentatives d'examen blanc" on public.student_mock_exam_attempts;
create policy "Un utilisateur lit ses propres tentatives d'examen blanc"
  on public.student_mock_exam_attempts for select
  using (auth.uid() = user_id);

-- Aucune politique insert/update/delete depuis le client : tout passe par
-- jurisia_record_mock_exam_result ci-dessous, pour empêcher un client de
-- fabriquer sa propre réussite.

create table if not exists public.student_mock_exam_state (
  user_id uuid not null references auth.users (id) on delete cascade,
  level_id text not null,
  locked_until timestamptz,
  requires_course_review boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, level_id)
);

alter table public.student_mock_exam_state enable row level security;

drop policy if exists "Un utilisateur lit son propre verrou d'examen blanc" on public.student_mock_exam_state;
create policy "Un utilisateur lit son propre verrou d'examen blanc"
  on public.student_mock_exam_state for select
  using (auth.uid() = user_id);

-- Aucune politique d'écriture cliente ici non plus — le verrou (délai de 7
-- jours, obligation de reconsulter le cours) n'est levé que par les deux RPC
-- security definer suivantes, jamais par un upsert direct du client.

-- ---------------------------------------------------------------------
-- Fonctions RPC appelées par le client
-- (lib/features/student/data/repositories/mock_exam_repository_impl.dart)
-- ---------------------------------------------------------------------

-- Enregistre le résultat final d'une tentative corrigée et applique, côté
-- serveur, le verrou de 7 jours en cas d'échec (score < 10/20).
create or replace function public.jurisia_record_mock_exam_result(
  p_level_id text, p_mode text, p_score numeric
) returns jsonb as $$
declare
  v_passed boolean := p_score >= 10;
begin
  if auth.uid() is null then
    raise exception 'non authentifié';
  end if;

  insert into public.student_mock_exam_attempts (user_id, level_id, mode, score, passed)
  values (auth.uid(), p_level_id, p_mode, p_score, v_passed);

  insert into public.student_mock_exam_state (user_id, level_id, locked_until, requires_course_review)
  values (
    auth.uid(), p_level_id,
    case when v_passed then null else now() + interval '168 hours' end,
    not v_passed
  )
  on conflict (user_id, level_id) do update set
    locked_until = excluded.locked_until,
    requires_course_review = excluded.requires_course_review,
    updated_at = now();

  return jsonb_build_object('passed', v_passed);
end;
$$ language plpgsql volatile security definer set search_path = public;

-- À appeler dès que l'étudiant reconsulte le cours d'un module du niveau
-- concerné après un échec (voir ModuleDetailScreen). Sans effet sur le délai
-- de 7 jours lui-même — les deux conditions du verrou sont indépendantes et
-- doivent être levées séparément.
create or replace function public.jurisia_mark_course_reviewed(p_level_id text)
returns void as $$
begin
  if auth.uid() is null then
    raise exception 'non authentifié';
  end if;

  update public.student_mock_exam_state
    set requires_course_review = false, updated_at = now()
    where user_id = auth.uid() and level_id = p_level_id;
end;
$$ language plpgsql volatile security definer set search_path = public;
