-- migration_040 — Cinq PDF transmis pour compléter le volet assurances.

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
  ('pdf-insurance-liability-civil-2018', 'Responsabilité civile et assurances — Actualités 2018', 'rapport', 'commercial', 'Ordre des avocats de Paris, Commission Assurances et Responsabilité civile — réunion du 18 janvier 2018', '2018-01-18', 'enVigueur', 'Dossier de veille consacré aux actualités législatives et jurisprudentielles en droit des assurances.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'assurances_et_responsabilite_civile_18_janvier_2018.pdf', array['pack-droit-bancaire-assurances','droit des assurances','responsabilité civile','veille juridique','PDF intégral'], '{}', now()),
  ('pdf-insurance-course-rouen', 'Droit approfondi des assurances — Université de Rouen', 'doctrine', 'commercial', 'Cours universitaire — Droit approfondi des assurances', '2013-08-21', 'enVigueur', 'Cours universitaire portant sur la théorie générale du droit des assurances, les assurances de dommages et les assurances de personnes.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit%20cours%2C%20droit%20approfondi%20des%20Assurances.pdf', array['pack-droit-bancaire-assurances','droit des assurances','cours universitaire','PDF intégral'], '{}', now()),
  ('pdf-insurance-risk-management-wagner-fuino', 'Gestion du risque et introduction aux assurances', 'doctrine', 'commercial', 'Joël Wagner et Michel Fuino — Gestion du risque & introduction aux assurances', '2021-12-21', 'enVigueur', 'Ouvrage introductif consacré à la gestion des risques et aux mécanismes fondamentaux de l’assurance.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Gestion_du_risque_et_introduction_aux_assurances__ed1_v1.pdf', array['pack-droit-bancaire-assurances','droit des assurances','gestion du risque','Joël Wagner','Michel Fuino','PDF intégral'], '{}', now()),
  ('pdf-insurance-enterprise-bergeron', 'Le droit des assurances et l’entreprise', 'doctrine', 'commercial', 'Jean-Guy Bergeron — Le droit des assurances et l’entreprise', '1983-01-01', 'enVigueur', 'Étude doctrinale sur le contrat d’assurance et ses liens avec l’activité de l’entreprise.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'LE%20DROIT%20DES%20ASSURANCES%20ET%20L%27ENTREPRISE.pdf', array['pack-droit-bancaire-assurances','droit des assurances','entreprise','Jean-Guy Bergeron','PDF intégral'], '{}', now()),
  ('pdf-insurance-enterprise-risks-medjebeur', 'Les assurances des risques d’entreprises', 'doctrine', 'commercial', 'Nora Fodil Medjebeur — Thèse de doctorat, Université d’Oran 2', '2000-01-01', 'enVigueur', 'Thèse consacrée aux assurances des risques d’entreprise et à leur cadre juridique.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Les%20assurances%20des%20risques%20d%27entreprises.pdf', array['pack-droit-bancaire-assurances','droit des assurances','risques d’entreprise','Nora Fodil Medjebeur','thèse','PDF intégral'], '{}', now())
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
