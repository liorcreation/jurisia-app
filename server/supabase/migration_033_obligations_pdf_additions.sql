-- migration_033 — Références PDF supplémentaires du pack Obligations.
-- Les fichiers originaux sont publiés dans legal-source-pdfs après l'accord
-- explicite de l'équipe. Les doublons binaires du lot sont réutilisés depuis
-- les objets existants; seuls les huit nouveaux documents sont référencés ici.

do $$
declare
  base_url constant text :=
    'https://gfpguuuzzyqoxjkhlhli.supabase.co/storage/v1/object/public/legal-source-pdfs/';
begin
  insert into public.legal_documents (
    id, title, type, domain, reference, date_publication, status, summary, full_content,
    outline, summary_only, official_source_name, file_url, tags, related_ids,
    imported_at
  )
  values
  ('doc-obl-annales-2018-lasserre', 'Droit des obligations — Annales 2018', 'doctrine', 'civil',
   'Marie-Cécile Lasserre, Sophie Druffin-Bricca et Jean-Raphaël Demarchi — édition 2018', '2018-01-01', 'enVigueur',
   'Annales de droit des obligations — document PDF intégral.', '', '{}', false,
   'Document transmis à JurisIA', base_url || 'Annale%20-%20Droit%20des%20obligations%20(2).pdf',
   array['pack-obligations', 'droit civil', 'annales', 'PDF intégral'], '{}', now()),
  ('doc-obl-cours-amelie', 'Droit civil — Les obligations, tome 2', 'doctrine', 'civil',
   'Amélie Dionisi-Peyrusse — préparation au concours d’attaché territorial', '2012-01-01', 'enVigueur',
   'Support de droit civil des obligations — document PDF intégral.', '', '{}', false,
   'Document transmis à JurisIA', base_url || 'DROIT%20CIVIL%20DES%20OBLIGATIONS%20D''AMELIE.pdf',
   array['pack-obligations', 'droit civil', 'cours', 'PDF intégral'], '{}', now()),
  ('doc-obl-renault-brahinsky-cours', 'Droit civil des obligations — Corinne Renault-Brahinsky', 'doctrine', 'civil',
   'Corinne Renault-Brahinsky — Mémentos, 16e éd., 2019/2020', '2019-01-01', 'enVigueur',
   'Ouvrage de droit civil des obligations — document PDF intégral.', '', '{}', false,
   'Document transmis à JurisIA', base_url || 'Droit%20civil%20des%20Obligations%20de%20Corinne%20Renault-Brahinsky.pdf',
   array['pack-obligations', 'droit civil', 'doctrine', 'PDF intégral'], '{}', now()),
  ('doc-obl-crfpa-session-2022', 'Droit des obligations — CRFPA, session 2022', 'doctrine', 'civil',
   'Nathalie Blanc, Mathias Latina et Denis Mazeaud — 3e éd., examen national 2022', '2022-01-01', 'enVigueur',
   'Préparation CRFPA en droit des obligations — document PDF intégral.', '', '{}', false,
   'Document transmis à JurisIA', base_url || 'Droit%20des%20obligations%20-%20CRFPA%20-%20Examen%20national%20Session%20--%20Mazeaud%2C%20Denis%2C%20Latina%2C%20Mathias%2C%20Blanc%2C%20Nathal.pdf',
   array['pack-obligations', 'droit civil', 'CRFPA', 'PDF intégral'], '{}', now()),
  ('doc-obl-cours-kenge', 'Droit des obligations — Cours Kenge', 'doctrine', 'civil',
   'Cours attribué à Kenge — date éditoriale non renseignée', '2012-01-01', 'enVigueur',
   'Cours de droit des obligations — document PDF intégral.', '', '{}', false,
   'Document transmis à JurisIA', base_url || 'Droit%20des%20obligations%20KENGE.pdf',
   array['pack-obligations', 'droit civil', 'cours', 'PDF intégral'], '{}', now()),
  ('doc-obl-malaurie-general', 'Droit des obligations — Philippe Malaurie et Laurent Aynès', 'doctrine', 'civil',
   'Philippe Malaurie, Laurent Aynès et Philippe Stoffel-Munck — 8e édition', '2017-01-01', 'enVigueur',
   'Ouvrage de droit des obligations — document PDF intégral.', '', '{}', false,
   'Document transmis à JurisIA', base_url || 'Droit_Civil_des_obligations_de_Philippe_Malaurie_et_Laurent_Ayns.pdf',
   array['pack-obligations', 'droit civil', 'doctrine', 'PDF intégral'], '{}', now()),
  ('doc-obl-aubert-de-vincelles-tome-1', 'Droit des obligations — Tome I, Prépa Dalloz', 'doctrine', 'civil',
   'Support de cours — examen du CRFPA 2016', '2016-01-01', 'enVigueur',
   'Ouvrage de droit civil des obligations — document PDF intégral.', '', '{}', false,
   'Document transmis à JurisIA', base_url || 'Droit_civil_des_obligations_tome_1_de_Carole_AUBERT_DE_VINCELLES.pdf',
   array['pack-obligations', 'droit civil', 'doctrine', 'PDF intégral'], '{}', now()),
  ('doc-obl-reussir-td-brusorio-aillaud', 'Réussir ses TD en droit des obligations', 'doctrine', 'civil',
   'Marjorie Brusorio-Aillaud — ouvrage de méthodologie, 2e éd.', '2019-01-01', 'enVigueur',
   'Outils de méthodologie en droit des obligations — document PDF intégral.', '', '{}', false,
   'Document transmis à JurisIA', base_url || 'Russir%20ses%20TD%20en%20droit%20des%20obligations%20de%20Marjorie%20Brusorio%20Aillaud.pdf',
   array['pack-obligations', 'droit civil', 'travaux dirigés', 'méthodologie', 'PDF intégral'], '{}', now())
  on conflict (id) do update set
    title = excluded.title,
    type = excluded.type,
    domain = excluded.domain,
    reference = excluded.reference,
    date_publication = excluded.date_publication,
    summary = excluded.summary,
    full_content = excluded.full_content,
    outline = excluded.outline,
    summary_only = false,
    official_source_name = excluded.official_source_name,
    file_url = excluded.file_url,
    tags = excluded.tags,
    related_ids = excluded.related_ids,
    updated_at = now();
end $$;
