-- migration_039 — PDF du pack Sciences politiques.
-- Les trois copies portant « (1) » sont identiques aux fichiers sans suffixe.

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
  ('pdf-political-science-dictionary-hermet-badie', 'Dictionnaire de la science politique', 'doctrine', 'constitutionnel', 'Guy Hermet et Bertrand Badie — Dictionnaire de la science politique', '2000-01-01', 'enVigueur', 'Dictionnaire de science politique transmis à JurisIA.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Dictionnaire%20de%20la%20science%20poli%20-%20Guy%20Hermet%3BBertrand%20Badie%3B.pdf', array['pack-sciences-politiques','science politique','Guy Hermet','Bertrand Badie','PDF intégral'], '{}', now()),
  ('pdf-political-science-dictionary-institutions', 'Dictionnaire de la science politique et des institutions politiques', 'doctrine', 'constitutionnel', 'Dictionnaire de la science politique et des institutions politiques', '2000-01-01', 'enVigueur', 'Dictionnaire consacré à la science politique et aux institutions politiques.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Dictionnaire_de_la_science_politique_et_des_institutions_politiq.pdf', array['pack-sciences-politiques','science politique','institutions politiques','PDF intégral'], '{}', now()),
  ('pdf-political-science-course', 'Sciences politiques', 'doctrine', 'constitutionnel', 'Sciences politiques — support de cours', '2000-01-01', 'enVigueur', 'Support de cours de sciences politiques transmis à JurisIA.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Sciences%20politiques.pdf', array['pack-sciences-politiques','science politique','cours','PDF intégral'], '{}', now()),
  ('pdf-political-science-kelsen-theory-law', 'Théorie pure du droit — Hans Kelsen', 'doctrine', 'constitutionnel', 'Hans Kelsen — Théorie pure du droit (1962)', '1962-01-01', 'enVigueur', 'Ouvrage de théorie du droit transmis à JurisIA.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Theorie%20Pure%20Du%20Droit%201962%20Hans%20Kelsen.pdf', array['pack-sciences-politiques','théorie du droit','Hans Kelsen','PDF intégral'], '{}', now())
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
