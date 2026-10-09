-- migration_041 — Pack droit du travail et sécurité sociale.
-- Deux PDF sont ajoutés au catalogue ; le PDF pénal/social existant est
-- simplement rattaché au pack afin d’éviter toute entrée en doublon.

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
  ('pdf-labor-droit-travail-en-pratique-mine-marchand', 'Le droit du travail en pratique', 'doctrine', 'travail', 'Michel Miné et Daniel Marchand — 2009', '2009-05-14', 'enVigueur', 'Ouvrage de droit du travail présentant les règles et pratiques françaises dans leur édition de 2009 ; les évolutions ultérieures doivent être vérifiées séparément.', '', '{}', false, 'PDF transmis à JurisIA', base_url || 'Droit%20du%20travail%20(3)%20(1).pdf', array['pack-droit-travail-securite-sociale','droit du travail','relations professionnelles','France','PDF intégral'], '{}', now()),
  ('pdf-labor-introduction-droit-travail-mali', 'Introduction au droit du travail — Mali', 'doctrine', 'travail', 'Centre de recherches, de documentations et de sondage d’opinions — Dr de Souza, juriste-consultant', '2014-10-15', 'enVigueur', 'Cours d’introduction centré sur le droit du travail malien et ses sources, notamment la loi n° 92-020 du 23 septembre 1992 citée dans le document.', '', '{}', false, 'PDF transmis à JurisIA', base_url || 'INTRODUCTION%20AU%20DROIT%20DU%20TRAVAIL%20(1).pdf', array['pack-droit-travail-securite-sociale','droit du travail','droit malien','cours','PDF intégral'], '{}', now())
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

  update public.legal_documents
  set tags = array_append(coalesce(tags, array[]::text[]), 'pack-droit-travail-securite-sociale'),
      updated_at = now()
  where id = 'pdf-penal-travail-securite-sociale'
    and not ('pack-droit-travail-securite-sociale' = any(coalesce(tags, array[]::text[])));
end $catalog$;
