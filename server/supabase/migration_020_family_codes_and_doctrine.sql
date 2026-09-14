-- Extension de la collection « Droit des personnes et de la famille ».
--
-- Le Code de 2025 est la référence actuellement en vigueur. Le texte de 1989
-- reste disponible comme repère historique, avec le statut « abroge ».
-- Les deux thèses sont indexées sous forme de métadonnées et de synthèses :
-- leurs textes intégraux ne sont pas reproduits dans le corpus public.

insert into public.legal_documents (
  id, title, type, domain, reference, date_publication, status, summary,
  full_content, outline, summary_only, official_source_name, source_url, tags,
  related_ids, imported_at
)
values
(
  'doc-code-personnes-famille',
  'Code des personnes et de la famille du Burkina Faso',
  'code',
  'famille',
  'Loi n° 012-2025/ALT du 1er septembre 2025, promulguée par le décret n° 2025-1232/PF du 25 septembre 2025',
  '2025-09-01',
  'enVigueur',
  'Texte actuellement en vigueur : personnes, état civil, famille, mariage, filiation, parentalité et successions.',
  'La loi n° 012-2025/ALT du 1er septembre 2025 organise le droit des personnes et de la famille au Burkina Faso. Elle encadre notamment la jouissance des droits civils, l''identification et l''état civil, le mariage, la filiation, l''autorité parentale, la protection des personnes vulnérables et les successions. La fiche JurisIA renvoie au texte publié au Journal officiel. Elle remplace la fiche du Code de 1989 : celui-ci est conservé séparément comme archive historique, car l''article 322-3 du Code de 2025 l''abroge expressément.',
  array['Première partie — Des personnes', 'Personnes physiques, droits civils, absence et disparition', 'Identification et état civil', 'Droit de la famille : mariage, filiation et parentalité', 'Régimes patrimoniaux, libéralités et successions', 'Dispositions transitoires et abrogatoires'],
  true,
  'Journal officiel du Faso / Légiburkina',
  'https://www.legiburkina.bf',
  array['famille', 'mariage', 'succession', 'état civil', 'droit positif', 'Burkina Faso'],
  array['doc-constitution'],
  now()
),
(
  'doc-code-personnes-famille-1989',
  'Code des personnes et de la famille — archive 1989',
  'code',
  'famille',
  'Zatu n° AN VII-0013/FP/PRES du 16 novembre 1989',
  '1989-11-16',
  'abroge',
  'Archive historique : le Code de 1989 a été expressément abrogé par l''article 322-3 de la loi n° 012-2025/ALT.',
  'Cette fiche conserve un repère documentaire vers l''ancien Code des personnes et de la famille, applicable de 1989 à son remplacement par le Code de 2025. Ses règles ne doivent pas être citées comme droit positif. Elle reste utile pour lire la doctrine, la jurisprudence et les situations juridiques antérieures au nouveau Code.',
  array['Première partie — Des personnes', 'État civil et identification', 'Deuxième partie — De la famille', 'Successions, libéralités et régimes matrimoniaux'],
  true,
  'Archive législative — texte transmis',
  null,
  array['archive', 'code abrogé', 'famille', 'mariage', 'état civil', 'Burkina Faso'],
  array['doc-code-personnes-famille'],
  now()
),
(
  'doc-these-egalite-mariage-afrique',
  'L''égalité de l''homme et de la femme dans le mariage en Afrique noire francophone',
  'doctrine',
  'famille',
  'Aïssata Dabo — Thèse de doctorat en cotutelle, Universités de Bordeaux et d''Abomey-Calavi, 15 décembre 2017',
  '2017-12-15',
  'enVigueur',
  'Étude comparée des droits du Bénin, du Burkina Faso et du Mali sur l''égalité dans le mariage, le pluralisme juridique et l''effectivité des droits des femmes.',
  'La thèse étudie les écarts entre les réformes des droits de la famille et leur effectivité, en particulier dans la formation, l''exécution et la dissolution du mariage. Elle analyse notamment la polygynie, les violences conjugales et les droits professionnels et reproductifs. Soutenue en 2017, elle constitue une ressource doctrinale et comparative : ses références au droit burkinabè antérieur au Code de 2025 doivent être recontextualisées avant toute application pratique.',
  array['Introduction — Réformes du droit de la famille et pluralisme juridique', 'Partie I — Faiblesse des droits de la femme dans le mariage', 'Formation, vie et dissolution du mariage', 'Partie II — Négation des droits de la femme dans le mariage', 'Polygynie, mutilations génitales féminines, violences et droits de santé', 'Conclusion générale'],
  true,
  'Aïssata Dabo — Universités de Bordeaux et d''Abomey-Calavi',
  null,
  array['égalité femmes-hommes', 'mariage', 'droit comparé', 'Bénin', 'Burkina Faso', 'Mali', 'doctrine'],
  array['doc-code-personnes-famille', 'doc-code-personnes-famille-1989'],
  now()
),
(
  'doc-these-pluralisme-justice-mossi',
  'Le pluralisme des systèmes juridiques et les perceptions de la justice',
  'doctrine',
  'famille',
  'Marie-Eve Paré — Thèse de doctorat en anthropologie, Université de Montréal, 22 décembre 2016',
  '2016-12-22',
  'enVigueur',
  'Ethnographie des conflits matrimoniaux chez les Mossi de Koudougou, centrée sur le pluralisme juridique, les stratégies de résolution et les perceptions de la justice.',
  'Cette recherche analyse les interactions entre référents coutumiers, religieux et étatiques dans les conflits matrimoniaux à Koudougou. Elle étudie la parenté, les formes de mariage, les sources de conflit et le « forum shopping » des justiciables. Il s''agit d''une étude anthropologique de terrain datée de 2016 : elle éclaire les pratiques et représentations sociales sans se substituer au droit positif actuellement en vigueur.',
  array['Introduction — Pluralisme juridique et perception de la justice', 'Approche théorique et méthodologie ethnographique', 'Parenté et organisation du mariage chez les Mossi', 'Conjugalité et sources des conflits matrimoniaux', 'Mariages forcés, polygynie, filiation et conflits successoraux', 'Résolution coutumière, action sociale, tribunal et forum shopping', 'Conclusion'],
  true,
  'Marie-Eve Paré — Université de Montréal',
  null,
  array['pluralisme juridique', 'Mossi', 'Koudougou', 'mariage', 'justice coutumière', 'anthropologie juridique', 'doctrine'],
  array['doc-code-personnes-famille', 'doc-code-personnes-famille-1989'],
  now()
)
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
  summary_only = excluded.summary_only,
  official_source_name = excluded.official_source_name,
  source_url = excluded.source_url,
  tags = excluded.tags,
  related_ids = excluded.related_ids,
  imported_at = excluded.imported_at;
