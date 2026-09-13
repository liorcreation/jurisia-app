-- Catalogue de formations et certificats signés électroniquement.

create table if not exists public.training_categories (
  id text primary key,
  title text not null,
  subtitle text,
  description text not null,
  training_type text not null check (training_type in ('certifying', 'lmd')),
  is_available boolean not null default false,
  domain text not null default 'autre',
  icon text not null default 'school',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists training_categories_availability_idx
  on public.training_categories (is_available, training_type, sort_order);

alter table public.training_categories enable row level security;

drop policy if exists "Le catalogue de formations est public" on public.training_categories;
create policy "Le catalogue de formations est public"
  on public.training_categories for select
  using (true);

insert into public.training_categories
  (id, title, subtitle, description, training_type, is_available, domain, icon, sort_order)
values
  ('cert-droit-famille', 'Droit de la famille', 'État des personnes, mariage, succession', 'Formation certifiante en droit de la famille.', 'certifying', true, 'famille', 'family', 10),
  ('cert-public-fondamental', 'Droit public fondamental', 'Constitution, administration, libertés', 'Formation certifiante en droit public fondamental.', 'certifying', true, 'administratif', 'account_balance', 20),
  ('cert-droit-affaires', 'Droit des affaires', 'Entreprise, contrats, OHADA', 'Formation certifiante en droit des affaires.', 'certifying', true, 'commercial', 'business_center', 30),
  ('cert-droit-assurances', 'Droit des assurances', 'Risques, garanties, indemnisation', 'Formation certifiante en droit des assurances.', 'certifying', true, 'civil', 'verified_user', 40),
  ('cert-droit-immobilier', 'Droit immobilier', 'Foncier, baux, transactions', 'Formation certifiante en droit immobilier.', 'certifying', true, 'foncier', 'domain', 50),
  ('lmd-university-course', 'Parcours universitaire LMD', 'Licence 1 à Master 2', 'Le parcours académique LMD sera ouvert ultérieurement.', 'lmd', false, 'autre', 'school', 100)
on conflict (id) do update set
  title = excluded.title,
  subtitle = excluded.subtitle,
  description = excluded.description,
  training_type = excluded.training_type,
  is_available = excluded.is_available,
  domain = excluded.domain,
  icon = excluded.icon,
  sort_order = excluded.sort_order,
  updated_at = now();

create table if not exists public.training_certificates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  category_id text not null references public.training_categories (id),
  title text not null,
  certificate_number text not null unique,
  verification_code text not null unique,
  status text not null default 'pending' check (status in ('pending', 'issued', 'revoked')),
  issued_at timestamptz,
  signed_at timestamptz,
  signer_name text,
  signature_hash text,
  pdf_storage_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists training_certificates_user_idx
  on public.training_certificates (user_id, issued_at desc);

alter table public.training_certificates enable row level security;

drop policy if exists "Un utilisateur lit ses certificats" on public.training_certificates;
create policy "Un utilisateur lit ses certificats"
  on public.training_certificates for select
  using (auth.uid() = user_id or public.jurisia_is_staff());

create or replace function public.verify_training_certificate(p_code text)
returns table (
  certificate_number text,
  title text,
  category_id text,
  status text,
  issued_at timestamptz,
  signer_name text
)
language sql
stable
security definer
set search_path = public
as $$
  select c.certificate_number, c.title, c.category_id, c.status,
         c.issued_at, c.signer_name
  from public.training_certificates c
  where c.verification_code = nullif(trim(p_code), '')
    and c.status = 'issued';
$$;

grant execute on function public.verify_training_certificate(text) to anon, authenticated;
