-- Schéma JurisIA — comptes, conversations, favoris, progression étudiante,
-- résultats de rédaction professionnelle.
--
-- À exécuter une fois dans l'éditeur SQL du tableau de bord Supabase
-- (Project > SQL Editor > New query), ou via `supabase db push` si vous
-- utilisez la CLI Supabase.
--
-- Chaque table a la sécurité au niveau des lignes (RLS) activée : un
-- utilisateur ne peut lire/écrire que ses propres données. C'est cette
-- politique — pas le secret de la clé publique du projet — qui protège les
-- données, conformément au modèle de sécurité de Supabase.

-- ---------------------------------------------------------------------
-- Profils (une ligne par utilisateur, créée automatiquement à l'inscription)
-- ---------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  terms_accepted_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Un utilisateur lit son propre profil"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Un utilisateur modifie son propre profil"
  on public.profiles for update
  using (auth.uid() = id);

-- Crée automatiquement la ligne de profil à l'inscription.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- Module 01 — Litiges et consultations
-- ---------------------------------------------------------------------

create table if not exists public.litigation_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null default 'Nouvelle consultation',
  domain text,
  complexity text,
  analysis_grid jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.litigation_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.litigation_conversations (id) on delete cascade,
  sender text not null check (sender in ('user', 'assistant')),
  content text not null,
  suggested_professional text,
  created_at timestamptz not null default now()
);

alter table public.litigation_conversations enable row level security;
alter table public.litigation_messages enable row level security;

create policy "Un utilisateur gère ses propres consultations"
  on public.litigation_conversations for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Un utilisateur gère les messages de ses propres consultations"
  on public.litigation_messages for all
  using (
    exists (
      select 1 from public.litigation_conversations c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.litigation_conversations c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- Module 02 — Bibliothèque juridique
-- ---------------------------------------------------------------------

create table if not exists public.library_favorites (
  user_id uuid not null references auth.users (id) on delete cascade,
  document_id text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, document_id)
);

-- Compteur de téléchargements global par document (pas de valeur ajoutée à
-- le suivre par utilisateur pour l'instant).
create table if not exists public.library_document_stats (
  document_id text primary key,
  download_count integer not null default 0
);

alter table public.library_favorites enable row level security;
alter table public.library_document_stats enable row level security;

create policy "Un utilisateur gère ses propres favoris"
  on public.library_favorites for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Tout le monde peut lire les statistiques de téléchargement"
  on public.library_document_stats for select
  using (true);

create policy "Tout utilisateur authentifié peut incrémenter les téléchargements"
  on public.library_document_stats for insert
  with check (auth.uid() is not null);

create policy "Tout utilisateur authentifié peut mettre à jour les téléchargements"
  on public.library_document_stats for update
  using (auth.uid() is not null);

-- Incrément atomique (évite la course entre deux appareils qui liraient puis
-- réécriraient la même valeur de compteur en parallèle).
create or replace function public.increment_download_count(doc_id text)
returns void as $$
begin
  insert into public.library_document_stats (document_id, download_count)
  values (doc_id, 1)
  on conflict (document_id)
  do update set download_count = public.library_document_stats.download_count + 1;
end;
$$ language plpgsql security invoker set search_path = public;

-- ---------------------------------------------------------------------
-- Module 03 — Espace étudiant
-- ---------------------------------------------------------------------

create table if not exists public.student_module_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  module_id text not null,
  is_unlocked boolean not null default false,
  is_completed boolean not null default false,
  best_score numeric,
  attempts_count integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, module_id)
);

create table if not exists public.student_evaluation_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  module_id text not null,
  attempt_number integer not null,
  score numeric not null,
  created_at timestamptz not null default now()
);

alter table public.student_module_progress enable row level security;
alter table public.student_evaluation_attempts enable row level security;

create policy "Un utilisateur gère sa propre progression"
  on public.student_module_progress for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Un utilisateur gère ses propres tentatives d'évaluation"
  on public.student_evaluation_attempts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- Module 04 — Espace professionnel
-- ---------------------------------------------------------------------

create table if not exists public.professional_drafting_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  mode text not null check (mode in ('redaction', 'audit', 'consultation')),
  title text not null,
  content text not null,
  risks jsonb not null default '[]'::jsonb,
  cited_sources jsonb not null default '[]'::jsonb,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.professional_drafting_results enable row level security;

create policy "Un utilisateur gère ses propres documents générés"
  on public.professional_drafting_results for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
