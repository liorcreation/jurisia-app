-- Références documentaires initiales — Droit des personnes et de la famille.
--
-- Ces fiches sont volontairement publiées comme résumés/repères : les PDF
-- transmis contiennent des sources doctrinales et un document institutionnel
-- dont les droits de diffusion et l'actualité normative doivent être vérifiés
-- avant de déposer le texte intégral dans le corpus public.

insert into public.legal_documents (
  id, title, type, domain, reference, date_publication, status, summary,
  full_content, outline, summary_only, official_source_name, tags,
  related_ids, imported_at
)
values
(
  'doc-onu-crc-sp-50',
  'Document ONU — Comité des droits de l''enfant (CRC/SP/50)',
  'rapport',
  'famille',
  'CRC/SP/50 — 5 juin 2018',
  '2018-06-05',
  'enVigueur',
  'Document institutionnel des Nations Unies relatif à l''élection de neuf membres du Comité des droits de l''enfant. Il ne constitue pas le texte intégral de la Convention.',
  'Cette référence présente la dix-septième réunion des États parties à la Convention relative aux droits de l''enfant et la procédure d''élection de neuf membres du Comité, conformément à l''article 43. Elle rassemble la note du Secrétaire général, la liste des personnes désignées et les notices biographiques communiquées par les États parties.',
  array['Réunion des États parties — New York, 29 juin 2018', 'Élection de neuf membres du Comité des droits de l''enfant', 'Personnes désignées par les États parties', 'Membres continuant leur mandat', 'Notices biographiques des personnes désignées'],
  true,
  'Nations Unies',
  array['droits de l''enfant', 'Convention relative aux droits de l''enfant', 'Comité des droits de l''enfant', 'Nations Unies'],
  array['doc-constitution'],
  now()
),
(
  'doc-doctrine-mariage-senegal',
  'L''organisation juridique du mariage au Sénégal',
  'doctrine',
  'famille',
  'Cheikh SENE — RAMReS, janvier 2020',
  '2020-01-01',
  'enVigueur',
  'Étude doctrinale consacrée à la formation et à l''organisation juridique du mariage au Sénégal, entre droit codifié, formes coutumières et liberté religieuse.',
  'L''article analyse les rapports préalables au mariage, les conditions de fond et de forme ainsi que les différentes formes d''union reconnues ou constatées par le droit sénégalais. Il met en perspective le mariage célébré, le mariage coutumier constaté et le mariage coutumier non constaté, puis examine leurs effets et les enjeux d''égalité entre les époux.',
  array['Introduction — Le Code de la famille sénégalais', 'Les rapports préalables à la conclusion du mariage : les fiançailles', 'Les conditions de fond et de forme', 'Le mariage célébré par l''officier d''état civil', 'Le mariage coutumier constaté', 'Le mariage coutumier non constaté', 'Les effets et la modernisation du mariage', 'Conclusion'],
  true,
  'RAMReS — Cheikh SENE',
  array['mariage', 'fiançailles', 'droit sénégalais', 'coutume', 'égalité des époux'],
  array['doc-code-personnes-famille'],
  now()
),
(
  'doc-doctrine-famille-burkina',
  'Droit de la famille burkinabé — Le code et ses pratiques à Ouagadougou',
  'doctrine',
  'famille',
  'Anne-Claude Cavin — L''Harmattan, 1998, ISBN 2-7384-7397-0',
  '1998-01-01',
  'enVigueur',
  'Étude doctrinale et anthropologique des pratiques familiales et judiciaires à Ouagadougou. L''ouvrage avertit explicitement qu''il ne tient pas compte des évolutions postérieures à son enquête (1993–1995).',
  'Cette recherche examine le droit métissé, le dualisme juridique et juridictionnel, les structures sociales fondamentales, le mariage traditionnel, la filiation, le veuvage, les filles-mères et les problèmes conjugaux à Ouagadougou. Elle doit être consultée comme une source historique et doctrinale, jamais comme une présentation à jour du droit positif burkinabè.',
  array['Partie I — Généralités : cadre historique, juridique et culturel', 'Le dualisme juridique et juridictionnel au Burkina Faso', 'Les structures sociales fondamentales : parenté, mariage, filiation', 'Partie II — Analyse des données de terrain', 'Le veuvage des femmes et la résolution des conflits', 'Les filles-mères et les litiges liés à la filiation', 'Les problèmes conjugaux', 'Partie III — Synthèse doctrinale et pratique'],
  true,
  'Éditions L''Harmattan — Anne-Claude Cavin',
  array['famille burkinabè', 'Ouagadougou', 'mariage traditionnel', 'filiation', 'veuvage', 'source historique'],
  array['doc-code-personnes-famille'],
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
  tags = excluded.tags,
  related_ids = excluded.related_ids,
  imported_at = excluded.imported_at;
