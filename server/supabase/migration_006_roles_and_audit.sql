-- À exécuter une fois dans le SQL Editor de votre projet Supabase — pose les
-- fondations de la future console d'administration séparée : rôles de
-- personnel (« staff ») et journal d'audit immuable. Sans risque à
-- réexécuter (idempotent). Aucune application cliente n'en dépend encore ;
-- cette migration peut être appliquée maintenant ou différée.

-- ---------------------------------------------------------------------
-- Rôles de personnel
-- ---------------------------------------------------------------------

create table if not exists public.staff_roles (
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in (
    'super_admin', 'admin', 'content_editor', 'legal_reviewer',
    'partner_manager', 'support_agent', 'analyst'
  )),
  granted_by uuid references auth.users (id),
  granted_at timestamptz not null default now(),
  primary key (user_id, role)
);

alter table public.staff_roles enable row level security;

-- Fonctions d'appartenance, en SECURITY DEFINER pour éviter la récursion RLS
-- (une politique qui interrogerait staff_roles se rappellerait elle-même).
create or replace function public.jurisia_has_role(target_role text)
returns boolean as $$
  select exists (
    select 1 from public.staff_roles
    where user_id = auth.uid() and role = target_role
  );
$$ language sql stable security definer set search_path = public;

create or replace function public.jurisia_is_staff()
returns boolean as $$
  select exists (select 1 from public.staff_roles where user_id = auth.uid());
$$ language sql stable security definer set search_path = public;

drop policy if exists "Le personnel lit les rôles" on public.staff_roles;
create policy "Le personnel lit les rôles"
  on public.staff_roles for select
  using (public.jurisia_is_staff());

-- Aucune politique insert/update/delete : un rôle ne s'accorde que via une
-- Edge Function (clé de service), jamais depuis un client. Pour amorcer le
-- tout premier super_admin, insérer sa ligne à la main dans le SQL Editor.

-- ---------------------------------------------------------------------
-- Journal d'audit (ajout seul, jamais modifié ni supprimé)
-- ---------------------------------------------------------------------

create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users (id),
  action text not null,
  target_type text,
  target_id text,
  before jsonb,
  after jsonb,
  reason text,
  ip text,
  created_at timestamptz not null default now()
);

alter table public.admin_audit_log enable row level security;

drop policy if exists "Le personnel lit le journal d'audit" on public.admin_audit_log;
create policy "Le personnel lit le journal d'audit"
  on public.admin_audit_log for select
  using (public.jurisia_is_staff());

-- Aucune politique d'écriture : le journal ne s'alimente que via des
-- fonctions SECURITY DEFINER (Edge Functions) et ne se modifie jamais.
