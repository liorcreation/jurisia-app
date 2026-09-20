-- migration_030 — Catalogue des PDF intégraux transmis pour la bibliothèque JurisIA.
--
-- Les fichiers sont publiés dans le bucket public `legal-source-pdfs`.
-- Chaque fiche est rattachée à un pack par son tag et expose le PDF original
-- via `file_url`. `summary_only = false` est volontaire : la fiche n'est pas
-- présentée comme un résumé et l'ouverture du document passe par la visionneuse
-- PDF de la bibliothèque.

do $$
declare
  base_url constant text :=
    'https://gfpguuuzzyqoxjkhlhli.supabase.co/storage/v1/object/public/legal-source-pdfs/';
begin
  update public.legal_documents d
  set file_url = base_url || v.file_name,
      summary_only = false,
      updated_at = now()
  from (values
    ('doc-onu-crc-sp-50', 'family-children-rights.pdf'),
    ('doc-doctrine-mariage-senegal', 'family-marriage-senegal.pdf'),
    ('doc-doctrine-famille-burkina', 'family-burkina.pdf'),
    ('doc-code-personnes-famille', 'family-new-code.pdf'),
    ('doc-code-personnes-famille-1989', 'family-code.pdf'),
    ('doc-these-egalite-mariage-afrique', 'family-thesis-equality.pdf'),
    ('doc-these-pluralisme-justice-mossi', 'family-thesis-pluralism.pdf')
  ) as v(document_id, file_name)
  where d.id = v.document_id;
end $$;

do $catalog$
declare
  base_url constant text :=
    'https://gfpguuuzzyqoxjkhlhli.supabase.co/storage/v1/object/public/legal-source-pdfs/';
begin
insert into public.legal_documents (
  id, title, type, domain, reference, status, summary, full_content,
  outline, summary_only, official_source_name, file_url, tags, related_ids,
  imported_at
)
values
('pdf-bank-loi-umoa', 'Loi Bancaire UMOA', 'loi', 'commercial',
 'PDF intégral — réglementation bancaire UMOA', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit bancaire et des assurances.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'bank-umoa.pdf',
 array['pack-droit-bancaire-assurances', 'droit bancaire', 'UMOA', 'PDF intégral'], '{}', now()),
('pdf-bank-bonneau', 'Droit bancaire — Thierry Bonneau', 'doctrine', 'commercial',
 'PDF intégral — support doctrinal de droit bancaire', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit bancaire et des assurances.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'bank-bonneau.pdf',
 array['pack-droit-bancaire-assurances', 'droit bancaire', 'doctrine', 'PDF intégral'], '{}', now()),
('pdf-bank-cima-2019', 'Code CIMA 2019', 'code', 'commercial',
 'PDF intégral — droit des assurances CIMA', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit bancaire et des assurances.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'bank-cima-2019.pdf',
 array['pack-droit-bancaire-assurances', 'assurances', 'Code CIMA', 'PDF intégral'], '{}', now()),

('pdf-admin-contracts', 'Droit des contrats administratifs', 'doctrine', 'administratif',
 'PDF intégral — contrats administratifs', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit administratif et jurisprudence administrative.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'admin-contracts.pdf',
 array['pack-droit-administratif', 'contrats administratifs', 'PDF intégral'], '{}', now()),
('pdf-admin-action-t1', 'Droit administratif — Tome I, L’action administrative', 'doctrine', 'administratif',
 'PDF intégral — Michel Rousset et Olivier Rousset', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit administratif et jurisprudence administrative.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'admin-action-t1.pdf',
 array['pack-droit-administratif', 'action administrative', 'PDF intégral'], '{}', now()),
('pdf-admin-contentieux-t2', 'Droit administratif — Tome II, Le contentieux administratif', 'doctrine', 'administratif',
 'PDF intégral — Michel Rousset et Olivier Rousset', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit administratif et jurisprudence administrative.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'admin-contentieux-t2.pdf',
 array['pack-droit-administratif', 'contentieux administratif', 'PDF intégral'], '{}', now()),
('pdf-admin-code-justice', 'Code de justice administrative', 'code', 'administratif',
 'PDF intégral — code de justice administrative', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit administratif et jurisprudence administrative.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'admin-code-justice.pdf',
 array['pack-droit-administratif', 'justice administrative', 'PDF intégral'], '{}', now()),

('pdf-jdp-procedure-dalloz', 'Procédure civile — Dalloz', 'doctrine', 'procedureCivile',
 'PDF intégral — procédure civile', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit judiciaire privé.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'jdp-procedure-dalloz.pdf',
 array['pack-droit-judiciaire-prive', 'procédure civile', 'PDF intégral'], '{}', now()),
('pdf-jdp-procedure-precis', 'Procédure civile — Précis Dalloz', 'doctrine', 'procedureCivile',
 'PDF intégral — procédure civile', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit judiciaire privé.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'jdp-procedure-precis.pdf',
 array['pack-droit-judiciaire-prive', 'procédure civile', 'PDF intégral'], '{}', now()),
('pdf-jdp-introduction-droit', 'Introduction au droit — thèmes fondamentaux du droit civil', 'doctrine', 'civil',
 'PDF intégral — Jean-Luc Aubert et Éric Savaux', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit judiciaire privé.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'jdp-introduction-droit.pdf',
 array['pack-droit-judiciaire-prive', 'introduction au droit', 'PDF intégral'], '{}', now()),
('pdf-jdp-droit-judiciaire-prive', 'Droit judiciaire privé — 6e édition', 'doctrine', 'procedureCivile',
 'PDF intégral — droit judiciaire privé', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit judiciaire privé.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'jdp-droit-judiciaire-prive.pdf',
 array['pack-droit-judiciaire-prive', 'droit judiciaire privé', 'PDF intégral'], '{}', now()),

('pdf-penal-bouloc', 'Droit pénal général et procédures pénales — Bouloc et Matsopoulou', 'doctrine', 'penal',
 'PDF intégral — droit pénal général et procédure pénale', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit pénal général, spécial et procédure pénale.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'penal-bouloc.pdf',
 array['pack-penal', 'droit pénal général', 'procédure pénale', 'PDF intégral'], '{}', now()),
('pdf-penal-kolb', 'Cours de droit pénal général — Kolb et Leturmy', 'doctrine', 'penal',
 'PDF intégral — droit pénal général', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit pénal général, spécial et procédure pénale.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'penal-kolb.pdf',
 array['pack-penal', 'droit pénal général', 'PDF intégral'], '{}', now()),
('pdf-penal-vogel', 'Droit pénal — Gaston Vogel 2018', 'doctrine', 'penal',
 'PDF intégral — droit pénal', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit pénal général, spécial et procédure pénale.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'penal-vogel.pdf',
 array['pack-penal', 'droit pénal', 'PDF intégral'], '{}', now()),
('pdf-penal-dps-enam', 'Cours DPS ENAM 2022', 'doctrine', 'penal',
 'PDF intégral — droit pénal spécial', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit pénal général, spécial et procédure pénale.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'penal-dps-enam.pdf',
 array['pack-penal', 'droit pénal spécial', 'PDF intégral'], '{}', now()),
('pdf-penal-special', 'Droit pénal spécial', 'doctrine', 'penal',
 'PDF intégral — droit pénal spécial', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit pénal général, spécial et procédure pénale.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'penal-special.pdf',
 array['pack-penal', 'droit pénal spécial', 'PDF intégral'], '{}', now()),
('pdf-penal-code-bf', 'Code pénal du Burkina Faso annoté et commenté', 'code', 'penal',
 'PDF intégral — Code pénal burkinabè', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit pénal général, spécial et procédure pénale.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'penal-code-bf.pdf',
 array['pack-penal', 'Code pénal burkinabè', 'PDF intégral'], '{}', now()),
('pdf-penal-general-complet', 'Cours complet de droit pénal général', 'doctrine', 'penal',
 'PDF intégral — droit pénal général', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit pénal général, spécial et procédure pénale.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'penal-general-complet.pdf',
 array['pack-penal', 'droit pénal général', 'PDF intégral'], '{}', now()),
('pdf-penal-procedure', 'Droit pénal et procédure pénale', 'doctrine', 'procedurePenale',
 'PDF intégral — droit pénal et procédure pénale', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit pénal général, spécial et procédure pénale.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'penal-procedure.pdf',
 array['pack-penal', 'procédure pénale', 'PDF intégral'], '{}', now()),
('pdf-penal-procedure-penale', 'Procédure pénale', 'doctrine', 'procedurePenale',
 'PDF intégral — procédure pénale', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit pénal général, spécial et procédure pénale.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'penal-procedure-penale.pdf',
 array['pack-penal', 'procédure pénale', 'PDF intégral'], '{}', now()),

('pdf-obl-terre-12e', 'Droit civil — Les obligations, 12e édition', 'doctrine', 'civil',
 'PDF intégral — droit civil des obligations', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-terre-12e.pdf',
 array['pack-obligations', 'droit des obligations', 'PDF intégral'], '{}', now()),
('pdf-obl-terre', 'Droit civil des obligations', 'doctrine', 'civil',
 'PDF intégral — droit civil des obligations', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-terre.pdf',
 array['pack-obligations', 'droit des obligations', 'PDF intégral'], '{}', now()),
('pdf-obl-porchy-simon', 'Droit des obligations 2021 — 13e édition', 'doctrine', 'civil',
 'PDF intégral — droit des obligations', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-porchy-simon-2021.pdf',
 array['pack-obligations', 'droit des obligations', 'PDF intégral'], '{}', now()),
('pdf-obl-annales-methodologie', 'Annales de droit civil des obligations 2021 — méthodologie et sujets corrigés', 'rapport', 'civil',
 'PDF intégral — annales et méthodologie', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-annales-methodologie.pdf',
 array['pack-obligations', 'annales', 'méthodologie', 'PDF intégral'], '{}', now()),
('pdf-obl-annales-nnn', 'Annales de droit civil des obligations', 'rapport', 'civil',
 'PDF intégral — annales', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-annales-nnn.pdf',
 array['pack-obligations', 'annales', 'PDF intégral'], '{}', now()),
('pdf-obl-technique-contractuelle', 'Technique contractuelle', 'doctrine', 'civil',
 'PDF intégral — technique contractuelle', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-technique-contractuelle.pdf',
 array['pack-obligations', 'contrats', 'technique contractuelle', 'PDF intégral'], '{}', now()),
('pdf-obl-renault-brahinsky', 'Droit des obligations — Corinne Renault-Brahinsky', 'doctrine', 'civil',
 'PDF intégral — droit des obligations', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-renault-brahinsky.pdf',
 array['pack-obligations', 'droit des obligations', 'PDF intégral'], '{}', now()),
('pdf-obl-civil-2e-annee', 'Droit civil, 2e année — Les obligations', 'doctrine', 'civil',
 'PDF intégral — cours de droit civil', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-civil-2e-annee.pdf',
 array['pack-obligations', 'droit des obligations', 'PDF intégral'], '{}', now()),
('pdf-obl-contrats-gorlier', 'Droit des contrats spéciaux — Gorlier', 'doctrine', 'civil',
 'PDF intégral — contrats spéciaux', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-contrats-gorlier.pdf',
 array['pack-obligations', 'contrats spéciaux', 'PDF intégral'], '{}', now()),
('pdf-obl-essentiel-obligations', 'L’essentiel du droit des obligations 2021', 'doctrine', 'civil',
 'PDF intégral — droit des obligations', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-essentiel-obligations.pdf',
 array['pack-obligations', 'droit des obligations', 'PDF intégral'], '{}', now()),
('pdf-obl-malaurie-contrats-1', 'Droit des contrats spéciaux — Malaurie', 'doctrine', 'civil',
 'PDF intégral — contrats spéciaux', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-malaurie-contrats-1.pdf',
 array['pack-obligations', 'contrats spéciaux', 'PDF intégral'], '{}', now()),
('pdf-obl-mementos', 'Droit des obligations — Mémentos', 'doctrine', 'civil',
 'PDF intégral — droit des obligations', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-mementos.pdf',
 array['pack-obligations', 'droit des obligations', 'PDF intégral'], '{}', now()),
('pdf-obl-contrats-malaurie-2', 'Droit des contrats spéciaux — Malaurie, Aunès et Gautier', 'doctrine', 'civil',
 'PDF intégral — contrats spéciaux', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-contrats-malaurie-2.pdf',
 array['pack-obligations', 'contrats spéciaux', 'PDF intégral'], '{}', now()),
('pdf-obl-annales-methodologie-2', 'Annales de droit civil des obligations 2021 — méthodologie et sujets corrigés', 'rapport', 'civil',
 'PDF intégral — annales et méthodologie', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-annales-methodologie-2.pdf',
 array['pack-obligations', 'annales', 'méthodologie', 'PDF intégral'], '{}', now()),
('pdf-obl-essentiel-contrats-speciaux', 'L’essentiel du droit des contrats spéciaux 2020–2021', 'doctrine', 'civil',
 'PDF intégral — contrats spéciaux', 'enVigueur',
 'Document PDF intégral rattaché au pack Droit des obligations.', '',
 '{}', false, 'Document transmis au groupe JurisIA', base_url || 'obl-essentiel-contrats-speciaux.pdf',
 array['pack-obligations', 'contrats spéciaux', 'PDF intégral'], '{}', now())
on conflict (id) do update set
  title = excluded.title,
  type = excluded.type,
  domain = excluded.domain,
  reference = excluded.reference,
  status = excluded.status,
  summary = excluded.summary,
  full_content = excluded.full_content,
  outline = excluded.outline,
  summary_only = excluded.summary_only,
  official_source_name = excluded.official_source_name,
  file_url = excluded.file_url,
  tags = excluded.tags,
  related_ids = excluded.related_ids,
  imported_at = excluded.imported_at;
end $catalog$;

-- Les ouvrages dépassant la limite globale de stockage sont publiés en
-- volumes PDF consécutifs, sans perte de pages.
do $volumes$
declare
  base_url constant text :=
    'https://gfpguuuzzyqoxjkhlhli.supabase.co/storage/v1/object/public/legal-source-pdfs/';
begin
  update public.legal_documents
  set title = 'Procédure civile — Dalloz — volume 1/3',
      file_url = base_url || 'jdp-procedure-dalloz-part-1.pdf',
      summary_only = false,
      updated_at = now()
  where id = 'pdf-jdp-procedure-dalloz';
  update public.legal_documents
  set title = 'Introduction au droit — volume 1/2',
      file_url = base_url || 'jdp-introduction-droit-part-1.pdf',
      summary_only = false,
      updated_at = now()
  where id = 'pdf-jdp-introduction-droit';

  insert into public.legal_documents (
    id, title, type, domain, reference, status, summary, full_content,
    outline, summary_only, official_source_name, file_url, tags, related_ids,
    imported_at
  ) values
  ('pdf-jdp-procedure-dalloz-2', 'Procédure civile — Dalloz — volume 2/3', 'doctrine', 'procedureCivile',
   'PDF intégral — volume 2/3', 'enVigueur', 'Deuxième volume PDF intégral du document.', '', '{}', false,
   'Document transmis au groupe JurisIA', base_url || 'jdp-procedure-dalloz-part-2.pdf',
   array['pack-droit-judiciaire-prive', 'procédure civile', 'PDF intégral'], '{}', now()),
  ('pdf-jdp-procedure-dalloz-3', 'Procédure civile — Dalloz — volume 3/3', 'doctrine', 'procedureCivile',
   'PDF intégral — volume 3/3', 'enVigueur', 'Troisième volume PDF intégral du document.', '', '{}', false,
   'Document transmis au groupe JurisIA', base_url || 'jdp-procedure-dalloz-part-3.pdf',
   array['pack-droit-judiciaire-prive', 'procédure civile', 'PDF intégral'], '{}', now()),
  ('pdf-jdp-introduction-droit-2', 'Introduction au droit — volume 2/2', 'doctrine', 'civil',
   'PDF intégral — volume 2/2', 'enVigueur', 'Deuxième volume PDF intégral du document.', '', '{}', false,
   'Document transmis au groupe JurisIA', base_url || 'jdp-introduction-droit-part-2.pdf',
   array['pack-droit-judiciaire-prive', 'introduction au droit', 'PDF intégral'], '{}', now()),
  ('pdf-admin-contentieux-cours', 'Cours de contentieux administratif', 'doctrine', 'administratif',
   'PDF intégral converti depuis le document transmis', 'enVigueur',
   'Document PDF intégral rattaché au pack Droit administratif et jurisprudence administrative.', '', '{}', false,
   'Document transmis au groupe JurisIA', base_url || 'admin-contentieux-cours.pdf',
   array['pack-droit-administratif', 'contentieux administratif', 'PDF intégral'], '{}', now())
  on conflict (id) do update set
    title = excluded.title, type = excluded.type, domain = excluded.domain,
    reference = excluded.reference, summary = excluded.summary,
    full_content = excluded.full_content, summary_only = false,
    official_source_name = excluded.official_source_name,
    file_url = excluded.file_url, tags = excluded.tags,
    imported_at = excluded.imported_at;

  update public.legal_documents
  set tags = case when 'pack-droit-famille' = any(tags) then tags else array_append(tags, 'pack-droit-famille') end,
      summary_only = false,
      updated_at = now()
  where id in (
    'doc-onu-crc-sp-50', 'doc-doctrine-mariage-senegal',
    'doc-doctrine-famille-burkina', 'doc-code-personnes-famille',
    'doc-code-personnes-famille-1989', 'doc-these-egalite-mariage-afrique',
    'doc-these-pluralisme-justice-mossi'
  );
end $volumes$;
