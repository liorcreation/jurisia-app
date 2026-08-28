-- À exécuter une fois dans le SQL Editor de votre projet Supabase — ajoute
-- le suivi des paiements (`payment_intents`) et les deux fonctions
-- d'activation appelées par les Edge Functions `billing-checkout` /
-- `billing-webhook` (voir `supabase/functions/`). Sans risque à réexécuter
-- (idempotent). Nécessite migration_006 et migration_007.
--
-- Aucun client n'écrit dans `subscriptions` : une offre payante ne s'active
-- que par un paiement confirmé, via `jurisia_billing_apply` (clé de service,
-- côté webhook).

-- ---------------------------------------------------------------------
-- Intentions de paiement
-- ---------------------------------------------------------------------

create table if not exists public.payment_intents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_code text not null references public.plans (code),
  amount_fcfa integer not null,
  currency text not null default 'XOF',
  transaction_id text not null unique,
  provider text not null,
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'failed', 'expired')),
  checkout_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.payment_intents enable row level security;

drop policy if exists "Un utilisateur lit ses propres paiements" on public.payment_intents;
create policy "Un utilisateur lit ses propres paiements"
  on public.payment_intents for select
  using (auth.uid() = user_id);

drop policy if exists "Le personnel lit tous les paiements" on public.payment_intents;
create policy "Le personnel lit tous les paiements"
  on public.payment_intents for select
  using (public.jurisia_is_staff());

-- Aucune politique insert/update/delete : les Edge Functions écrivent via
-- les fonctions ci-dessous (SECURITY DEFINER) ou la clé de service.

-- ---------------------------------------------------------------------
-- Création d'une intention de paiement (appelée par billing-checkout avec
-- le JWT de l'utilisateur — `auth.uid()` fait foi).
-- ---------------------------------------------------------------------

create or replace function public.jurisia_billing_create_intent(
  p_plan_code text,
  p_transaction_id text,
  p_provider text
)
returns public.payment_intents as $$
declare
  v_plan public.plans;
  v_row public.payment_intents;
begin
  if auth.uid() is null then
    raise exception 'non authentifié';
  end if;

  select * into v_plan from public.plans where code = p_plan_code;
  if v_plan.code is null then
    raise exception 'offre inconnue : %', p_plan_code;
  end if;
  if coalesce(v_plan.price_fcfa, 0) <= 0 then
    raise exception 'offre non payante : %', p_plan_code;
  end if;

  insert into public.payment_intents
    (user_id, plan_code, amount_fcfa, transaction_id, provider)
  values
    (auth.uid(), p_plan_code, v_plan.price_fcfa, p_transaction_id, p_provider)
  returning * into v_row;

  return v_row;
end;
$$ language plpgsql volatile security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Finalisation d'un paiement (appelée par billing-webhook avec la clé de
-- service, sans contexte utilisateur). Idempotente : ne fait rien si
-- l'intention n'est plus « pending ».
-- ---------------------------------------------------------------------

create or replace function public.jurisia_billing_apply(
  p_transaction_id text,
  p_new_status text,                    -- 'paid' | 'failed' | 'expired'
  p_period_end timestamptz default null
)
returns void as $$
declare
  v_intent public.payment_intents;
begin
  if p_new_status not in ('paid', 'failed', 'expired') then
    raise exception 'statut invalide : %', p_new_status;
  end if;

  select * into v_intent
    from public.payment_intents
    where transaction_id = p_transaction_id
    for update;

  if v_intent.id is null then
    raise exception 'intention de paiement introuvable : %', p_transaction_id;
  end if;

  -- Déjà finalisée : rien à faire (rejeu du webhook).
  if v_intent.status <> 'pending' then
    return;
  end if;

  update public.payment_intents
    set status = p_new_status, updated_at = now()
    where id = v_intent.id;

  if p_new_status <> 'paid' then
    return;
  end if;

  insert into public.subscriptions
    (user_id, plan_code, status, current_period_end, psp, psp_ref, updated_at)
  values
    (v_intent.user_id, v_intent.plan_code, 'active',
     coalesce(p_period_end, now() + interval '1 month'),
     v_intent.provider, p_transaction_id, now())
  on conflict (user_id) do update set
    plan_code = excluded.plan_code,
    status = 'active',
    current_period_end = excluded.current_period_end,
    psp = excluded.psp,
    psp_ref = excluded.psp_ref,
    updated_at = now();

  -- Trace système au journal d'audit (actor_id null = pas un opérateur).
  insert into public.admin_audit_log
    (actor_id, action, target_type, target_id, after, reason)
  values
    (null, 'subscription.activated', 'subscriptions', v_intent.user_id::text,
     jsonb_build_object('plan', v_intent.plan_code, 'transaction_id', p_transaction_id),
     'paiement confirmé (' || v_intent.provider || ')');
end;
$$ language plpgsql volatile security definer set search_path = public;
