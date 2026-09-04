-- À exécuter une fois dans le SQL Editor de votre projet Supabase — donne à
-- la console d'administration une vraie gestion du personnel (jusqu'ici,
-- migration_006 exigeait d'ajouter chaque membre à la main en SQL). Sans
-- risque à réexécuter (idempotent). Nécessite migration_006 (staff_roles,
-- jurisia_is_staff/jurisia_has_role) et migration_008 (jurisia_admin_log).
--
-- Toute action reste tracée au journal d'audit et réservée aux
-- super_admin — un rôle ne peut toujours pas s'accorder ou se retirer
-- depuis un client sans passer par ces fonctions SECURITY DEFINER, qui
-- vérifient elles-mêmes l'appelant (pas de politique RLS insert/update/
-- delete sur staff_roles, comme prévu par migration_006).

-- ---------------------------------------------------------------------
-- Lecture du personnel avec l'e-mail (public.staff_roles seul ne porte
-- que des user_id : auth.users n'est pas exposé au client via PostgREST).
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_list_staff()
returns table (
  user_id uuid,
  email text,
  role text,
  granted_by uuid,
  granted_by_email text,
  granted_at timestamptz
) as $$
begin
  if not public.jurisia_is_staff() then
    raise exception 'réservé au personnel';
  end if;

  return query
    select
      sr.user_id,
      u.email::text,
      sr.role,
      sr.granted_by,
      gu.email::text,
      sr.granted_at
    from public.staff_roles sr
    join auth.users u on u.id = sr.user_id
    left join auth.users gu on gu.id = sr.granted_by
    order by u.email, sr.role;
end;
$$ language plpgsql stable security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Accorder un rôle — réservé aux super_admin. L'utilisateur doit déjà
-- avoir un compte JurisIA (recherché par e-mail) ; on ne peut pas en créer
-- un depuis cette fonction.
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_grant_staff_role(
  p_email text,
  p_role text
)
returns void as $$
declare
  v_user_id uuid;
begin
  if not public.jurisia_has_role('super_admin') then
    raise exception 'réservé aux super administrateurs';
  end if;
  if p_role not in (
    'super_admin', 'admin', 'content_editor', 'legal_reviewer',
    'partner_manager', 'support_agent', 'analyst'
  ) then
    raise exception 'rôle invalide : %', p_role;
  end if;

  select id into v_user_id from auth.users where lower(email) = lower(trim(p_email));
  if v_user_id is null then
    raise exception 'aucun compte JurisIA avec cet e-mail : %', p_email;
  end if;

  insert into public.staff_roles (user_id, role, granted_by)
    values (v_user_id, p_role, auth.uid())
    on conflict (user_id, role) do nothing;

  perform public.jurisia_admin_log(
    'staff.grant_role',
    'staff_roles',
    v_user_id::text,
    null,
    jsonb_build_object('role', p_role, 'email', p_email),
    null
  );
end;
$$ language plpgsql volatile security definer set search_path = public;

-- ---------------------------------------------------------------------
-- Retirer un rôle — réservé aux super_admin. Refuse de retirer le tout
-- dernier super_admin : ce serait perdre l'accès à cette fonction même.
-- ---------------------------------------------------------------------

create or replace function public.jurisia_admin_revoke_staff_role(
  p_user_id uuid,
  p_role text
)
returns void as $$
declare
  v_remaining_super_admins integer;
begin
  if not public.jurisia_has_role('super_admin') then
    raise exception 'réservé aux super administrateurs';
  end if;

  if p_role = 'super_admin' then
    select count(*) into v_remaining_super_admins
      from public.staff_roles
      where role = 'super_admin' and user_id <> p_user_id;
    if v_remaining_super_admins = 0 then
      raise exception 'impossible : ce serait le dernier super administrateur';
    end if;
  end if;

  delete from public.staff_roles where user_id = p_user_id and role = p_role;

  perform public.jurisia_admin_log(
    'staff.revoke_role',
    'staff_roles',
    p_user_id::text,
    jsonb_build_object('role', p_role),
    null,
    null
  );
end;
$$ language plpgsql volatile security definer set search_path = public;
