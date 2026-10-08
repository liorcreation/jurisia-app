-- migration_032 — PDF lisibles pour les références du pack Obligations et
-- les cours pédagogiques originaux déjà rédigés par JurisIA.
--
-- Les neuf références du pack Obligations pointent vers les fichiers sources
-- déjà présents dans legal-source-pdfs. Les cours originaux JurisIA pointent
-- vers des PDF mis en page à partir, sans réécriture, de leur full_content.
-- Appliquer après les migrations 024 à 028 et après le téléversement des
-- quatorze PDF course-*-jurisia.pdf dans le bucket public.

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
    -- Fichiers source fournis pour le pack Droit des obligations.
    ('doc-doctrine-terre-obligations', 'obl-terre-12e.pdf'),
    ('doc-doctrine-porchy-simon-obligations', 'obl-porchy-simon-2021.pdf'),
    ('doc-annales-obligations-dalloz', 'obl-annales-methodologie.pdf'),
    ('doc-technique-contractuelle-meyer', 'obl-technique-contractuelle.pdf'),
    ('doc-gorlier-contrats-speciaux', 'obl-contrats-gorlier.pdf'),
    ('doc-malaurie-contrats-speciaux', 'obl-contrats-malaurie-2.pdf'),
    ('doc-renault-brahinsky-obligations-mementos', 'obl-mementos.pdf'),
    ('doc-boustani-contrats-speciaux', 'obl-essentiel-contrats-speciaux.pdf'),
    ('doc-renault-brahinsky-obligations-essentiel', 'obl-essentiel-obligations.pdf'),

    -- Cours originaux JurisIA ; chaque fichier conserve le contenu intégral
    -- des constantes fullContent déjà publiées dans les migrations 024-028.
    ('doc-jurisia-cours-complet-obligations', 'course-obligations-jurisia.pdf'),
    ('doc-jurisia-cours-complet-droit-penal-general', 'course-penal-general-jurisia.pdf'),
    ('doc-jurisia-cours-complet-droit-penal-special', 'course-penal-special-jurisia.pdf'),
    ('doc-jurisia-cours-complet-procedure-penale', 'course-procedure-penale-jurisia.pdf'),
    ('doc-jurisia-fondements-droit-judiciaire-prive', 'course-droit-judiciaire-prive-jurisia.pdf'),
    ('doc-jurisia-procedure-civile-complete', 'course-procedure-civile-jurisia.pdf'),
    ('doc-jurisia-juridictions-execution-civile', 'course-execution-civile-jurisia.pdf'),
    ('doc-jurisia-action-administrative', 'course-action-administrative-jurisia.pdf'),
    ('doc-jurisia-contrats-administratifs', 'course-contrats-administratifs-jurisia.pdf'),
    ('doc-jurisia-contentieux-administratif', 'course-contentieux-administratif-jurisia.pdf'),
    ('doc-jurisia-droit-bancaire-general', 'course-droit-bancaire-jurisia.pdf'),
    ('doc-jurisia-droit-bancaire-umoa', 'course-reglementation-umoa-jurisia.pdf'),
    ('doc-jurisia-droit-assurances-cima', 'course-assurances-cima-jurisia.pdf'),
    ('doc-modele-neutre-acte-juridique', 'course-modele-neutre-acte-juridique-jurisia.pdf')
  ) as v(document_id, file_name)
  where d.id = v.document_id;
end $$;
