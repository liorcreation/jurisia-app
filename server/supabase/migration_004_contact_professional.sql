-- À exécuter une fois dans le SQL Editor de votre projet Supabase — ajoute
-- le 5e module « Contacter un professionnel » (mise en relation avec un
-- notaire, avocat, juriste, huissier, greffier ou juge partenaire). Sans
-- risque à réexécuter (idempotent).

create table if not exists public.professional_contact_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  category text not null check (
    category in ('notaire', 'avocat', 'juriste', 'huissier', 'greffier', 'juge')
  ),
  full_name text not null,
  contact_info text not null,
  message text not null,
  status text not null default 'pending' check (status in ('pending', 'contacted', 'closed')),
  created_at timestamptz not null default now()
);

alter table public.professional_contact_requests enable row level security;

drop policy if exists "Un utilisateur gère ses propres demandes de contact"
  on public.professional_contact_requests;

create policy "Un utilisateur gère ses propres demandes de contact"
  on public.professional_contact_requests for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
