-- À exécuter une fois dans le SQL Editor de votre projet Supabase — ouvre au
-- personnel (« staff », voir migration_006) l'accès en lecture aux données
-- opérationnelles de la console d'administration, et expose des fonctions
-- SECURITY DEFINER pour les actions qui doivent être tracées au journal
-- d'audit. Sans risque à réexécuter (idempotent). Nécessite migration_006 et
-- migration_007.

-- ---------------------------------------------------------------------
-- Lecture transverse pour le personnel (politiques additives — les
-- politiques « propriétaire » existantes restent en place).
-- ---------------------------------------------------------------------

drop policy if exists "Le personnel lit toutes les demandes de contact"
  on public.professional_contact_requests;
create policy "Le personnel lit toutes les demandes de contact"
  on public.professional_contact_requests for select
  using (public.jurisia_is_staff());

drop policy if exists "Le personnel lit tous les abonnements" on public.subscriptions;
create policy "Le personnel lit tous les abonnements"
  on public.subscriptions for select
  using (public.jurisia_is_staff());

drop policy if exists "Le personnel lit toute la consommation" on public.usage_counters;
create policy "Le personnel lit toute la consommation"
  on public.usage_counters for select
  using (public.jurisia_is_staff());

-- ---------------------------------------------------------------------
-- Journal d'audit générique (appelé par les Edge Functions / RPC admin).
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_log(
  p_action text,
  p_target_type text default null,
  p_target_id text default null,
  p_before jsonb default null,
  p_after jsonb default null,
  p_reason text default null
)
returns void as $$
begin
  if not public.jurisia_is_staff() then
    raise exception 'réservé au personnel';
  end if;

  insert into public.admin_audit_log
    (actor_id, action, target_type, target_id, before, after, reason)
  values
    (auth.uid(), p_action, p_target_type, p_target_id, p_before, p_after, p_reason);
end;
$$ language plpgsql volatile security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Action tracée : changer le statut d'une demande de mise en relation.
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_set_contact_status(
  p_request_id uuid,
  p_status text,
  p_reason text default null
)
returns public.professional_contact_requests as $$
declare
  v_before public.professional_contact_requests;
  v_after public.professional_contact_requests;
begin
  if not public.jurisia_is_staff() then
    raise exception 'réservé au personnel';
  end if;
  if p_status not in ('pending', 'contacted', 'closed') then
    raise exception 'statut invalide : %', p_status;
  end if;

  select * into v_before from public.professional_contact_requests where id = p_request_id;
  if v_before.id is null then
    raise exception 'demande introuvable';
  end if;

  update public.professional_contact_requests
    set status = p_status
    where id = p_request_id
    returning * into v_after;

  perform public.jurisia_admin_log(
    'contact_request.set_status',
    'professional_contact_requests',
    p_request_id::text,
    jsonb_build_object('status', v_before.status),
    jsonb_build_object('status', v_after.status),
    p_reason
  );

  return v_after;
end;
$$ language plpgsql volatile security definer set search_path = public;
