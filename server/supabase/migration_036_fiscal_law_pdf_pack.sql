-- migration_036 — PDF du pack droit fiscal et fiscalité internationale.
-- Les cours L2 et le droit fiscal général 2018 ont chacun une copie binaire identique ; une seule est cataloguée.

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
  ('pdf-fiscal-code-impots-2025', 'Code général des Impôts — 2025', 'code', 'fiscal', 'Code général des Impôts — édition 2025', '2025-01-01', 'enVigueur', 'Texte fiscal général transmis pour la bibliothèque JurisIA.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Code%20general%20des%20Impots%202025.pdf', array['pack-droit-fiscal-international','code général des impôts','fiscalité','2025','PDF intégral'], '{}', now()),
  ('pdf-fiscal-course-l2-2022-2023', 'Cours de droit fiscal — L2 (2022–2023)', 'doctrine', 'fiscal', 'Cours de droit fiscal L2 — année universitaire 2022–2023', '2022-09-01', 'enVigueur', 'Support de cours de droit fiscal pour le niveau L2.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'COURS%20DE%20DROIT%20FISCAL%20L2%20DROIT%202022-2023.%20%281%29.pdf', array['pack-droit-fiscal-international','cours','droit fiscal','L2','PDF intégral'], '{}', now()),
  ('pdf-fiscal-course-enterprises', 'Cours de fiscalité des entreprises', 'doctrine', 'fiscal', 'Cours de fiscalité des entreprises', '2000-01-01', 'enVigueur', 'Support consacré à la fiscalité des entreprises.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Cours%20de%20fiscalit%20des%20entreprises.pdf', array['pack-droit-fiscal-international','fiscalité des entreprises','cours','PDF intégral'], '{}', now()),
  ('pdf-fiscal-procedures-ricou', 'Droit des procédures fiscales — Benjamin Ricou', 'doctrine', 'fiscal', 'Benjamin Ricou — Droit des procédures fiscales', '2000-01-01', 'enVigueur', 'Ouvrage consacré aux procédures fiscales.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit%20des%20procedures%20fiscales%20-%20Benjamin%20Ricou%20%40lechat%20%281%29.pdf', array['pack-droit-fiscal-international','procédures fiscales','Benjamin Ricou','PDF intégral'], '{}', now()),
  ('pdf-fiscal-collectif-breal-2023', 'Droit fiscal — Collectif (Bréal, 2023)', 'doctrine', 'fiscal', 'Collectif — Bréal, 2023', '2023-01-01', 'enVigueur', 'Ouvrage collectif de droit fiscal publié chez Bréal.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit%20fiscal%20--%20Collectif%20--%202023%20--%20Bral.pdf', array['pack-droit-fiscal-international','droit fiscal','Bréal','2023','PDF intégral'], '{}', now()),
  ('pdf-fiscal-disle', 'Droit fiscal — Emmanuel Disle', 'doctrine', 'fiscal', 'Emmanuel Disle — Droit fiscal', '2000-01-01', 'enVigueur', 'Document de droit fiscal attribué à Emmanuel Disle.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit%20fiscal%20de%20Emmanuel%20DISLE%202.pdf', array['pack-droit-fiscal-international','droit fiscal','Emmanuel Disle','PDF intégral'], '{}', now()),
  ('pdf-fiscal-goliard', 'Droit fiscal général — François Goliard', 'doctrine', 'fiscal', 'François Goliard — Droit fiscal général', '2000-01-01', 'enVigueur', 'Document de droit fiscal général attribué à François Goliard.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit%20fiscal%20de%20Franois%20GOLIARD.pdf', array['pack-droit-fiscal-international','droit fiscal général','François Goliard','PDF intégral'], '{}', now()),
  ('pdf-fiscal-torrione', 'Droit fiscal — Henri Torrione', 'doctrine', 'fiscal', 'Henri Torrione — Droit fiscal', '2000-01-01', 'enVigueur', 'Document de cours de droit fiscal attribué à Henri Torrione.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit%20fiscal%20de%20Henri%20Torrione.pdf', array['pack-droit-fiscal-international','droit fiscal','Henri Torrione','PDF intégral'], '{}', now()),
  ('pdf-fiscal-affaires-2018-ed17', 'Droit fiscal des affaires (2018–2019, 17e édition)', 'doctrine', 'fiscal', 'Droit fiscal des affaires — 2018–2019, 17e édition', '2018-01-01', 'enVigueur', 'Ouvrage consacré au droit fiscal des affaires.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit%20fiscal%20des%20affaires%202018-2019%20Ed.%2017.pdf', array['pack-droit-fiscal-international','fiscalité des affaires','17e édition','2018–2019','PDF intégral'], '{}', now()),
  ('pdf-fiscal-general-2018-ed11', 'Droit fiscal général (2018, 11e édition)', 'doctrine', 'fiscal', 'Droit fiscal général — 2018, 11e édition', '2018-01-01', 'enVigueur', 'Ouvrage de droit fiscal général, 11e édition.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'DROIT%20FISCAL%20GENERAL%202018%2011%20EDITION.pdf', array['pack-droit-fiscal-international','droit fiscal général','11e édition','2018','PDF intégral'], '{}', now()),
  ('pdf-fiscal-namayele', 'Droit fiscal — notes de cours Namayele', 'doctrine', 'fiscal', 'Notes de droit fiscal — Namayele', '2000-01-01', 'enVigueur', 'Notes de cours de droit fiscal portant le nom Namayele.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit%20Fiscal%20Namayele.pdf', array['pack-droit-fiscal-international','droit fiscal','Namayele','PDF intégral'], '{}', now()),
  ('pdf-fiscal-affaires-precis-2018', 'Droit fiscal des affaires — Précis (17e édition, 2018–2019)', 'doctrine', 'fiscal', 'Précis — droit fiscal des affaires, 17e édition, 2018–2019', '2018-01-01', 'enVigueur', 'Précis consacré au droit fiscal des affaires.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit_fiscal_des_affaires_2018_2019_17e_ed_Prcis_French_Edition.pdf', array['pack-droit-fiscal-international','fiscalité des affaires','Précis','17e édition','PDF intégral'], '{}', now()),
  ('pdf-fiscal-kola-gonze', 'Droit fiscal — Kola Gonze', 'doctrine', 'fiscal', 'Kola Gonze — Droit fiscal', '2000-01-01', 'enVigueur', 'Document de droit fiscal attribué à Kola Gonze.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'DROIT_FISCAL_kola_Gonze_%281%29.pdf', array['pack-droit-fiscal-international','droit fiscal','Kola Gonze','PDF intégral'], '{}', now()),
  ('pdf-fiscal-international-oecd-africa', 'La fiscalité internationale et l’Afrique — OCDE', 'rapport', 'fiscal', 'OCDE — La fiscalité internationale et l’Afrique', '2000-01-01', 'enVigueur', 'Document consacré à la fiscalité internationale en Afrique.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'La%20fiscalitinternationale%20et%20lAfrique.pdf', array['pack-droit-fiscal-international','fiscalité internationale','Afrique','OCDE','PDF intégral'], '{}', now()),
  ('pdf-fiscal-manuel-5e', 'Manuel de droit fiscal — 5e édition', 'doctrine', 'fiscal', 'Manuel de droit fiscal — 5e édition', '2000-01-01', 'enVigueur', 'Manuel consacré aux principes et règles de droit fiscal.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'MANUEL_DE_DROIT_FISCAL_5ED-1.pdf', array['pack-droit-fiscal-international','droit fiscal','manuel','5e édition','PDF intégral'], '{}', now()),
  ('pdf-fiscal-development-africa', 'Vers un droit fiscal de développement de l’Afrique', 'doctrine', 'fiscal', 'Analyse d’Eric — développement de l’Afrique et fiscalité', '2000-01-01', 'enVigueur', 'Étude sur le droit fiscal du développement en Afrique et l’espace OHADA.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Vers_un_droit_fiscal_de_dveloppement_de_l%27Afrique_Analyse_Eric.pdf', array['pack-droit-fiscal-international','fiscalité du développement','Afrique','OHADA','PDF intégral'], '{}', now()),
  ('pdf-fiscal-limites-pouvoir-1999', 'Les limites du pouvoir fiscal (1999)', 'doctrine', 'fiscal', 'Willemart — limites du pouvoir fiscal, 1999', '1999-01-01', 'enVigueur', 'Étude consacrée aux limites du pouvoir fiscal.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'willemart-limitespouvoirfiscal-1999.pdf', array['pack-droit-fiscal-international','pouvoir fiscal','1999','PDF intégral'], '{}', now())
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
