-- migration_027 — Pack original JurisIA : droit administratif.
--
-- Les supports transmis servent de base thématique. Cette migration publie
-- des cours JurisIA rédigés avec une formulation originale et ne reproduit
-- pas les ouvrages externes.

insert into public.legal_documents (
  id, title, type, domain, reference, date_publication, status, summary,
  full_content, outline, summary_only, official_source_name, source_url,
  tags, related_ids, imported_at
)
values
(
  'doc-jurisia-action-administrative',
  'Cours complet JurisIA — Action administrative', 'traite', 'administratif',
  'Édition pédagogique originale JurisIA — pack droit administratif', '2026-09-20', 'enVigueur',
  'Cours complet sur l’administration, le service public, la police administrative, les actes unilatéraux et la responsabilité administrative.',
  $action$
COURS COMPLET JURISIA — ACTION ADMINISTRATIVE

Le droit administratif encadre l’action des personnes publiques et des organismes chargés d’une mission administrative. Il recherche un équilibre entre l’intérêt général, la continuité des services et la protection des droits. Toute qualification doit partir du droit applicable au pays concerné, de l’auteur de l’acte, de sa finalité, de ses effets et du régime de contrôle.

PARTIE I — ADMINISTRATION ET LÉGALITÉ

L’administration agit au nom de l’intérêt général, mais elle n’est pas située en dehors du droit. Le principe de légalité impose le respect de la Constitution, des engagements internationaux, des lois, des règlements et des principes généraux reconnus par le système juridique. La compétence de l’auteur, la procédure suivie, le motif et le contenu de la décision doivent être contrôlés séparément.

L’organisation administrative distingue l’État, les collectivités territoriales, les établissements publics et les organismes auxquels une mission administrative est confiée. La déconcentration répartit les pouvoirs au sein d’une même personne publique; la décentralisation confie des affaires à une personne morale distincte. Une délégation doit avoir un fondement, un objet et une publicité conformes aux textes.

PARTIE II — SERVICE PUBLIC

Le service public est une activité orientée vers un besoin collectif et assumée ou contrôlée par une personne publique, selon la qualification retenue par le droit applicable. La continuité, l’égalité des usagers et l’adaptation du service sont des exigences classiques. Elles doivent être conciliées avec la neutralité, la liberté et les contraintes de ressources.

PARTIE III — POLICE ADMINISTRATIVE

La police administrative prévient les troubles à l’ordre public; la police judiciaire recherche les infractions et leurs auteurs. Une même opération peut changer de nature selon sa finalité réelle. Une mesure de police doit reposer sur une compétence, un risque suffisamment établi et une motivation adaptée. Elle doit être nécessaire et proportionnée.

PARTIE IV — ACTES ADMINISTRATIFS

L’acte unilatéral modifie l’ordonnancement juridique sans nécessiter l’accord de son destinataire. Il peut être réglementaire ou individuel, explicite ou implicite, créateur de droits ou non. L’entrée en vigueur, la publication, la notification, le retrait et l’abrogation produisent des effets différents. Le vice d’incompétence, le vice de procédure, l’erreur de droit et le détournement de pouvoir doivent être distingués.

PARTIE V — RESPONSABILITÉ ADMINISTRATIVE

La responsabilité peut résulter d’une faute de service, d’une faute personnelle, d’un risque ou d’une rupture d’égalité selon le régime applicable. Le demandeur doit établir un dommage certain, direct et personnel, un fait imputable à l’administration et un lien causal. Les causes d’exonération, la faute de la victime et le partage de responsabilité doivent être examinés.

MÉTHODE DE QUALIFICATION

Identifier la personne qui agit, le texte qui fonde sa compétence, la finalité de l’action, la nature de l’acte, les droits affectés, l’urgence et le recours possible. Séparer légalité externe, légalité interne et responsabilité. Vérifier la version des textes et la jurisprudence du ressort avant toute conclusion.
  $action$,
  array['Administration et légalité', 'Organisation administrative', 'Service public', 'Police administrative', 'Actes administratifs', 'Responsabilité', 'Méthode de qualification'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-droit-administratif', 'droit administratif', 'action administrative', 'service public', 'police administrative'], array[]::text[], now()
),
(
  'doc-jurisia-contrats-administratifs',
  'Cours complet JurisIA — Contrats administratifs', 'traite', 'administratif',
  'Édition pédagogique originale JurisIA — pack droit administratif', '2026-09-20', 'enVigueur',
  'Cours complet sur la qualification, la conclusion, l’exécution, les pouvoirs de l’administration et le contentieux des contrats administratifs.',
  $contracts$
COURS COMPLET JURISIA — CONTRATS ADMINISTRATIFS

Le contrat administratif est un instrument de réalisation de l’action publique. Il organise une prestation, un ouvrage, une occupation ou la gestion d’une activité tout en tenant compte de l’intérêt général. La qualification détermine les règles de formation, les pouvoirs de l’administration, le juge compétent et les voies de recours.

PARTIE I — QUALIFICATION

La présence d’une personne publique peut constituer un indice important, mais elle ne suffit pas toujours. Il faut rechercher l’objet du contrat, la participation à un service public, l’existence de clauses ou de prérogatives exorbitantes et le régime spécial prévu par les textes. Un contrat conclu entre personnes privées peut relever du droit administratif lorsque la loi ou la jurisprudence le prévoit.

Les marchés publics répondent à un besoin de travaux, de fournitures ou de services contre un prix ou une rémunération déterminée. Les conventions de délégation transfèrent davantage de risques et peuvent lier la rémunération aux résultats de l’exploitation. La qualification doit être faite à partir de l’économie réelle de l’opération.

PARTIE II — FORMATION ET TRANSPARENCE

La préparation comprend la définition du besoin, l’estimation, le choix de la procédure, la publicité, la mise en concurrence et la vérification des candidatures. Les principes d’égalité, de transparence, d’impartialité et de bonne utilisation des deniers publics protègent les concurrents et l’intérêt collectif.

L’offre, l’attribution, l’approbation et la signature doivent respecter les compétences et contrôles prévus. Les pièces contractuelles doivent fixer les prestations, les délais, les prix, les pénalités, les garanties, la réception, la sous-traitance et les conditions de règlement.

PARTIE III — EXÉCUTION ET ÉQUILIBRE FINANCIER

L’administration dispose de pouvoirs de direction, de contrôle et de sanction justifiés par l’intérêt général. Elle peut parfois imposer une modification unilatérale, mais elle doit respecter les limites du contrat et l’équilibre financier du cocontractant. Une modification qui bouleverse l’économie de l’opération peut exiger un nouveau contrat.

Le cocontractant a droit au paiement des prestations et, dans les conditions prévues, à une compensation des charges imposées. La force majeure, les sujétions imprévues et les difficultés exceptionnelles ne produisent pas les mêmes effets. Il faut établir l’événement, son impact et le lien avec le surcoût.

PARTIE IV — SANCTIONS ET FIN

Le retard, la mauvaise exécution ou l’abandon peuvent justifier une pénalité, une mise en demeure, une exécution aux frais et risques ou une résiliation. La sanction doit être prévue ou autorisée, proportionnée et précédée des garanties nécessaires. La résiliation pour motif d’intérêt général peut ouvrir un droit à indemnité distinct de la résiliation pour faute.

PARTIE V — RECOURS

Le candidat évincé peut contester la procédure selon le recours ouvert. Le cocontractant peut demander le paiement, l’indemnisation, la reprise des relations ou la résiliation. L’administration peut demander l’exécution, la réparation ou la fin du contrat. Le recours doit préciser le contrat, la clause, le manquement, le préjudice et la mesure demandée.

MÉTHODE D’AUDIT

Reconstituer la chronologie de la passation et de l’exécution. Vérifier l’habilitation, la publicité, les offres, les pièces, les ordres de service, les paiements et les réserves. Distinguer risque de qualification, irrégularité de passation, difficulté d’exécution et litige financier.
  $contracts$,
  array['Qualification', 'Formation et transparence', 'Exécution', 'Équilibre financier', 'Sanctions et fin', 'Recours', 'Méthode d’audit'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-droit-administratif', 'contrats administratifs', 'marchés publics', 'service public', 'commande publique'], array[]::text[], now()
),
(
  'doc-jurisia-contentieux-administratif',
  'Cours complet JurisIA — Contentieux administratif et jurisprudence', 'traite', 'administratif',
  'Édition pédagogique originale JurisIA — pack droit administratif', '2026-09-20', 'enVigueur',
  'Cours complet sur le juge administratif, les recours, la recevabilité, le contrôle de légalité, les référés et l’analyse de jurisprudence.',
  $litigation$
COURS COMPLET JURISIA — CONTENTIEUX ADMINISTRATIF ET JURISPRUDENCE

Le contentieux administratif permet de contrôler l’action administrative et de réparer les atteintes causées par elle. Le recours se choisit selon l’acte, la qualité du demandeur, la mesure recherchée et l’office du juge. La jurisprudence est étudiée comme un raisonnement : faits pertinents, procédure, question, règle, application et portée.

PARTIE I — JUGE ET ACTES ATTAQUABLES

La compétence du juge administratif dépend de l’organisation juridictionnelle et de la nature du litige. Il faut identifier l’auteur, la mission, le régime de l’acte et l’existence d’un texte attribuant le contentieux à une autre juridiction. Un acte faisant grief modifie la situation juridique ou produit des effets suffisamment directs.

L’intérêt pour agir doit être personnel, direct et actuel selon le recours. Une association, une entreprise, un agent ou une collectivité ne justifie pas son intérêt de la même manière. La qualité, la représentation, la décision préalable et le respect du délai sont contrôlés avant l’examen des moyens.

PARTIE II — RECOURS

Le recours pour excès de pouvoir vise l’annulation d’un acte illégal. Le plein contentieux permet, selon les matières, de demander une indemnité, une réformation, une substitution, une résiliation ou une mesure d’exécution. Le recours contractuel suit le régime du contrat et les pouvoirs reconnus au juge.

La requête doit identifier la décision, les parties, les faits, les moyens et les conclusions. Le demandeur doit joindre la décision attaquée ou expliquer son absence, produire les pièces utiles et respecter la forme de saisine.

PARTIE III — LÉGALITÉ EXTERNE ET INTERNE

La légalité externe porte sur la compétence, la procédure, la forme et la motivation lorsque celle-ci est exigée. La légalité interne porte sur le sens de la décision, le fondement juridique, les faits, la qualification et le but poursuivi. Une décision peut être annulée pour erreur de droit, erreur de fait, erreur de qualification, détournement de pouvoir ou disproportion lorsque le contrôle applicable le permet.

Le juge adapte l’intensité de son contrôle à la nature de la décision. Il peut vérifier strictement les faits et la qualification, contrôler une erreur manifeste ou respecter une marge d’appréciation. Le moyen doit expliquer la règle, le fait prouvé et le raisonnement qui conduit à l’illégalité.

PARTIE IV — PROCÉDURE ET RÉFÉRÉS

Le procès administratif est écrit et contradictoire, sous réserve des règles propres à l’audience. La communication des mémoires permet à chaque partie de répondre. Le juge peut demander une régularisation, une production ou une précision. L’irrecevabilité, le non-lieu et le rejet au fond ne produisent pas les mêmes effets.

Le référé-suspension exige une urgence et un moyen propre à créer un doute sérieux sur la légalité lorsque le texte le prévoit. Le référé-liberté ou la mesure de sauvegarde d’une liberté répond à des conditions spécifiques et à un office plus rapide.

PARTIE V — RESPONSABILITÉ ET EXÉCUTION

La demande indemnitaire doit établir le fait générateur, le dommage, le lien causal et le montant réclamé. La faute, le risque, la rupture d’égalité et les régimes spéciaux sont distingués. Après la décision, vérifier son caractère exécutoire, la notification, les injonctions, l’astreinte et la possibilité d’une exécution spontanée ou forcée.

MÉTHODE DE COMMENTAIRE D’ARRÊT

Présenter les faits utiles, retracer la procédure, formuler la question de droit, exposer la solution et expliquer sa portée. Distinguer la règle posée, l’application au cas et les réserves. Pour un cas pratique, identifier l’acte, la recevabilité, le recours, les moyens et la mesure recherchée avant de conclure sur les chances et les risques.
  $litigation$,
  array['Juge administratif', 'Actes attaquables', 'Recours', 'Légalité externe et interne', 'Référés', 'Responsabilité', 'Commentaire d’arrêt'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-droit-administratif', 'contentieux administratif', 'jurisprudence administrative', 'recours', 'légalité'], array[]::text[], now()
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
