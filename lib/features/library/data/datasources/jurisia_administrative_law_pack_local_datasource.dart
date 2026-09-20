import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';

/// Cours originaux JurisIA construits à partir des thèmes des supports
/// transmis sur l'action administrative, les contrats et le contentieux.
///
/// Les ouvrages et documents servent à cadrer les thèmes. Les textes
/// ci-dessous sont rédigés pour JurisIA et ne reproduisent pas les sources
/// transmises. Les compétences, délais et références jurisprudentielles
/// doivent être vérifiés dans le droit positif applicable.
final jurisiaAdministrativeLawPackLocalDocuments = <LegalDocument>[
  LegalDocument(
    id: 'doc-jurisia-action-administrative',
    title: 'Cours complet JurisIA — Action administrative',
    type: LegalDocumentType.traite,
    domain: LegalDomain.administratif,
    reference: 'Édition pédagogique originale JurisIA — pack droit administratif',
    datePublication: DateTime(2026, 9, 20),
    summary:
        'Cours complet sur l’administration, le service public, la police administrative, les actes unilatéraux et la responsabilité administrative.',
    fullContent: _administrativeActionCourse,
    outline: const [
      'État, administration et principe de légalité',
      'Organisation administrative et personnes publiques',
      'Service public et activités administratives',
      'Police administrative et libertés',
      'Actes administratifs unilatéraux',
      'Responsabilité et réparation administrative',
      'Contrôle de l’administration',
      'Méthode de qualification administrative',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-droit-administratif',
      'droit administratif',
      'action administrative',
      'service public',
      'police administrative',
    ],
  ),
  LegalDocument(
    id: 'doc-jurisia-contrats-administratifs',
    title: 'Cours complet JurisIA — Contrats administratifs',
    type: LegalDocumentType.traite,
    domain: LegalDomain.administratif,
    reference: 'Édition pédagogique originale JurisIA — pack droit administratif',
    datePublication: DateTime(2026, 9, 20),
    summary:
        'Cours complet sur la qualification, la conclusion, l’exécution, les pouvoirs de l’administration et le contentieux des contrats administratifs.',
    fullContent: _administrativeContractsCourse,
    outline: const [
      'Qualification et catégories de contrats administratifs',
      'Formation, publicité et choix du cocontractant',
      'Clauses, équilibre financier et risques',
      'Pouvoirs de direction et de modification',
      'Rémunération, sujétions imprévues et force majeure',
      'Sanctions, résiliation et fin du contrat',
      'Responsabilité des parties',
      'Recours et règlement des différends',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-droit-administratif',
      'contrats administratifs',
      'marchés publics',
      'service public',
      'commande publique',
    ],
  ),
  LegalDocument(
    id: 'doc-jurisia-contentieux-administratif',
    title: 'Cours complet JurisIA — Contentieux administratif et jurisprudence',
    type: LegalDocumentType.traite,
    domain: LegalDomain.administratif,
    reference: 'Édition pédagogique originale JurisIA — pack droit administratif',
    datePublication: DateTime(2026, 9, 20),
    summary:
        'Cours complet sur le juge administratif, les recours, la recevabilité, le contrôle de légalité, les référés et l’analyse de jurisprudence.',
    fullContent: _administrativeLitigationCourse,
    outline: const [
      'Juridictions et principes du procès administratif',
      'Actes attaquables et intérêt pour agir',
      'Recours pour excès de pouvoir et plein contentieux',
      'Recevabilité, délais et procédure contradictoire',
      'Moyens de légalité externe et interne',
      'Référés et mesures provisoires',
      'Responsabilité, indemnisation et exécution',
      'Méthode de commentaire d’arrêt administratif',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-droit-administratif',
      'contentieux administratif',
      'jurisprudence administrative',
      'recours',
      'légalité',
    ],
  ),
];

const _administrativeActionCourse = r'''
COURS COMPLET JURISIA — ACTION ADMINISTRATIVE

ORIENTATION

Le droit administratif encadre l’action des personnes publiques et des
organismes chargés d’une mission administrative. Il recherche un équilibre
entre l’intérêt général, la continuité des services et la protection des
droits. Toute qualification doit partir du droit applicable au pays concerné,
de l’auteur de l’acte, de sa finalité, de ses effets et du régime de contrôle.

PARTIE I — ADMINISTRATION ET LÉGALITÉ

L’administration agit au nom de l’intérêt général, mais elle n’est pas située
en dehors du droit. Le principe de légalité impose le respect de la
Constitution, des engagements internationaux, des lois, des règlements et des
principes généraux reconnus par le système juridique. La compétence de
l’auteur, la procédure suivie, le motif et le contenu de la décision doivent
être contrôlés séparément.

L’organisation administrative distingue l’État, les collectivités
territoriales, les établissements publics et les organismes auxquels une
mission administrative est confiée. La déconcentration répartit les pouvoirs
au sein d’une même personne publique; la décentralisation confie des affaires
à une personne morale distincte. Une délégation doit avoir un fondement, un
objet et une publicité conformes aux textes.

PARTIE II — SERVICE PUBLIC

Le service public est une activité orientée vers un besoin collectif et
assumée ou contrôlée par une personne publique, selon la qualification retenue
par le droit applicable. La continuité, l’égalité des usagers et l’adaptation
du service sont des exigences classiques. Elles doivent être conciliées avec
la neutralité, la liberté et les contraintes de ressources.

La gestion peut être directe ou confiée à un opérateur. Le contrat, la mission
confiée, le financement, le contrôle et les prérogatives conservées par la
personne publique permettent de distinguer une délégation de service public,
un marché ou une simple convention. La qualification ne dépend pas seulement
du titre donné par les parties.

PARTIE III — POLICE ADMINISTRATIVE

La police administrative prévient les troubles à l’ordre public; la police
judiciaire recherche les infractions et leurs auteurs. Une même opération peut
changer de nature selon sa finalité réelle. L’ordre public comprend notamment
la sécurité, la tranquillité et la salubrité publiques, avec les composantes
que les textes et la jurisprudence reconnaissent.

Une mesure de police doit reposer sur une compétence, un risque suffisamment
établi et une motivation adaptée. Elle doit être nécessaire et proportionnée.
Une interdiction générale et absolue appelle une justification renforcée.
L’autorité doit examiner des mesures moins attentatoires aux libertés avant de
retenir la restriction la plus forte.

PARTIE IV — ACTES ADMINISTRATIFS

L’acte unilatéral modifie l’ordonnancement juridique sans nécessiter l’accord
de son destinataire. Il peut être réglementaire ou individuel, explicite ou
implicite, créateur de droits ou non. L’entrée en vigueur, la publication, la
notification, le retrait et l’abrogation produisent des effets différents.

Le vice d’incompétence concerne l’auteur; le vice de forme ou de procédure
concerne la préparation de l’acte; le détournement de pouvoir concerne la
finalité; l’erreur de droit, l’erreur de fait et l’erreur manifeste concernent
le motif ou l’appréciation. Il faut rattacher chaque critique à la décision
attaquée et à la règle pertinente.

PARTIE V — RESPONSABILITÉ ADMINISTRATIVE

La responsabilité peut résulter d’une faute de service, d’une faute
personnelle, d’un risque ou d’une rupture d’égalité selon le régime applicable.
Le demandeur doit établir un dommage certain, direct et personnel, un fait
imputable à l’administration et un lien causal. Les causes d’exonération, la
faute de la victime et le partage de responsabilité doivent être examinés.

MÉTHODE DE QUALIFICATION

Identifier la personne qui agit, le texte qui fonde sa compétence, la finalité
de l’action, la nature de l’acte, les droits affectés, l’urgence et le recours
possible. Séparer légalité externe, légalité interne et responsabilité. Vérifier
la version des textes et la jurisprudence du ressort avant toute conclusion.
''';

const _administrativeContractsCourse = r'''
COURS COMPLET JURISIA — CONTRATS ADMINISTRATIFS

INTRODUCTION

Le contrat administratif est un instrument de réalisation de l’action
publique. Il organise une prestation, un ouvrage, une occupation ou la gestion
d’une activité tout en tenant compte de l’intérêt général. La qualification
détermine les règles de formation, les pouvoirs de l’administration, le juge
compétent et les voies de recours.

PARTIE I — QUALIFICATION

La présence d’une personne publique peut constituer un indice important, mais
elle ne suffit pas toujours. Il faut rechercher l’objet du contrat, la
participation à un service public, l’existence de clauses ou de prérogatives
exorbitantes et le régime spécial prévu par les textes. Un contrat conclu
entre personnes privées peut relever du droit administratif lorsque la loi ou
la jurisprudence le prévoit; inversement, une personne publique peut conclure
un contrat de droit privé.

Les marchés publics répondent à un besoin de travaux, de fournitures ou de
services contre un prix ou une rémunération déterminée. Les conventions de
délégation transfèrent davantage de risques et peuvent lier la rémunération
aux résultats de l’exploitation. La qualification doit être faite à partir de
l’économie réelle de l’opération.

PARTIE II — FORMATION ET TRANSPARENCE

La préparation comprend la définition du besoin, l’estimation, le choix de la
procédure, la publicité, la mise en concurrence et la vérification des
candidatures. Les principes d’égalité, de transparence, d’impartialité et de
bonne utilisation des deniers publics protègent les concurrents et l’intérêt
collectif.

L’offre, l’attribution, l’approbation et la signature doivent respecter les
compétences et contrôles prévus. L’autorité ne peut engager la personne
publique sans habilitation. Les pièces contractuelles doivent fixer les
prestations, les délais, les prix, les pénalités, les garanties, la réception,
la sous-traitance et les conditions de règlement.

PARTIE III — EXÉCUTION ET ÉQUILIBRE FINANCIER

L’administration dispose de pouvoirs de direction, de contrôle et de sanction
justifiés par l’intérêt général. Elle peut parfois imposer une modification
unilatérale, mais elle doit respecter les limites du contrat, la procédure et
l’équilibre financier du cocontractant. Une modification qui transforme
l’objet ou bouleverse l’économie de l’opération peut exiger un nouveau contrat.

Le cocontractant a droit au paiement des prestations et, dans les conditions
prévues, à une compensation des charges imposées. La force majeure, les
sujétions imprévues et les difficultés exceptionnelles ne produisent pas les
mêmes effets. Il faut établir l’événement, son imprévisibilité, son impact,
les mesures prises pour limiter les pertes et le lien avec le surcoût.

PARTIE IV — SANCTIONS ET FIN DU CONTRAT

Le retard, la mauvaise exécution ou l’abandon peuvent justifier une pénalité,
une mise en demeure, une exécution aux frais et risques ou une résiliation.
La sanction doit être prévue ou autorisée, proportionnée et précédée des
garanties nécessaires. La résiliation pour motif d’intérêt général peut ouvrir
un droit à indemnité distinct de la résiliation pour faute.

À la fin du contrat, organiser la réception, la levée des réserves, la remise
des biens, la clôture financière, les garanties et l’archivage. Les différends
sur le décompte, les travaux supplémentaires ou les pénalités doivent être
présentés dans les formes et délais contractuels.

PARTIE V — RECOURS

Le candidat évincé peut contester la procédure selon le recours ouvert par le
droit applicable. Le cocontractant peut demander le paiement, l’indemnisation,
la reprise des relations ou la résiliation. L’administration peut demander
l’exécution, la réparation ou la fin du contrat. Le recours doit préciser le
contrat, la clause, le manquement, le préjudice et la mesure demandée.

MÉTHODE D’AUDIT

Reconstituer la chronologie de la passation et de l’exécution. Vérifier
l’habilitation, la publicité, les offres, les pièces, les ordres de service,
les paiements et les réserves. Distinguer risque de qualification, irrégularité
de passation, difficulté d’exécution et litige financier. Chiffrer séparément
les prestations, les surcoûts, les pénalités et le préjudice prouvé.
''';

const _administrativeLitigationCourse = r'''
COURS COMPLET JURISIA — CONTENTIEUX ADMINISTRATIF ET JURISPRUDENCE

ORIENTATION

Le contentieux administratif permet de contrôler l’action administrative et
de réparer les atteintes causées par elle. Le recours se choisit selon l’acte,
la qualité du demandeur, la mesure recherchée et l’office du juge. La
jurisprudence est étudiée comme un raisonnement : faits pertinents, procédure,
question, règle, application et portée, sans réduire la décision à une phrase
isolée.

PARTIE I — JUGE ET ACTES ATTAQUABLES

La compétence du juge administratif dépend de l’organisation juridictionnelle
et de la nature du litige. Il faut identifier l’auteur, la mission, le régime
de l’acte et l’existence d’un texte attribuant le contentieux à une autre
juridiction. Un acte faisant grief modifie la situation juridique ou produit
des effets suffisamment directs. Les mesures préparatoires, informations et
actes internes peuvent obéir à un régime différent.

L’intérêt pour agir doit être personnel, direct et actuel selon le recours.
Une association, une entreprise, un agent ou une collectivité ne justifie pas
son intérêt de la même manière. La qualité, la représentation, la décision
préalable et le respect du délai sont contrôlés avant l’examen des moyens.

PARTIE II — RECOURS

Le recours pour excès de pouvoir vise l’annulation d’un acte illégal. Le plein
contentieux permet, selon les matières, de demander une indemnité, une
réformation, une substitution, une résiliation ou une mesure d’exécution. Le
recours contractuel suit le régime du contrat et les pouvoirs reconnus au
juge.

La requête doit identifier la décision, les parties, les faits, les moyens et
les conclusions. Le demandeur doit joindre la décision attaquée ou expliquer
son absence, produire les pièces utiles et respecter la forme de saisine. Une
demande confuse ou dépourvue de conclusions précises fragilise le débat.

PARTIE III — LÉGALITÉ EXTERNE ET INTERNE

La légalité externe porte sur la compétence, la procédure, la forme et la
motivation lorsque celle-ci est exigée. La légalité interne porte sur le sens
de la décision, le fondement juridique, les faits, la qualification et le but
poursuivi. Une décision peut être annulée pour erreur de droit, erreur de fait,
erreur de qualification, détournement de pouvoir ou disproportion lorsque le
contrôle applicable le permet.

Le juge adapte l’intensité de son contrôle à la nature de la décision. Il peut
vérifier strictement les faits et la qualification, contrôler une erreur
manifeste ou respecter une marge d’appréciation. Le moyen doit expliquer la
règle, le fait prouvé et le raisonnement qui conduit à l’illégalité.

PARTIE IV — PROCÉDURE ET RÉFÉRÉS

Le procès administratif est écrit et contradictoire, sous réserve des règles
propres à l’audience. La communication des mémoires permet à chaque partie de
répondre. Le juge peut demander une régularisation, une production ou une
précision. Le désistement, le non-lieu, l’irrecevabilité et le rejet au fond
ne produisent pas les mêmes effets.

Le référé-suspension exige une urgence et un moyen propre à créer un doute
sérieux sur la légalité, lorsque le texte le prévoit. Le référé-liberté ou la
mesure de sauvegarde d’une liberté répond à des conditions spécifiques et à un
office plus rapide. Une mesure provisoire ne préjuge pas nécessairement du
jugement au fond.

PARTIE V — RESPONSABILITÉ ET EXÉCUTION

La demande indemnitaire doit établir le fait générateur, le dommage, le lien
causal et le montant réclamé. La faute, le risque, la rupture d’égalité et les
régimes spéciaux sont distingués. La victime doit limiter raisonnablement son
préjudice et produire les justificatifs de perte, de dépenses, de troubles ou
de préjudices personnels.

Après la décision, vérifier son caractère exécutoire, la notification, les
injonctions, l’astreinte et la possibilité d’une exécution spontanée ou forcée.
Une administration ne peut ignorer une décision définitive; le justiciable
doit toutefois utiliser la procédure prévue pour obtenir l’exécution.

MÉTHODE DE COMMENTAIRE D’ARRÊT

Présenter les faits utiles sans les déformer, retracer la procédure, formuler
la question de droit, exposer la solution et expliquer sa portée. Distinguer
la règle posée, l’application au cas et les réserves. Pour un cas pratique,
identifier l’acte, la recevabilité, le recours, les moyens et la mesure
recherchée avant de conclure sur les chances et les risques.
''';
