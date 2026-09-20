import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';

/// Cours originaux JurisIA construits à partir des thèmes des supports
/// transmis sur le droit bancaire UMOA et le droit des assurances CIMA.
///
/// Les supports servent à cadrer les thèmes. Les textes ci-dessous sont
/// rédigés pour JurisIA et ne reproduisent pas les ouvrages transmis. Les
/// agréments, délais, seuils et sanctions doivent être vérifiés dans les
/// textes en vigueur au moment du dossier.
final jurisiaBankingInsurancePackLocalDocuments = <LegalDocument>[
  LegalDocument(
    id: 'doc-jurisia-droit-bancaire-general',
    title: 'Cours complet JurisIA — Droit bancaire',
    type: LegalDocumentType.traite,
    domain: LegalDomain.commercial,
    reference: 'Édition pédagogique originale JurisIA — pack bancaire et assurances',
    datePublication: DateTime(2026, 9, 20),
    summary:
        'Cours complet sur les acteurs bancaires, les opérations de crédit et de paiement, la relation client, la conformité et la responsabilité.',
    fullContent: _bankingLawCourse,
    outline: const [
      'Système bancaire et acteurs du secteur',
      'Agrément, contrôle et gouvernance',
      'Compte, dépôt et instruments de paiement',
      'Crédit, garanties et sûretés',
      'Obligations du banquier et du client',
      'Secret bancaire, conformité et lutte contre la fraude',
      'Responsabilité, incidents et règlement des différends',
      'Méthode d’analyse d’une opération bancaire',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-droit-bancaire-assurances',
      'droit bancaire',
      'crédit',
      'paiement',
      'conformité bancaire',
    ],
  ),
  LegalDocument(
    id: 'doc-jurisia-droit-bancaire-umoa',
    title: 'Cours complet JurisIA — Réglementation bancaire UMOA',
    type: LegalDocumentType.traite,
    domain: LegalDomain.ohada,
    reference: 'Édition pédagogique originale JurisIA — pack bancaire et assurances',
    datePublication: DateTime(2026, 9, 20),
    summary:
        'Cours complet sur le cadre uniforme UMOA, les établissements de crédit, la supervision, la protection des déposants et les sanctions.',
    fullContent: _umoaBankingLawCourse,
    outline: const [
      'Architecture institutionnelle de l’Union',
      'Établissements de crédit et activités réglementées',
      'Agrément, capital et gouvernance',
      'Supervision prudentielle et contrôle',
      'Opérations, moyens de paiement et clientèle',
      'Prévention des risques et obligations déclaratives',
      'Mesures correctives, sanctions et résolution',
      'Cas pratique de qualification UMOA',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-droit-bancaire-assurances',
      'droit bancaire UMOA',
      'BCEAO',
      'établissement de crédit',
      'supervision prudentielle',
    ],
  ),
  LegalDocument(
    id: 'doc-jurisia-droit-assurances-cima',
    title: 'Cours complet JurisIA — Droit des assurances et Code CIMA',
    type: LegalDocumentType.traite,
    domain: LegalDomain.commercial,
    reference: 'Édition pédagogique originale JurisIA — pack bancaire et assurances',
    datePublication: DateTime(2026, 9, 20),
    summary:
        'Cours complet sur le contrat d’assurance, les obligations des parties, les sinistres, l’indemnisation, l’assurance obligatoire et le cadre CIMA.',
    fullContent: _insuranceLawCourse,
    outline: const [
      'Fonction économique et cadre institutionnel CIMA',
      'Formation et classification du contrat',
      'Déclarations, primes et obligations de l’assuré',
      'Garanties, exclusions et aggravation du risque',
      'Sinistre, expertise et règlement',
      'Assurance de responsabilité et circulation',
      'Intermédiaires, contrôle et solvabilité',
      'Recours, prescription et méthode de dossier',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-droit-bancaire-assurances',
      'droit des assurances',
      'Code CIMA',
      'sinistre',
      'indemnisation',
    ],
  ),
];

const _bankingLawCourse = r'''
COURS COMPLET JURISIA — DROIT BANCAIRE

ORIENTATION

Le droit bancaire organise la collecte de l’épargne, la mise à disposition du
crédit, les paiements et la circulation de la monnaie scripturale. Il protège
la stabilité du système tout en encadrant la relation entre l’établissement,
le client, les garants et les tiers. Toute consultation doit distinguer la
règle générale, la réglementation professionnelle et les conditions prévues
par le contrat.

PARTIE I — ACTEURS ET ACTIVITÉS

Les banques, établissements financiers, institutions de microfinance,
prestataires de paiement et autres intervenants ne disposent pas des mêmes
prérogatives. La collecte de dépôts remboursables, l’octroi habituel de
crédits, la mise à disposition de moyens de paiement et les services de
transmission de fonds peuvent être soumis à agrément ou à autorisation.

L’agrément est attaché à une personne et à un programme d’activités. Il ne
dispense pas de respecter les règles de gouvernance, de contrôle interne, de
gestion des risques, de protection de la clientèle et de lutte contre le
blanchiment. Une activité exercée sans titre expose son auteur et peut priver
les opérations de certains effets juridiques.

PARTIE II — COMPTE ET DÉPÔT

L’ouverture d’un compte implique l’identification du client, la vérification
de ses pouvoirs et la définition des conditions de fonctionnement. Le contrat
doit préciser les frais, les moyens d’accès, les opérations autorisées, les
modalités de clôture et la procédure de contestation. Un compte professionnel,
un compte de paiement et un compte d’épargne n’emportent pas les mêmes droits.

Le dépôt crée une obligation de restitution selon la nature de l’opération.
Les relevés et écritures bancaires constituent des éléments de preuve, mais
leur portée doit être appréciée avec les contestations, les délais et les
documents contractuels. La banque doit exécuter les ordres reçus avec les
contrôles nécessaires et signaler les anomalies manifestes.

PARTIE III — CRÉDIT ET GARANTIES

Une opération de crédit se décrit par le montant, la durée, le taux, le coût
global, l’échéancier, les conditions de déblocage et les événements de défaut.
Le prêteur analyse la capacité de remboursement sans transformer cette analyse
en garantie absolue de la réussite du projet. L’emprunteur doit fournir des
informations exactes et affecter les fonds conformément au contrat.

Le cautionnement, la garantie autonome, le gage, le nantissement, l’hypothèque
et la garantie réelle n’ont pas le même régime. Identifier l’obligation
garantie, le plafond, la durée, les formalités, le rang, les conditions d’appel
et les recours du garant. Une sûreté mal constituée peut être inopposable ou
réduire le recouvrement.

PARTIE IV — PAIEMENTS ET INCIDENTS

Le virement, le prélèvement, la carte, le chèque et la monnaie électronique
obéissent à des règles distinctes. Contrôler l’autorisation, l’identité du
donneur d’ordre, l’irrévocabilité éventuelle, les délais de contestation et la
répartition des pertes en cas de fraude. L’établissement doit réagir à un
ordre irrégulier, mais le client doit protéger ses instruments et signaler
rapidement une opération contestée.

PARTIE V — SECRET ET CONFORMITÉ

Le secret professionnel protège les informations obtenues dans l’activité
financière. Il connaît des exceptions légales, notamment pour l’autorité
judiciaire, la supervision et les dispositifs de lutte contre le blanchiment
et le financement du terrorisme. La conformité comprend la connaissance du
client, la surveillance des opérations, la conservation des pièces et la
déclaration prévue lorsque les conditions sont réunies.

PARTIE VI — RESPONSABILITÉ

La responsabilité de la banque peut être recherchée pour défaut d’exécution,
faute dans un paiement, rupture fautive de crédit, manquement d’information,
atteinte au secret ou concours irrégulier. Le client doit établir le devoir,
le manquement, le dommage et le lien causal. La banque peut opposer le contrat,
la faute du client, la prescription ou une cause étrangère selon le droit
applicable.

MÉTHODE D’ANALYSE

Qualifier l’acteur, le service, le contrat, les fonds, le risque et la date.
Reconstituer les autorisations et les opérations, identifier les documents
probatoires, vérifier les délais et distinguer responsabilité contractuelle,
professionnelle et réglementaire. Contrôler systématiquement le texte bancaire
et les instructions du régulateur applicables au dossier.
''';

const _umoaBankingLawCourse = r'''
COURS COMPLET JURISIA — RÉGLEMENTATION BANCAIRE UMOA

ARCHITECTURE DE L’UNION

La réglementation bancaire UMOA s’insère dans une architecture régionale qui
organise la monnaie, la supervision et les conditions d’exercice des activités
bancaires dans les États membres. Il faut distinguer le rôle de la banque
centrale, de la commission de supervision, des autorités nationales et des
organes de décision. Une règle uniforme peut nécessiter une mise en œuvre
nationale avant de produire certains effets.

PARTIE I — ÉTABLISSEMENTS ET AGRÉMENT

Un établissement doit définir son activité, son capital, sa forme, ses
dirigeants, ses actionnaires significatifs et son dispositif de contrôle. La
demande d’agrément doit permettre de vérifier la solidité financière,
l’honorabilité et la compétence des responsables. L’agrément ne couvre pas
automatiquement toute activité financière : les services de paiement,
microfinance, monnaie électronique et opérations de change peuvent relever de
règles complémentaires.

L’exercice sans agrément, l’utilisation indue d’une qualité bancaire et le
non-respect des restrictions d’activité peuvent entraîner des mesures
administratives, des sanctions disciplinaires et des poursuites. Il faut
identifier l’auteur, l’activité réellement exercée, la répétition, la clientèle
visée et l’éventuelle exemption.

PARTIE II — GOUVERNANCE ET PRUDENCE

La gouvernance répartit les responsabilités entre organes sociaux, direction
effective, contrôle permanent, audit et gestion des risques. Les exigences de
solvabilité, de liquidité, de concentration des risques et de classement des
créances protègent les déposants et la stabilité du système.

Les procédures internes doivent prévenir les conflits d’intérêts, les abus de
biens, les opérations avec des personnes liées et la prise de risque excessive.
Les documents comptables et prudentiels doivent être fiables, conservés et
transmis aux autorités selon les modalités prévues.

PARTIE III — RELATION AVEC LA CLIENTÈLE

L’établissement informe le client sur le service, le coût, les risques et les
conditions de sortie. L’identification et la connaissance du client doivent
être adaptées au risque. La protection ne signifie pas que tout client est
garanti contre les pertes : elle impose une information loyale, l’exécution
correcte et le traitement des réclamations.

Les moyens de paiement exigent des contrôles d’accès, une traçabilité et une
répartition claire des responsabilités. En cas d’opération suspecte, il faut
conserver les traces, suspendre ou examiner l’opération lorsque le droit le
permet, et respecter le secret ainsi que les obligations de déclaration.

PARTIE IV — SUPERVISION ET MESURES CORRECTIVES

La supervision peut comprendre les contrôles sur pièces, sur place, demandes
d’information, injonctions et mesures de redressement. L’établissement doit
coopérer, répondre exactement et corriger les insuffisances. Le superviseur
peut imposer un plan, limiter une activité, remplacer un dirigeant ou prendre
une mesure conservatoire dans les conditions prévues.

La procédure de sanction doit identifier le manquement, respecter les droits
de la défense, individualiser la mesure et permettre le recours prévu. Une
sanction pécuniaire, une interdiction, un retrait d’agrément et une mesure de
résolution n’ont pas la même finalité.

PARTIE V — CRISE ET PROTECTION

La défaillance d’un établissement affecte les déposants, les emprunteurs et
les autres établissements. La prévention repose sur les fonds propres, la
liquidité, les plans de continuité et la surveillance. En cas de crise, les
autorités organisent la protection des fonctions essentielles, le traitement
des actifs et passifs et, si le droit le prévoit, l’indemnisation des déposants.

CAS PRATIQUE

Qualifier l’établissement, vérifier l’agrément et l’activité, relever les
obligations de gouvernance et de conformité, identifier le manquement,
contrôler l’autorité compétente, puis distinguer mesure corrective, sanction
et recours. Toujours vérifier la version la plus récente de la loi uniforme,
des textes d’application et des instructions régionales.
''';

const _insuranceLawCourse = r'''
COURS COMPLET JURISIA — DROIT DES ASSURANCES ET CODE CIMA

FONCTION DE L’ASSURANCE

L’assurance organise la prise en charge d’un risque incertain en contrepartie
d’une prime. Le contrat mutualise des risques homogènes, mais il ne transforme
pas tout dommage en sinistre garanti. Il faut distinguer le risque couvert,
l’événement assuré, le dommage, la garantie, l’exclusion et le montant
indemnisable dans le cadre CIMA et des textes nationaux complémentaires.

PARTIE I — ENTREPRISES ET INTERMÉDIAIRES

L’entreprise d’assurance doit être autorisée, disposer d’une organisation et
de ressources compatibles avec ses engagements, constituer les provisions et
respecter les règles de contrôle. L’intermédiaire doit agir dans les limites
de son mandat, présenter le produit avec loyauté et transmettre les
informations utiles à l’assureur et au souscripteur.

La solvabilité protège les assurés. Les provisions techniques représentent les
engagements futurs et les actifs doivent permettre leur couverture. Le
contrôle, les obligations de reporting et les mesures de redressement ou de
retrait répondent à une logique différente du règlement d’un sinistre
individuel.

PARTIE II — FORMATION DU CONTRAT

La proposition, la police, les conditions générales et particulières décrivent
le risque et la garantie. L’assureur doit pouvoir apprécier le risque à partir
des déclarations du souscripteur. Une information fausse ou incomplète peut
affecter la garantie selon la gravité, l’intention, le lien avec le sinistre et
le régime applicable.

La prime, la date d’effet, la durée, le renouvellement, la résiliation et les
modalités de notification doivent être identifiés. Une exclusion doit être
claire, précise et portée à la connaissance de l’assuré dans les conditions
requises. Une clause qui vide la garantie de sa substance doit être examinée
avec attention.

PARTIE III — RISQUE ET GARANTIES

L’aggravation du risque, sa disparition, le changement d’activité ou la
modification du bien peuvent imposer une déclaration et permettre une
adaptation du contrat. La garantie ne doit pas être étendue à un événement
étranger à la police. Les franchises, plafonds, sous-limites et règles de
proportion réduisent ou encadrent l’indemnité de manière différente.

Les assurances de biens, de personnes, de responsabilité, de transport et de
dommages liés à la circulation répondent à des logiques propres. L’assurance
obligatoire poursuit aussi une fonction de protection des victimes, qui peut
limiter les exceptions opposables à celles-ci.

PARTIE IV — SINISTRE ET INDEMNISATION

L’assuré doit déclarer le sinistre dans le délai prévu, prendre les mesures
conservatoires, transmettre les pièces et éviter d’aggraver le dommage.
L’assureur vérifie la garantie, la réalité de l’événement, la causalité, le
montant et les exclusions. L’expertise doit être contradictoire lorsque le
régime le prévoit; le rapport d’expert éclaire le montant sans remplacer la
qualification juridique.

L’indemnité répare le dommage garanti dans les limites du contrat et du droit.
Il faut déduire la franchise, respecter le plafond et éviter l’enrichissement
de l’assuré. Le paiement, le refus motivé, la contestation et la proposition
transactionnelle doivent être documentés.

PARTIE V — RESPONSABILITÉ ET RECOURS

La responsabilité civile suppose un fait générateur, un dommage et un lien
causal. L’assureur peut prendre en charge la dette de responsabilité selon la
police, tandis que la victime peut disposer d’une action directe ou d’un
recours spécial lorsque le texte le prévoit. L’assureur qui indemnise peut
exercer un recours subrogatoire dans les limites du paiement.

La prescription, la déchéance, la notification, la compétence et la
conciliation doivent être vérifiées séparément. Une clause de déchéance ne se
présume pas et son application dépend de ses conditions et du préjudice causé
à l’assureur.

MÉTHODE DE DOSSIER

Lire la police avant le récit du sinistre. Construire un tableau : souscripteur,
assuré, victime, risque, date d’effet, événement, déclaration, pièces,
exclusion, franchise, plafond, dommage et recours. Identifier ce qui est admis,
contesté et à prouver, puis vérifier la version actuelle du Code CIMA et des
textes nationaux applicables.
''';
