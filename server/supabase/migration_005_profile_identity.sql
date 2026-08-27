-- À exécuter une fois dans le SQL Editor de votre projet Supabase — ajoute
-- l'identité affichée dans la carte profil de la sidebar : nom complet et
-- profil (« Vous êtes »), plus l'épinglage des consultations. Sans risque à
-- réexécuter (idempotent).

-- ---------------------------------------------------------------------
-- Identité du profil
-- ---------------------------------------------------------------------

alter table public.profiles
  add column if not exists full_name text;

alter table public.profiles
  add column if not exists profession text;

-- L'utilisateur peut désormais créer sa propre ligne de profil au besoin
-- (le trigger la crée déjà à l'inscription ; ceci couvre le repli côté
-- application quand la fonction n'a pas encore été redéployée).
drop policy if exists "Un utilisateur crée son propre profil" on public.profiles;
create policy "Un utilisateur crée son propre profil"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Recrée le trigger d'inscription pour recopier le nom complet et le profil
-- fournis dans les métadonnées utilisateur (auth.signUp(data: {...})).
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, profession)
  values (
    new.id,
    nullif(new.raw_user_meta_data->>'full_name', ''),
    nullif(new.raw_user_meta_data->>'profession', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- Épinglage des consultations (section « Épinglées » de la sidebar)
-- ---------------------------------------------------------------------

alter table public.litigation_conversations
  add column if not exists is_favorite boolean not null default false;
