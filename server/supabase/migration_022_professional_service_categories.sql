-- migration_022 — Typologie métier des services professionnels.
-- Le parcours client distingue désormais une catégorie de service (notaire,
-- avocat, création de société, etc.) d'une simple profession à contacter.
-- Les anciennes valeurs restent autorisées afin de préserver l'historique.

do $$
declare
  constraint_name text;
begin
  select c.conname
    into constraint_name
  from pg_constraint c
  join pg_class t on t.oid = c.conrelid
  join pg_namespace n on n.oid = t.relnamespace
  where n.nspname = 'public'
    and t.relname = 'professional_service_requests'
    and c.contype = 'c'
    and pg_get_constraintdef(c.oid) ilike '%category%';

  if constraint_name is not null then
    execute format(
      'alter table public.professional_service_requests drop constraint %I',
      constraint_name
    );
  end if;
end $$;

alter table public.professional_service_requests
  add constraint professional_service_requests_category_check check (
    category in (
      'services_notariaux',
      'services_avocats',
      'services_huissier',
      'jurisconsulte',
      'creation_entreprise_association',
      'creation_societes',
      'creation_cooperatives',
      'consultation_approfondie',
      -- Compatibilité avec les demandes historiques.
      'notaire',
      'avocat',
      'juriste',
      'huissier',
      'greffier',
      'juge'
    )
  );
