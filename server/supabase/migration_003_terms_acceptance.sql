-- À exécuter une fois dans le SQL Editor de votre projet Supabase — trace la
-- date d'acceptation des CGU/politique de confidentialité par utilisateur.
-- Sans risque à réexécuter (idempotent).

alter table public.profiles
  add column if not exists terms_accepted_at timestamptz;
