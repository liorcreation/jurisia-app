import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';

/// Cours originaux JurisIA construits à partir des thèmes des ressources
/// transmises sur le droit judiciaire privé et la procédure civile.
///
/// Les ouvrages de référence servent uniquement à cadrer les thèmes. Les
/// textes ci-dessous sont rédigés pour JurisIA et ne reproduisent pas les
/// ouvrages consultés. Les délais, compétences et formalités doivent être
/// vérifiés dans les textes applicables au dossier.
final jurisiaPrivateJudicialLawPackLocalDocuments = <LegalDocument>[
  LegalDocument(
    id: 'doc-jurisia-fondements-droit-judiciaire-prive',
    title: 'Cours complet JurisIA — Fondements du droit judiciaire privé',
    type: LegalDocumentType.traite,
    domain: LegalDomain.procedureCivile,
    reference: 'Édition pédagogique originale JurisIA — pack DJP',
    datePublication: DateTime(2026, 9, 20),
    summary:
        'Cours complet sur la justice civile, l’action en justice, les acteurs, la compétence, la preuve et les principes directeurs du procès.',
    fullContent: _privateJudicialFoundations,
    outline: const [
      'Notion, fonctions et sources du droit judiciaire privé',
      'Organisation des juridictions et acteurs du procès',
      'Action en justice, intérêt, qualité et recevabilité',
      'Compétence matérielle et territoriale',
      'Principes directeurs du procès civil',
      'Preuve, actes de procédure et incidents',
      'Décision de justice, autorité et exécution',
      'Méthode de consultation et cas pratique',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-droit-judiciaire-prive',
      'droit judiciaire privé',
      'action en justice',
      'compétence',
      'procès civil',
    ],
  ),
  LegalDocument(
    id: 'doc-jurisia-procedure-civile-complete',
    title: 'Cours complet JurisIA — Procédure civile',
    type: LegalDocumentType.traite,
    domain: LegalDomain.procedureCivile,
    reference: 'Édition pédagogique originale JurisIA — pack DJP',
    datePublication: DateTime(2026, 9, 20),
    summary:
        'Cours complet sur l’introduction de l’instance, la mise en état, les mesures d’instruction, les incidents, le jugement et les recours.',
    fullContent: _civilProcedureCourse,
    outline: const [
      'Saisine, assignation, requête et constitution',
      'Déroulement de l’instance et calendrier procédural',
      'Conclusions, moyens, demandes et office du juge',
      'Mise en état et mesures d’instruction',
      'Incidents, exceptions et nullités',
      'Audience, délibéré et jugement',
      'Appel, opposition, cassation et recours particuliers',
      'Méthode de rédaction d’un acte ou d’une consultation',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-droit-judiciaire-prive',
      'procédure civile',
      'instance',
      'mise en état',
      'voies de recours',
    ],
  ),
  LegalDocument(
    id: 'doc-jurisia-juridictions-execution-civile',
    title: 'Cours complet JurisIA — Juridictions et exécution civile',
    type: LegalDocumentType.traite,
    domain: LegalDomain.procedureCivile,
    reference: 'Édition pédagogique originale JurisIA — pack DJP',
    datePublication: DateTime(2026, 9, 20),
    summary:
        'Cours complet sur les juridictions civiles, les référés, les procédures spéciales, les mesures conservatoires et l’exécution forcée.',
    fullContent: _jurisdictionsAndEnforcementCourse,
    outline: const [
      'Juridictions de droit commun et juridictions spécialisées',
      'Référé, requête et procédures accélérées',
      'Médiation, conciliation et modes amiables',
      'Mesures conservatoires et sûretés judiciaires',
      'Titre exécutoire et conditions de l’exécution',
      'Saisies mobilières, saisie-attribution et saisie immobilière',
      'Difficultés, contestations et responsabilité des intervenants',
      'Parcours pratique du justiciable',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-droit-judiciaire-prive',
      'juridictions civiles',
      'référé',
      'exécution forcée',
      'saisies',
    ],
  ),
];

const _privateJudicialFoundations = r'''
COURS COMPLET JURISIA — FONDEMENTS DU DROIT JUDICIAIRE PRIVÉ

ORIENTATION

Le droit judiciaire privé organise la manière dont une personne demande au
juge civil de reconnaître, protéger ou réaliser un droit. Il ne se confond
pas avec le droit substantiel : le droit des contrats, de la famille ou des
biens détermine la règle de fond, tandis que le droit judiciaire privé règle
la saisine, le débat, la décision et son exécution. Une consultation complète
doit toujours articuler ces deux dimensions.

PARTIE I — OBJET, SOURCES ET FONCTIONS

La matière comprend les règles relatives aux juridictions civiles, à l'action
en justice, à la compétence, à l'instance, à la preuve procédurale, aux voies
de recours et à l'exécution des décisions. Ses sources sont la Constitution,
les traités, les lois, les règlements de procédure, les textes organisant les
juridictions et la jurisprudence dans les limites reconnues par le système
juridique applicable. La coutume professionnelle ne peut écarter une règle
impérative.

Le procès remplit une fonction de protection et de pacification. Il permet de
faire constater une situation, d'obtenir une condamnation, de faire cesser un
trouble ou de prendre une mesure provisoire. Le juge doit préserver l'égalité
des armes, la contradiction, l'accès au tribunal et le délai raisonnable.

PARTIE II — JURIDICTIONS ET ACTEURS

La compétence d'une juridiction se vérifie avant toute rédaction. Il faut
identifier la nature du litige, la qualité des parties, la valeur de la
demande, le lieu pertinent et l'existence d'une attribution spéciale. Les
juridictions de droit commun connaissent des litiges qui ne sont pas réservés
à une juridiction spécialisée. Les juridictions commerciales, sociales,
foncières ou familiales interviennent lorsque les textes leur attribuent le
litige.

Le juge tranche les prétentions qui lui sont soumises et ne statue pas au-delà
de ce qui est demandé. Le greffe assure l'authentification, la conservation
et la circulation de nombreux actes. L'avocat conseille, rédige et représente
son client selon les règles de représentation. L'huissier ou commissaire de
justice signifie les actes et contribue à l'exécution lorsque son statut le
prévoit. Le ministère public intervient dans les cas déterminés par la loi.

PARTIE III — ACTION EN JUSTICE

L'action est le droit de soumettre une prétention à un juge pour qu'il la
tranche. Elle se distingue de la demande, qui est l'acte procédural par lequel
ce droit est exercé, et de la défense, qui répond à la prétention adverse. La
recevabilité s'apprécie notamment au regard de l'intérêt, de la qualité, de la
capacité, du délai et du respect des conditions de forme.

L'intérêt doit être personnel, légitime, actuel et suffisamment concret, sauf
les actions préventives ou collectives admises par un texte. La qualité dépend
du droit invoqué ou de la représentation autorisée. La capacité procédurale
doit être distinguée du bien-fondé : une partie peut avoir qualité pour agir
et pourtant perdre sur le fond.

PARTIE IV — PRINCIPES DIRECTEURS

Les parties introduisent l'instance et déterminent l'objet du litige par leurs
prétentions. Elles doivent exposer les faits utiles, les moyens de droit et
les pièces qui les soutiennent. Le juge applique la règle de droit et peut
demander les explications nécessaires, sans remplacer une partie défaillante
dans la conduite de son procès.

Le contradictoire impose que chaque pièce, demande et argument susceptible
de fonder la décision soit communiqué et puisse être discuté. La loyauté
procédurale interdit la rétention abusive d'une information ou la surprise
organisée. Le juge peut écarter une pièce communiquée trop tard si son examen
porterait atteinte aux droits de la défense, selon le texte applicable.

PARTIE V — PREUVE ET ACTES

La preuve du fait générateur, du dommage et du lien causal relève en principe
de celui qui prétend un droit. La charge peut être aménagée par la loi ou par
une présomption. Il faut distinguer la recevabilité d'un moyen de preuve, sa
force probante et l'appréciation souveraine du juge.

Un acte de procédure doit être signé par la personne habilitée, identifier les
parties, exposer l'objet de la démarche, mentionner les délais et indiquer les
conséquences de l'inaction lorsque le texte l'exige. La signification et la
notification ne sont pas interchangeables : leur choix dépend de la loi et du
type d'acte. Une irrégularité ne justifie une nullité que si le régime prévu
est rempli et, souvent, si un grief est démontré.

PARTIE VI — DÉCISION ET EXÉCUTION

Le jugement doit répondre aux prétentions, être motivé et permettre de
comprendre le raisonnement suivi. L'autorité de la chose jugée porte sur ce
qui a été tranché entre les mêmes parties, pour le même objet et sur la même
cause, dans les limites du droit applicable. L'exécution provisoire, la force
exécutoire et les voies de recours doivent être vérifiées séparément.

MÉTHODE DE CONSULTATION

Commencer par une chronologie. Identifier les parties, leur qualité, la
prétention, le fondement substantiel, le juge compétent, le délai et l'acte
à accomplir. Vérifier les conditions de recevabilité avant le fond, préparer
la preuve et prévoir les conséquences d'une décision favorable ou défavorable.
Ne jamais annoncer un délai ou une compétence sans vérifier la version du
texte applicable au ressort concerné.
''';

const _civilProcedureCourse = r'''
COURS COMPLET JURISIA — PROCÉDURE CIVILE

SÉQUENCE GÉNÉRALE

Une procédure civile suit une chaîne : naissance du différend, choix d'une
solution amiable ou contentieuse, saisine, mise en état, débat, jugement,
recours éventuel et exécution. Chaque étape possède ses propres délais et
formes. L'analyse doit toujours préciser la juridiction et le droit de la
procédure applicables, car une règle connue dans un autre système ne peut pas
être transposée automatiquement.

PARTIE I — SAISINE ET INTRODUCTION DE L'INSTANCE

L'assignation informe le défendeur de la demande, des faits, des moyens, de la
juridiction saisie, de la date d'audience et des conséquences d'une absence.
La requête est adaptée lorsque le texte autorise une saisine non contradictoire
ou une procédure simplifiée. La déclaration, la requête conjointe ou la
constitution peuvent répondre à des situations particulières.

Avant de déposer l'acte, contrôler l'identité et l'adresse des parties, la
capacité, le pouvoir du représentant, la compétence, le calcul de la demande,
les pièces et les mentions obligatoires. Une erreur sur la juridiction ou sur
la notification peut retarder le procès ou entraîner une irrecevabilité.

PARTIE II — INSTANCE ET PRÉTENTIONS

Les demandes initiales, additionnelles, reconventionnelles et incidentes ne
produisent pas les mêmes effets. Il faut distinguer la demande de la simple
argumentation et déterminer si la prétention nouvelle se rattache suffisamment
au litige initial. Les conclusions doivent exposer les demandes dans un
dispositif clair, puis développer les faits, les moyens et les pièces.

Le calendrier procédural organise les échanges. Une partie qui reçoit une
conclusion doit disposer d'un temps utile pour répondre. Le juge peut fixer des
délais, ordonner la clôture des échanges ou inviter les parties à préciser un
point. La mise en état sert à purger les difficultés et à préparer l'affaire
pour l'audience; elle ne dispense pas de respecter le contradictoire.

PARTIE III — MESURES D'INSTRUCTION

Lorsque les pièces produites ne suffisent pas, le juge peut ordonner une
mesure d'instruction autorisée : expertise, constat, audition, enquête,
comparution ou production d'un document. La mesure doit être utile à la
solution du litige et proportionnée. L'expert éclaire le juge sans trancher
la question juridique. Les parties doivent pouvoir discuter la mission, les
dires, les opérations et le rapport.

Une demande de production forcée doit identifier le document, expliquer son
utilité et respecter les secrets protégés. Une mesure avant tout procès peut
être sollicitée pour conserver ou établir la preuve d'un fait dont dépend un
litige futur lorsque les conditions sont remplies.

PARTIE IV — INCIDENTS, EXCEPTIONS ET NULLITÉS

Les exceptions de procédure tendent à faire suspendre ou déclarer irrégulière
la procédure sans discuter immédiatement le fond. L'incompétence, la litispendance,
la connexité, le défaut de pouvoir et les délais de procédure doivent être
qualifiés correctement et soulevés au moment prévu.

La fin de non-recevoir conteste le droit d'agir : défaut d'intérêt, défaut de
qualité, prescription ou autorité de la chose jugée peuvent en relever selon
le droit applicable. La nullité vise un acte irrégulier. Il faut vérifier le
texte, l'auteur de l'acte, le délai, le grief éventuel et la possibilité de
régularisation. Une défense au fond ne doit pas être présentée comme une
exception et inversement.

PARTIE V — AUDIENCE ET JUGEMENT

À l'audience, le juge vérifie l'état du dossier et peut entendre les
observations utiles. La clôture du débat empêche en principe les écritures et
pièces tardives, sauf réouverture ou exception prévue. Le délibéré doit rester
indépendant des parties. Le jugement expose les prétentions, les motifs et le
dispositif; c'est le dispositif qui fixe la mesure ordonnée.

Une décision doit être lue avec sa date, sa notification, son caractère
contradictoire ou non, sa force exécutoire et les voies de recours indiquées.
Une erreur matérielle, une omission de statuer et une difficulté
d'interprétation ne se traitent pas par le même recours.

PARTIE VI — RECOURS

L'opposition permet, dans les cas prévus, de faire rejuger une décision rendue
en l'absence d'une partie. L'appel remet devant la juridiction supérieure les
points dévolus par l'acte d'appel et les prétentions recevables. Le recours en
cassation ne constitue pas un troisième examen général des faits : il contrôle
la conformité de la décision au droit et aux règles de procédure.

Le délai court à compter de l'événement prévu par le texte, souvent la
notification. Il faut vérifier le mode de notification, le point de départ,
les causes d'interruption ou de suspension, la représentation obligatoire et
les effets du recours sur l'exécution.

MÉTHODE DE RÉDACTION

Pour une assignation, présenter les parties, la juridiction, les faits, les
fondements, les demandes, les pièces et les mentions imposées. Pour des
conclusions, répondre point par point aux moyens adverses et terminer par un
dispositif numéroté. Pour une consultation, distinguer les options, les
risques, les délais, les preuves disponibles et la solution recommandée.
''';

const _jurisdictionsAndEnforcementCourse = r'''
COURS COMPLET JURISIA — JURIDICTIONS ET EXÉCUTION CIVILE

PARTIE I — CARTOGRAPHIE DES JURIDICTIONS

La carte juridictionnelle se lit selon trois questions : quelle matière est en
cause, quel degré de juridiction doit connaître le litige et quel lieu est
pertinent ? La juridiction de première instance reçoit en principe les demandes
initiales. La juridiction d'appel réexamine les points dévolus. La juridiction
suprême contrôle le droit dans les limites de son office.

La juridiction civile de droit commun connaît des litiges privés non attribués
à une autre formation. Des juridictions spécialisées peuvent connaître du
commerce, du travail, de la famille, du foncier ou d'une catégorie particulière
de personnes. La dénomination et les seuils dépendent de l'organisation
judiciaire nationale : ils doivent être vérifiés avant la saisine.

PARTIE II — RÉFÉRÉ ET PROCÉDURES RAPIDES

Le référé permet d'obtenir une mesure provisoire lorsque l'urgence, l'absence
de contestation sérieuse, la nécessité de prévenir un dommage ou le trouble
manifestement illicite répond aux conditions du texte. Le juge des référés ne
tranche pas définitivement le principal, mais sa décision peut avoir un effet
pratique immédiat.

La requête non contradictoire n'est admise que lorsque la loi ou les
circonstances justifient de ne pas avertir l'adversaire avant la mesure. Le
demandeur doit expliquer pourquoi la contradiction immédiate ferait disparaître
l'efficacité de la preuve ou de la protection demandée. L'adversaire peut
solliciter la rétractation ou contester la mesure dans les formes prévues.

PARTIE III — MODES AMIABLES

La négociation, la conciliation et la médiation recherchent une solution sans
imposer à l'une des parties la décision d'un juge. Il faut expliquer les
concessions, la confidentialité, le rôle du tiers et la portée de l'accord.
Un accord peut devenir exécutoire par homologation ou par la formalité prévue.
Le recours à l'amiable n'autorise pas à laisser expirer un délai de prescription
ou de recours sans vérifier l'effet juridique de la démarche.

PARTIE IV — CONSERVATION ET EXÉCUTION

Une mesure conservatoire protège le recouvrement avant que le débiteur ne
disparaisse ou n'organise son insolvabilité. Elle peut porter sur des biens ou
des créances si la créance paraît fondée et si les circonstances menacent son
recouvrement. L'autorisation judiciaire, la dénonciation, la conversion et la
mainlevée suivent des règles précises.

L'exécution forcée suppose en principe un titre exécutoire, une obligation
déterminée ou déterminable et une exigibilité actuelle. Le créancier choisit
la mesure adaptée sans dépasser ce qui est nécessaire : paiement volontaire,
saisie-attribution, saisie-vente, saisie immobilière, obligation de faire ou
astreinte peuvent répondre à des situations différentes.

PARTIE V — SAISIES ET CONTESTATIONS

La saisie-attribution immobilise une créance entre les mains d'un tiers et
organise son attribution au créancier dans les limites de la dette. La saisie
mobilière vise des biens corporels identifiables; elle doit respecter les
biens insaisissables et les protections du débiteur. La saisie immobilière
obéit à un formalisme renforcé : commandement, publicité, orientation,
conditions de vente et répartition doivent être suivis dans l'ordre.

Le débiteur peut contester le titre, le montant, la régularité de l'acte, la
proportion de la mesure ou l'insaisissabilité d'un bien. Le tiers saisi doit
déclarer ce qu'il détient et ne pas aggraver la situation par une déclaration
inexacte. L'agent chargé de l'exécution engage sa responsabilité en cas de
faute, mais chaque contestation relève de la juridiction désignée par le texte.

PARTIE VI — PARCOURS PRATIQUE

Pour aider un justiciable, établir l'objectif : obtenir une décision, préserver
une preuve, empêcher un dommage, recouvrer une somme ou faire cesser un trouble.
Rassembler le titre, le contrat, les échanges, les preuves de notification,
les informations sur les biens et l'historique des paiements. Calculer les
délais et les coûts. Choisir ensuite la voie amiable, la procédure au fond,
le référé ou la mesure conservatoire.

Une stratégie professionnelle indique les avantages et limites de chaque
option. Elle ne promet pas un résultat, distingue les faits établis des
hypothèses et vérifie la version actuelle des textes, les seuils de compétence,
les tarifs et les formalités du ressort concerné.
''';
