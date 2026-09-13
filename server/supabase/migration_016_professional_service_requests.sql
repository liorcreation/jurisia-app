-- Module Professionnels & rédaction d'actes
-- Demandes structurées pour un acte juridique ou un rendez-vous d'expert.

create table if not exists public.professional_service_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('legalAct', 'expertAppointment')),
  category text not null check (
    category in ('notaire', 'avocat', 'juriste', 'huissier', 'greffier', 'juge')
  ),
  act_type text,
  full_name text not null,
  email text not null,
  phone text not null,
  details text not null,
  urgency text not null default 'standard' check (urgency in ('standard', 'priority', 'urgent')),
  attachment_names jsonb not null default '[]'::jsonb,
  desired_date date,
  appointment_mode text check (appointment_mode in ('phone', 'video', 'inPerson')),
  status text not null default 'submitted' check (
    status in ('submitted', 'acknowledged', 'quoteReady', 'scheduled', 'closed', 'cancelled')
  ),
  quote_amount numeric(12, 2),
  quote_currency text not null default 'XOF',
  deposit_url text,
  dropoff_location text,
  pickup_location text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint professional_service_request_context_check check (
    (kind = 'legalAct' and nullif(trim(act_type), '') is not null)
    or (kind = 'expertAppointment' and desired_date is not null)
  )
);

create index if not exists professional_service_requests_user_idx
  on public.professional_service_requests (user_id, created_at desc);
create index if not exists professional_service_requests_status_idx
  on public.professional_service_requests (status, created_at desc);

alter table public.professional_service_requests enable row level security;

drop policy if exists "Un utilisateur lit ses demandes professionnelles"
  on public.professional_service_requests;
create policy "Un utilisateur lit ses demandes professionnelles"
  on public.professional_service_requests for select
  using (auth.uid() = user_id or public.jurisia_is_staff());

drop policy if exists "Un utilisateur crée ses demandes professionnelles"
  on public.professional_service_requests;
create policy "Un utilisateur crée ses demandes professionnelles"
  on public.professional_service_requests for insert
  with check (auth.uid() = user_id);

create or replace function public.professional_service_request_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists professional_service_requests_updated_at
  on public.professional_service_requests;
create trigger professional_service_requests_updated_at
  before update on public.professional_service_requests
  for each row execute function public.professional_service_request_touch_updated_at();
