-- migration_038 — PDF intégraux du pack Finances publiques.
-- Les deux copies binaires identiques sur l'UEMOA/Sénégal sont cataloguées une fois.

do $catalog$
declare
  base_url constant text :=
    'https://gfpguuuzzyqoxjkhlhli.supabase.co/storage/v1/object/public/legal-source-pdfs/';
begin
  insert into public.legal_documents (
    id, title, type, domain, reference, date_publication, status, summary,
    full_content, outline, summary_only, official_source_name, file_url,
    tags, related_ids, imported_at
  ) values
  ('pdf-public-finance-blanc-droit-economique', 'Du droit public économique au droit public de l’économie', 'doctrine', 'administratif', 'F. Blanc — Du droit public économique au droit public de l’économie', '2000-01-01', 'enVigueur', 'Étude consacrée au droit public économique.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'F.%20Blanc%2C%20Du%20droit%20public%20economique%20au%20droit%20public%20de%20l%27economie.pdf', array['pack-finances-publiques','droit public économique','F. Blanc','PDF intégral'], '{}', now()),
  ('pdf-public-finance-chouvel-2020', 'Finances publiques — François Chouvel (2020)', 'doctrine', 'fiscal', 'François Chouvel — Finances publiques, Mémentos, 23e édition, 2020', '2020-01-01', 'enVigueur', 'Ouvrage de finances publiques, édition 2020.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Finances%20publiques%202020%20_%20Intgre%20la%20loi%20de%20finances%20pour%20--%20Chouvel%2C%20Franois%20--%20Mmentos%2C%2023%2C%202020%20--%20Gualino%20--%2042877e26f3e7c0ce07717932231c389d%20--%20Annas%20Archive.pdf', array['pack-finances-publiques','finances publiques','François Chouvel','2020','PDF intégral'], '{}', now()),
  ('pdf-public-finance-chouvel', 'Finances publiques — François Chouvel', 'doctrine', 'fiscal', 'François Chouvel — Finances publiques', '2000-01-01', 'enVigueur', 'Document consacré aux finances publiques.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Finances%20publiques%20by%20Francois%20Chouvel%20%28z-lib.org%29.pdf', array['pack-finances-publiques','finances publiques','François Chouvel','PDF intégral'], '{}', now()),
  ('pdf-public-finance-hasquenoh-voix-feminines', 'Les voix féminines du droit public de l’économie', 'doctrine', 'administratif', 'I. Hasquenoh — Les voix féminines du droit public de l’économie', '2000-01-01', 'enVigueur', 'Étude sur les voix féminines du droit public de l’économie.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'I.%20Hasquenoh%2C%20Les%20voix%20feminines%20du%20droit%20public%20de%20l%27economie.pdf', array['pack-finances-publiques','droit public économique','I. Hasquenoh','PDF intégral'], '{}', now()),
  ('pdf-public-finance-boucheix', 'Les finances publiques — Philippe Boucheix', 'doctrine', 'fiscal', 'Philippe Boucheix — Les finances publiques', '2000-01-01', 'enVigueur', 'Document consacré aux finances publiques.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Les%20finances%20publiqu...%20by%20Philippe%20Boucheix%20%20R...%20%28z-lib.or.pdf', array['pack-finances-publiques','finances publiques','Philippe Boucheix','PDF intégral'], '{}', now()),
  ('pdf-public-finance-uemoa-senegal', 'Les finances publiques dans l’UEMOA — Sénégal', 'doctrine', 'fiscal', 'Les finances publiques dans l’UEMOA — Sénégal', '2000-01-01', 'enVigueur', 'Étude des finances publiques dans l’espace UEMOA, consacrée au Sénégal.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'LES%20FINANCES%20PUBLIQUES%20DANS%20L%27UEMOA_SENEGAL.pdf', array['pack-finances-publiques','finances publiques','UEMOA','Sénégal','PDF intégral'], '{}', now()),
  ('pdf-public-finance-houser-concours', 'Les finances publiques aux concours — Matthieu Houser', 'doctrine', 'fiscal', 'Matthieu Houser — Les finances publiques aux concours', '2000-01-01', 'enVigueur', 'Support de finances publiques destiné à la préparation des concours.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Les_finances_publiques_aux_concours_by_Matthieu_Houser_z_lib_org.pdf', array['pack-finances-publiques','finances publiques','Matthieu Houser','concours','PDF intégral'], '{}', now()),
  ('pdf-public-finance-chambon-courants-doctrinaux', 'Les courants doctrinaux du droit public de l’économie', 'doctrine', 'administratif', 'M. Chambon — Les courants doctrinaux du droit public de l’économie', '2000-01-01', 'enVigueur', 'Étude des courants doctrinaux du droit public de l’économie.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'M.%20Chambon%2C%20Les%20courants%20doctrinaux%20du%20droit%20public%20de%20l%27economie.pdf', array['pack-finances-publiques','droit public économique','M. Chambon','PDF intégral'], '{}', now())
  on conflict (id) do update set
    title = excluded.title,
    type = excluded.type,
    domain = excluded.domain,
    reference = excluded.reference,
    date_publication = excluded.date_publication,
    status = excluded.status,
    summary = excluded.summary,
    full_content = excluded.full_content,
    outline = excluded.outline,
    summary_only = false,
    official_source_name = excluded.official_source_name,
    file_url = excluded.file_url,
    tags = excluded.tags,
    related_ids = excluded.related_ids,
    updated_at = now();
end $catalog$;
