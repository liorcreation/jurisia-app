-- À exécuter une fois dans le SQL Editor de votre projet Supabase — met en
-- place les fondations d'abonnement : catalogue d'offres, abonnements,
-- consommation mensuelle, et limites d'IA par palier. Sans risque à
-- réexécuter (idempotent).
--
-- Tant que cette migration n'est pas appliquée, l'application continue de
-- fonctionner normalement : elle applique alors le quota de l'offre
-- Découverte depuis un compteur mensuel local (voir lib/core/entitlements/).
-- Une fois la migration en place, le serveur redevient la source de vérité.

-- ---------------------------------------------------------------------
-- Catalogue d'offres
-- ---------------------------------------------------------------------

create table if not exists public.plans (
  code text primary key,
  name text not null,
  price_fcfa integer,
  billing_interval text,               -- 'month' | 'year' | null (sur devis)
  features jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0
);

alter table public.plans enable row level security;

drop policy if exists "Le catalogue d'offres est public" on public.plans;
create policy "Le catalogue d'offres est public"
  on public.plans for select using (true);

insert into public.plans (code, name, price_fcfa, billing_interval, sort_order, features) values
  ('decouverte', 'JurisIA Découverte', 0, null, 0,
    '{"litige.consultations": 3, "contact.requests": 1}'::jsonb),
  ('plus', 'JurisIA+', 2500, 'month', 1,
    '{"litige.consultations": null, "contact.requests": null, "litige.mode_approfondi": true, "litige.export_pdf": true, "ia.priorite": true, "coffre_fort": true}'::jsonb),
  ('etudiant', 'JurisIA Étudiant', 1000, 'month', 2,
    '{"litige.consultations": 3, "contact.requests": 1, "etudiant.tous_modules": true}'::jsonb),
  ('pro', 'JurisIA Pro', 15000, 'month', 3,
    '{"litige.consultations": null, "contact.requests": null, "pro.espace": true, "litige.mode_approfondi": true, "litige.export_pdf": true, "ia.priorite": true, "coffre_fort": true}'::jsonb),
  ('cabinet', 'JurisIA Cabinet', null, null, 4,
    '{"litige.consultations": null, "contact.requests": null, "pro.espace": true, "litige.mode_approfondi": true, "litige.export_pdf": true, "ia.priorite": true, "coffre_fort": true}'::jsonb)
on conflict (code) do update set
  name = excluded.name,
  price_fcfa = excluded.price_fcfa,
  billing_interval = excluded.billing_interval,
  sort_order = excluded.sort_order,
  features = excluded.features;

-- ---------------------------------------------------------------------
-- Abonnements (une ligne par utilisateur)
-- ---------------------------------------------------------------------

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_code text not null references public.plans (code) default 'decouverte',
  status text not null default 'active'
    check (status in ('active', 'trialing', 'past_due', 'canceled')),
  current_period_end timestamptz,
  psp text,                            -- prestataire de paiement
  psp_ref text,
  seats integer not null default 1,
  trial_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

alter table public.subscriptions enable row level security;

drop policy if exists "Un utilisateur lit son propre abonnement" on public.subscriptions;
create policy "Un utilisateur lit son propre abonnement"
  on public.subscriptions for select
  using (auth.uid() = user_id);

-- Aucune politique insert/update/delete depuis le client : un abonnement ne
-- se crée / ne se modifie que via le webhook du prestataire de paiement
-- (Edge Function, clé de service).

-- ---------------------------------------------------------------------
-- Consommation mensuelle
-- ---------------------------------------------------------------------

create table if not exists public.usage_counters (
  user_id uuid not null references auth.users (id) on delete cascade,
  feature text not null,
  period date not null,                -- 1er jour du mois concerné
  used integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, feature, period)
);

alter table public.usage_counters enable row level security;

drop policy if exists "Un utilisateur lit sa propre consommation" on public.usage_counters;
create policy "Un utilisateur lit sa propre consommation"
  on public.usage_counters for select
  using (auth.uid() = user_id);

-- Trace fine des consommations (matière première du futur cockpit
-- coûts & abus de la console d'administration).
create table if not exists public.usage_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  feature text not null,
  created_at timestamptz not null default now()
);

alter table public.usage_events enable row level security;

drop policy if exists "Un utilisateur lit ses propres événements" on public.usage_events;
create policy "Un utilisateur lit ses propres événements"
  on public.usage_events for select
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- Limites d'IA par palier (destinées à être lues par le relais Cloudflare
-- une fois l'authentification de l'appelant en place — voir la feuille de
-- route « authentification & comptes »).
-- ---------------------------------------------------------------------

create table if not exists public.ai_limits (
  plan_code text primary key references public.plans (code),
  req_per_min integer not null default 20,
  max_tokens integer not null default 1536,
  model text not null default 'openai/gpt-oss-120b',
  priority text not null default 'standard'
);

alter table public.ai_limits enable row level security;

drop policy if exists "Les limites d'IA sont publiques" on public.ai_limits;
create policy "Les limites d'IA sont publiques"
  on public.ai_limits for select using (true);

insert into public.ai_limits (plan_code, req_per_min, max_tokens, model, priority) values
  ('decouverte', 12, 1536, 'openai/gpt-oss-120b', 'standard'),
  ('plus',       30, 2048, 'openai/gpt-oss-120b', 'high'),
  ('etudiant',   20, 1536, 'openai/gpt-oss-120b', 'standard'),
  ('pro',        60, 3072, 'openai/gpt-oss-120b', 'max'),
  ('cabinet',    60, 3072, 'openai/gpt-oss-120b', 'max')
on conflict (plan_code) do update set
  req_per_min = excluded.req_per_min,
  max_tokens = excluded.max_tokens,
  model = excluded.model,
  priority = excluded.priority;

-- ---------------------------------------------------------------------
-- Fonctions RPC appelées par le client (lib/core/entitlements/)
-- ---------------------------------------------------------------------

-- Code de l'offre active de l'utilisateur courant (défaut : 'decouverte').
create or replace function public.jurisia_plan_code()
returns text as $$
  select coalesce(
    (select plan_code from public.subscriptions
      where user_id = auth.uid()
        and status in ('active', 'trialing')
      limit 1),
    'decouverte'
  );
$$ language sql stable security definer set search_path = public;

-- Offre + consommation du mois en cours, en un seul aller-retour.
create or replace function public.jurisia_entitlements()
returns jsonb as $$
  select jsonb_build_object(
    'plan', public.jurisia_plan_code(),
    'usage', coalesce(
      (select jsonb_object_agg(feature, used)
        from public.usage_counters
        where user_id = auth.uid()
          and period = date_trunc('month', now())::date),
      '{}'::jsonb
    )
  );
$$ language sql stable security definer set search_path = public;

-- Enregistre une unité de consommation d'une fonctionnalité pour le mois en
-- cours (incrément atomique, évite la course entre deux appareils) et trace
-- l'événement. Toujours borné à auth.uid() : un utilisateur ne peut
-- incrémenter que ses propres compteurs.
create or replace function public.jurisia_record_usage(p_feature text)
returns integer as $$
declare
  v_used integer;
begin
  if auth.uid() is null then
    raise exception 'non authentifié';
  end if;

  insert into public.usage_counters (user_id, feature, period, used)
  values (auth.uid(), p_feature, date_trunc('month', now())::date, 1)
  on conflict (user_id, feature, period)
  do update set used = public.usage_counters.used + 1, updated_at = now()
  returning used into v_used;

  insert into public.usage_events (user_id, feature) values (auth.uid(), p_feature);

  return v_used;
end;
$$ language plpgsql volatile security definer set search_path = public;
