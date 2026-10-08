-- migration_037 — PDF intégraux du pack droit des sûretés.
-- Deux ouvrages ont chacun une copie binaire identique ; une seule est cataloguée.

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
  ('pdf-suretes-cours-ohada-introduction', 'Cours de droit des sûretés OHADA', 'doctrine', 'ohada', 'Cours de droit des sûretés OHADA', '2000-01-01', 'enVigueur', 'Cours consacré au droit des sûretés dans l’espace OHADA.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'cours%20de%20droit%20des%20srets%20OHADA_.pdf', array['pack-droit-suretes','sûretés OHADA','cours','PDF intégral'], '{}', now()),
  ('pdf-suretes-cours-ohada-espace', 'Cours de droit des sûretés dans l’espace OHADA', 'doctrine', 'ohada', 'Cours de droit des sûretés dans l’espace OHADA', '2000-01-01', 'enVigueur', 'Cours de droit des garanties dans l’espace OHADA.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Cours%20droit%20des%20srets%20dans%20l%27espace%20ohada.pdf', array['pack-droit-suretes','sûretés OHADA','cours','PDF intégral'], '{}', now()),
  ('pdf-suretes-cours-ohada-general', 'Droit des sûretés OHADA — cours général', 'doctrine', 'ohada', 'Cours de droit des sûretés OHADA', '2000-01-01', 'enVigueur', 'Support de cours sur le droit OHADA des sûretés.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'COURS-DE-DROIT-DES-SURETES-OHADA.pdf', array['pack-droit-suretes','sûretés OHADA','cours','PDF intégral'], '{}', now()),
  ('pdf-suretes-10e-edition', 'Droit des sûretés — 10e édition', 'doctrine', 'civil', 'Droit des sûretés — 10e édition', '2000-01-01', 'enVigueur', 'Ouvrage consacré au droit des sûretés, 10e édition.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit%20des%20srets%20-%2010e%20dition.pdf', array['pack-droit-suretes','droit civil','10e édition','PDF intégral'], '{}', now()),
  ('pdf-suretes-wolou-komi', 'Droit des sûretés — Wolou Komi', 'doctrine', 'ohada', 'Wolou Komi — Droit des sûretés', '2000-01-01', 'enVigueur', 'Document de droit des sûretés attribué à Wolou Komi.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Droit%20des%20srets%20de%20WOLOU%20Komi.pdf', array['pack-droit-suretes','sûretés OHADA','Wolou Komi','PDF intégral'], '{}', now()),
  ('pdf-suretes-general', 'Droit des sûretés', 'doctrine', 'civil', 'Droit des sûretés', '2000-01-01', 'enVigueur', 'Document de référence consacré au droit des sûretés.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'droit%20des%20srets.pdf', array['pack-droit-suretes','droit civil','sûretés','PDF intégral'], '{}', now()),
  ('pdf-suretes-master-dabire', 'Droit des sûretés — Master 1, Dabiré', 'doctrine', 'ohada', 'Master 1 — Droit des sûretés, Dabiré', '2000-01-01', 'enVigueur', 'Support de Master 1 consacré au droit des sûretés.', '', '{}', false, 'Document transmis à JurisIA', base_url || 'Master%201%20Droit%20des%20Suretes%20DABIRE.pdf', array['pack-droit-suretes','sûretés OHADA','Master 1','PDF intégral'], '{}', now())
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
