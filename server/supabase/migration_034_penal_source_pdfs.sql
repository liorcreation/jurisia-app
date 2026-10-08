-- migration_034 — PDF intégraux reçus pour les packs pénal et procédure pénale.
-- Trois fichiers de ce lot (le code 2018, le Bouloc et le Verny complémentaire)
-- correspondent à des références déjà présentes dans le bucket et au catalogue.
-- Les sept documents nouveaux donnent huit volumes PDF, Larcier étant scindé
-- en deux parties consécutives pour respecter le plafond de 50 Mo du bucket.

do $catalog$
declare
  base_url constant text :=
    'https://gfpguuuzzyqoxjkhlhli.supabase.co/storage/v1/object/public/legal-source-pdfs/';
begin
  insert into public.legal_documents (
    id, title, type, domain, reference, date_publication, status, summary,
    full_content, outline, summary_only, official_source_name, file_url,
    tags, related_ids, imported_at
  )
  values
  ('pdf-penal-code-burkina-1996', 'Code pénal du Burkina Faso — édition 1996 (archive)', 'code', 'penal',
   'Loi n° 043/96/ADP du 13 novembre 1996 — version historique', '1996-11-13', 'abroge',
   'Texte historique du Code pénal burkinabè. Consulter l’édition applicable aux faits avant toute utilisation.',
   '', '{}', false, 'Copie PDF transmise à JurisIA — archive historique',
   base_url || 'CODE%20PENAL%20du%20Burkina%20Faso.pdf',
   array['pack-penal', 'droit pénal général', 'Burkina Faso', 'archive historique', 'PDF intégral'], '{}', now()),
  ('pdf-penal-exercices-corriges', 'Droit pénal — exercices corrigés', 'doctrine', 'penal',
   'Support d’exercices transmis à JurisIA', '2020-06-24', 'enVigueur',
   'Exercices corrigés de droit pénal pour s’entraîner à la qualification et au raisonnement.',
   '', '{}', false, 'Document transmis à JurisIA',
   base_url || '%40SciencesJuridiques%20Droit%20pnal%20Exercice-Corrig.pdf',
   array['pack-penal', 'droit pénal général', 'exercices corrigés', 'méthodologie', 'PDF intégral'], '{}', now()),
  ('pdf-penal-compare-pradel-2016', 'Droit pénal comparé — Jean Pradel', 'doctrine', 'penal',
   'Jean Pradel — Précis, Dalloz, édition 2016', '2016-01-01', 'enVigueur',
   'Étude de droit pénal comparé. Le fichier transmis est consultable en PDF intégral.',
   '', '{}', false, 'Document transmis à JurisIA',
   base_url || 'Droit%20pnal%20compar%20(Prcis)%20(French%20Edition)%20--%20Pradel%2C%20Jean%20--%202016%20--%20Dalloz%20--%20f37cec40964beb26192c0790f678b442%20--%20Annas%20Archive.pdf',
   array['pack-penal', 'droit pénal comparé', 'Jean Pradel', 'doctrine', 'PDF intégral'], '{}', now()),
  ('pdf-penal-general-larcier-part-1', 'Droit pénal général — Larcier (partie 1/2)', 'doctrine', 'penal',
   'PDF intégral réparti — pages 1 à 209 sur 419', '2020-04-19', 'enVigueur',
   'Première partie du PDF Larcier, pages 1 à 209. Le volume 2/2 contient la suite sans omission.',
   '', '{}', false, 'Document transmis à JurisIA — volume 1/2',
   base_url || 'penal-general-larcier-part-1-of-2.pdf',
   array['pack-penal', 'droit pénal général', 'Larcier', 'doctrine', 'PDF intégral', 'volume 1/2'], '{}', now()),
  ('pdf-penal-general-larcier-part-2', 'Droit pénal général — Larcier (partie 2/2)', 'doctrine', 'penal',
   'PDF intégral réparti — pages 210 à 419 sur 419', '2020-04-19', 'enVigueur',
   'Seconde partie du PDF Larcier, pages 210 à 419. Elle complète le volume 1/2.',
   '', '{}', false, 'Document transmis à JurisIA — volume 2/2',
   base_url || 'penal-general-larcier-part-2-of-2.pdf',
   array['pack-penal', 'droit pénal général', 'Larcier', 'doctrine', 'PDF intégral', 'volume 2/2'], '{}', now()),
  ('pdf-penal-travail-securite-sociale', 'Droit pénal du travail et de la sécurité sociale', 'doctrine', 'penal',
   'Guy — document transmis à JurisIA', '2007-10-25', 'enVigueur',
   'Ressource consacrée aux infractions et règles pénales liées au travail et à la sécurité sociale.',
   '', '{}', false, 'Document transmis à JurisIA',
   base_url || 'Droit_pnal_du_travail_et_le_droit_de_la_scurit_sociale_de_BOU.pdf',
   array['pack-penal', 'droit pénal du travail', 'sécurité sociale', 'droit social', 'PDF intégral'], '{}', now()),
  ('pdf-penal-general-barres', 'Droit pénal général — Garance Barrès', 'doctrine', 'penal',
   'Garance Barrès — support daté de 2016 dans les métadonnées PDF', '2016-01-20', 'enVigueur',
   'Support de droit pénal général consultable dans son PDF intégral.',
   '', '{}', false, 'Document transmis à JurisIA',
   base_url || 'Droit-pnal-gnral.pdf',
   array['pack-penal', 'droit pénal général', 'Garance Barrès', 'cours', 'PDF intégral'], '{}', now()),
  ('pdf-procedure-penale-verny-2018', 'Procédure pénale — Édouard Verny', 'doctrine', 'procedurePenale',
   'Édouard Verny — Cours Dalloz, 6e édition, Paris, 2018', '2018-01-01', 'enVigueur',
   'Cours de procédure pénale, 6e édition, disponible dans son PDF intégral.',
   '', '{}', false, 'Document transmis à JurisIA',
   base_url || 'Je%20partage%20Procdure%20pnale%20(Cours%20Dalloz)%20Sixime%20dition%20--%20Edouard%20Verny%20--%20Cours%20Dalloz_%20Serie%20Droit%20prive%2C%206e%20edition%2C%20Paris%2C%202018%20--%20Dalloz%20--%209782247179718%20--%20a8dac1d7784be6ace18b8125ce1fbe18%20--%20Annas%20Archive%20avec%20vous.pdf',
   array['pack-penal', 'procédure pénale', 'Édouard Verny', 'Cours Dalloz', 'PDF intégral'], '{}', now())
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
