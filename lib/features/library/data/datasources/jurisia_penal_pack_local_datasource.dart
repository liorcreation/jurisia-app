import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';

/// Cours originaux JurisIA construits à partir des thèmes des ressources
/// pénales transmises : droit pénal général, spécial et procédure pénale.
///
/// Les textes sont rédigés pour JurisIA et ne reproduisent pas les ouvrages
/// consultés. Les incriminations, peines et délais doivent être vérifiés dans
/// le Code pénal et le Code de procédure pénale applicables au dossier.
final jurisiaPenalPackLocalDocuments = <LegalDocument>[
  LegalDocument(
    id: 'doc-jurisia-cours-complet-droit-penal-general',
    title: 'Cours complet JurisIA — Droit pénal général',
    type: LegalDocumentType.traite,
    domain: LegalDomain.penal,
    reference: 'Édition pédagogique originale JurisIA — pack Droit pénal',
    datePublication: DateTime(2026, 9, 19),
    summary:
        'Cours complet sur la loi pénale, l’infraction, la responsabilité, la participation, les causes d’irresponsabilité et les peines.',
    fullContent: _generalPenalCourse,
    outline: const [
      'Fondements, fonctions et sources du droit pénal',
      'Principe de légalité et application de la loi pénale',
      'Éléments constitutifs de l’infraction',
      'Tentative, coaction et complicité',
      'Responsabilité pénale et causes d’irresponsabilité',
      'Personnes morales, mineurs et pluralité d’infractions',
      'Peines, individualisation et extinction',
      'Méthode de cas pratique',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-penal',
      'droit pénal général',
      'infraction',
      'responsabilité pénale',
      'peines',
    ],
  ),
  LegalDocument(
    id: 'doc-jurisia-cours-complet-droit-penal-special',
    title: 'Cours complet JurisIA — Droit pénal spécial',
    type: LegalDocumentType.traite,
    domain: LegalDomain.penal,
    reference: 'Édition pédagogique originale JurisIA — pack Droit pénal',
    datePublication: DateTime(2026, 9, 19),
    summary:
        'Cours complet de qualification des atteintes aux personnes, aux biens, à la confiance, à l’autorité publique et à la sécurité.',
    fullContent: _specialPenalCourse,
    outline: const [
      'Méthode de qualification et lecture du texte d’incrimination',
      'Atteintes à la vie et à l’intégrité',
      'Atteintes sexuelles et violences',
      'Atteintes aux biens et au patrimoine',
      'Faux, escroquerie, abus de confiance et corruption',
      'Infractions contre l’autorité et la paix publiques',
      'Infractions numériques et économiques',
      'Méthode de cas pratique pénal',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-penal',
      'droit pénal spécial',
      'atteintes aux personnes',
      'atteintes aux biens',
      'infractions économiques',
    ],
  ),
  LegalDocument(
    id: 'doc-jurisia-cours-complet-procedure-penale',
    title: 'Cours complet JurisIA — Procédure pénale',
    type: LegalDocumentType.traite,
    domain: LegalDomain.procedurePenale,
    reference: 'Édition pédagogique originale JurisIA — pack Procédure pénale',
    datePublication: DateTime(2026, 9, 19),
    summary:
        'Cours complet sur l’action publique, l’enquête, l’instruction, le jugement, les voies de recours et l’exécution des décisions.',
    fullContent: _criminalProcedureCourse,
    outline: const [
      'Principes directeurs et acteurs du procès pénal',
      'Action publique, victime et alternatives aux poursuites',
      'Enquête et pouvoirs de police judiciaire',
      'Poursuites, instruction et mesures de sûreté',
      'Preuve, droits de la défense et contrôle juridictionnel',
      'Audience, jugement et voies de recours',
      'Exécution des peines et réparation de la victime',
      'Méthode de consultation procédurale',
    ],
    summaryOnly: false,
    officialSourceName: 'JurisIA — contenu pédagogique original',
    tags: const [
      'pack-penal',
      'procédure pénale',
      'enquête',
      'instruction',
      'jugement',
      'droits de la défense',
    ],
  ),
];

const _generalPenalCourse = r'''
COURS COMPLET JURISIA — DROIT PÉNAL GÉNÉRAL

ORIENTATION

Le droit pénal général fournit les catégories qui permettent de déterminer
quand un comportement peut être poursuivi, qui peut en répondre et quelle
sanction peut être prononcée. Il doit être lu avec le Code pénal applicable,
la Constitution, les textes de procédure et les instruments internationaux
en vigueur. Ce cours est une création pédagogique JurisIA inspirée par les
thèmes des supports transmis, et non la reproduction d'un ouvrage.

PARTIE I — FONDEMENTS ET LÉGALITÉ

Le droit pénal protège des intérêts fondamentaux en définissant des
interdictions et des sanctions. Il poursuit une fonction de protection, de
prévention, de réinsertion et de réaffirmation de la norme. Ces finalités ne
permettent pas de condamner sur la seule dangerosité supposée d'une personne :
la responsabilité doit reposer sur un texte et des faits établis.

Le principe de légalité exige qu'une incrimination et une peine soient prévues
par un texte accessible avant les faits. Il commande une interprétation stricte
du texte pénal et interdit l'analogie défavorable. La loi pénale plus sévère ne
doit pas rétroagir, tandis qu'une loi plus douce peut recevoir l'application
que prévoit le droit applicable. Les règles de compétence territoriale et les
cas de compétence extraterritoriale doivent être vérifiés séparément.

PARTIE II — L'INFRACTION

Une infraction s'analyse par un élément légal, un élément matériel et un
élément moral. L'élément légal est le texte qui décrit le comportement et la
sanction. L'élément matériel comprend l'acte ou l'omission, le résultat lorsque
le texte l'exige, les circonstances et parfois un lien causal. L'élément moral
correspond à l'intention, à la conscience, à la volonté ou à la faute
d'imprudence exigée par l'incrimination.

La classification en contravention, délit et crime dépend du droit national et
produit des conséquences sur la juridiction, la tentative, la prescription,
les mesures d'enquête et la peine. Une infraction instantanée se consomme à un
moment déterminé; une infraction continue se prolonge par la volonté de son
auteur; une infraction d'habitude suppose la répétition prévue par le texte.

La tentative suppose un commencement d'exécution et une interruption
indépendante de la volonté de l'auteur, sous réserve du régime prévu pour
l'infraction concernée. Les actes préparatoires ne suffisent pas toujours.
Le désistement volontaire peut modifier l'analyse, tandis que l'échec dû à un
événement extérieur n'efface pas nécessairement la tentative.

PARTIE III — AUTEURS ET PARTICIPANTS

L'auteur réalise les éléments de l'infraction ou participe directement à sa
réalisation. La coaction repose sur une action concertée. La complicité exige,
selon le texte applicable, une aide, une assistance, une provocation ou des
instructions données sciemment. Il faut distinguer l'aide intentionnelle de la
simple présence et démontrer le lien entre l'acte du participant et
l'infraction principale.

La responsabilité pénale est personnelle. Elle ne se déduit ni de la parenté,
ni de la fonction, ni de la propriété d'un bien. Une personne morale peut être
responsable lorsque le droit le prévoit et si l'infraction a été commise pour
son compte par un organe ou un représentant habilité. La responsabilité de la
personne morale n'efface pas nécessairement celle des personnes physiques.

PARTIE IV — IMPUTABILITÉ ET IRRESPONSABILITÉ

L'imputabilité demande que l'auteur ait pu comprendre et contrôler son acte.
L'âge, les troubles psychiques, la contrainte, l'erreur, l'état de nécessité,
la légitime défense et l'ordre de la loi peuvent modifier ou exclure la
responsabilité lorsque leurs conditions sont prouvées.

La légitime défense suppose une atteinte injustifiée, actuelle ou imminente,
et une riposte nécessaire et proportionnée. L'état de nécessité oppose un
danger grave à l'acte accompli pour le sauvegarder; la proportion et l'absence
d'alternative sont déterminantes. La contrainte doit être irrésistible et
l'ordre reçu ne protège pas un acte manifestement illégal selon le droit
applicable.

PARTIE V — PEINES ET INDIVIDUALISATION

La peine doit être légale, nécessaire et individualisée. Le juge tient compte
de la gravité des faits, de la personnalité, du rôle de chacun, du préjudice,
des antécédents et des efforts de réparation dans les limites du texte. Il
faut distinguer peine principale, peine complémentaire, mesure de sûreté,
réparation civile et mesure de confiscation.

La pluralité d'infractions, la récidive, la tentative, la participation et les
circonstances aggravantes influent sur le régime de sanction. L'extinction de
la peine, l'amnistie, la grâce, la prescription, la réhabilitation et
l'effacement des condamnations obéissent à des conditions différentes qu'il
ne faut pas confondre.

MÉTHODE DE CAS PRATIQUE

Pour traiter un cas, établir la chronologie; identifier chaque personne et
chaque acte; citer le texte d'incrimination; vérifier successivement les trois
éléments; analyser tentative et participation; examiner les causes
d'irresponsabilité; puis déterminer la peine et la compétence. Il faut
séparer ce qui est prouvé de ce qui est seulement allégué et vérifier la
version du Code pénal applicable à la date des faits.

''';

const _specialPenalCourse = r'''
COURS COMPLET JURISIA — DROIT PÉNAL SPÉCIAL

MÉTHODE DE QUALIFICATION

Le droit pénal spécial étudie chaque infraction à partir de son texte. Une
qualification sérieuse identifie le bien protégé, l'auteur visé, la victime,
le comportement, les circonstances, l'intention, le résultat, les aggravations
et la peine. Il faut éviter de partir d'une étiquette médiatique : les faits
doivent être confrontés aux éléments exacts de l'incrimination applicable.

ATTEINTES À LA VIE ET À L'INTÉGRITÉ

L'homicide volontaire se distingue de l'homicide involontaire par la volonté
de donner la mort et par la faute exigée. L'analyse porte sur l'acte causal,
le décès, l'intention et les circonstances aggravantes prévues. Les violences
volontaires se qualifient selon l'atteinte, les conséquences, l'arme, la
préméditation, la vulnérabilité de la victime et le contexte. Les blessures
involontaires exigent une faute de maladresse, imprudence, négligence ou
violation d'une obligation de sécurité selon le texte.

Les violences dans le couple, sur un mineur ou sur une personne vulnérable
peuvent relever de dispositions spéciales. Le consentement de la victime ne
justifie pas automatiquement toutes les atteintes : il faut vérifier la nature
du bien protégé et les limites de la loi.

ATTEINTES SEXUELLES ET PROTECTION DES PERSONNES

Les infractions sexuelles exigent une étude précise de l'âge, du consentement,
de la contrainte, de la menace, de la surprise, de l'autorité et des actes
reprochés. La protection des mineurs renforce les obligations de signalement
et les aggravations prévues par la loi. Le secret de l'enquête, la dignité de
la victime et la conservation des preuves médicales et numériques doivent être
préservés.

ATTEINTES AUX BIENS

Le vol suppose une soustraction frauduleuse de la chose d'autrui. L'analyse
doit identifier la chose, sa possession, l'absence de remise volontaire et
l'intention de se l'approprier. L'extorsion ajoute une contrainte, une menace
ou une violence. Le recel porte sur la détention, la transmission ou le profit
tiré d'une chose provenant d'une infraction, avec la connaissance requise.

L'abus de confiance repose sur un détournement d'un bien remis à charge de le
rendre, le représenter ou en faire un usage déterminé. L'escroquerie suppose
des manœuvres ou une tromperie ayant déterminé une remise. La distinction avec
un simple litige contractuel dépend de la fraude initiale, du moment de
l'intention et des preuves disponibles.

FAUX, CORRUPTION ET INFRACTIONS ÉCONOMIQUES

Le faux altère la vérité dans un écrit ou un support ayant une portée juridique
et l'usage consiste à s'en prévaloir. Il faut analyser le support, l'altération,
l'intention et le préjudice ou le risque juridiquement pertinent. La corruption
et le trafic d'influence nécessitent d'identifier l'avantage, l'intermédiaire,
la fonction concernée, l'accord ou la sollicitation et le moment de l'échange.

Les infractions d'affaires peuvent concerner la société, les créanciers, la
concurrence, le blanchiment, les marchés publics ou la gestion des fonds.
L'enquête financière doit suivre les flux, les bénéficiaires effectifs, les
actes de gestion et les pièces comptables sans confondre mauvaise gestion et
infraction intentionnelle.

AUTORITÉ, PAIX PUBLIQUE ET SÉCURITÉ

Les infractions contre l'autorité publique protègent le fonctionnement des
institutions, l'intégrité des agents et l'exécution des décisions. Il faut
vérifier la qualité de la victime, la mission exercée et la résistance ou la
menace reprochée. Les atteintes à la paix publique, les associations
criminelles, le port d'armes et le terrorisme relèvent de textes spéciaux qui
doivent être consultés dans leur version en vigueur.

INFRACTIONS NUMÉRIQUES ET PREUVE ÉLECTRONIQUE

L'accès frauduleux, l'atteinte à un système, la captation de données, la
diffusion illicite ou la fraude en ligne doivent être qualifiés selon le texte
national. Les preuves numériques exigent une chaîne de conservation : origine,
date, support, copie, intégrité, accès et rapprochement avec les autres faits.
Une capture d'écran isolée ne répond pas toujours aux exigences de preuve.

MÉTHODE DE CAS

Construire un tableau par infraction : texte, bien protégé, auteur, victime,
acte, résultat, intention, circonstances, preuve, aggravations et sanction.
Comparer ensuite les qualifications concurrentes, rechercher les éléments
communs et spéciaux, examiner la tentative et la complicité, puis conclure avec
la qualification la plus précise. Les montants et durées de peine doivent être
copiés uniquement depuis le Code pénal applicable, jamais déduits d'un ancien
support.

''';

const _criminalProcedureCourse = r'''
COURS COMPLET JURISIA — PROCÉDURE PÉNALE

PRINCIPES DIRECTEURS

La procédure pénale organise la recherche des infractions, la poursuite des
auteurs, le jugement et l'exécution de la décision. Elle doit concilier
recherche de la vérité, sécurité publique, présomption d'innocence, droits de
la défense, dignité, délai raisonnable, contrôle du juge et réparation de la
victime. Les règles de compétence, de délai et de nullité sont toujours celles
du Code de procédure pénale applicable.

ACTEURS ET ACTIONS

Le ministère public apprécie les suites à donner selon ses pouvoirs. La police
judiciaire constate, recherche, conserve les indices et exécute les actes
autorisés sous la direction prévue par la loi. Le juge d'instruction, lorsqu'il
existe dans le système concerné, recherche les charges à décharge et à charge.
La juridiction de jugement tranche la culpabilité et la peine. La victime peut
être témoin, partie civile ou demander réparation selon les formes prévues.

L'action publique tend à l'application de la loi pénale; l'action civile vise
la réparation du dommage. Elles peuvent être liées sans se confondre. Le
classement, la médiation, la composition ou toute autre alternative aux
poursuites supposent un fondement légal, un consentement valide et une
traçabilité de la décision.

ENQUÊTE

L'enquête de flagrance repose sur une situation permettant une intervention
immédiate; l'enquête préliminaire obéit à un cadre différent. Dans chaque cas,
vérifier le déclenchement, la direction, l'autorisation, la durée, les horaires
et la proportionnalité de l'acte. Auditions, perquisitions, saisies,
réquisitions, interceptions, géolocalisation et constatations doivent respecter
les garanties propres à leur régime.

La garde à vue ou mesure équivalente est strictement encadrée : notification
des droits, information sur les faits, assistance d'un avocat lorsque la loi le
prévoit, examen médical, information d'un proche ou d'une autorité et contrôle
de la durée. Toute prolongation doit être autorisée selon les conditions
applicables. Les procès-verbaux doivent indiquer les heures, personnes
présentes, actes accomplis et signatures ou réserves.

POURSUITES ET INSTRUCTION

Après l'enquête, le parquet peut classer, orienter vers une alternative,
engager des poursuites ou saisir un juge. L'acte de poursuite doit permettre
au prévenu de connaître les faits et la qualification. Lorsque l'instruction
est ouverte, les parties peuvent demander des actes, contester certaines
décisions et accéder au dossier selon les règles de confidentialité.

Les mesures de sûreté ne sont pas des peines anticipées. Le contrôle judiciaire,
la détention provisoire, l'assignation ou les obligations de pointage exigent
nécessité, proportionnalité, motivation et contrôle périodique. La liberté reste
le principe lorsque les conditions de la restriction ne sont pas démontrées.

PREUVE ET NULLITÉS

La preuve pénale doit être obtenue et discutée loyalement. La présomption
d'innocence impose à l'accusation de démontrer les éléments de l'infraction;
le silence ne vaut pas aveu. La preuve scientifique, numérique, documentaire et
testimoniale doit être authentifiée et replacée dans sa chaîne de conservation.

Une nullité suppose l'identification d'une règle violée, d'un acte concerné et
du grief ou de la condition exigée par le droit. Il faut agir au bon moment,
devant la juridiction compétente et selon la forme prévue. Une irrégularité ne
conduit pas automatiquement à l'annulation de tout le dossier.

JUGEMENT ET VOIES DE RECOURS

L'audience respecte publicité ou huis clos justifié, débat contradictoire,
présence ou représentation, lecture des faits, examen des preuves, réquisitions,
plaidoiries et dernier mot de la personne poursuivie. La décision doit être
motivée, répondre aux moyens essentiels et distinguer culpabilité, peine,
intérêts civils et frais.

L'appel permet un nouvel examen dans la limite de sa saisine. Le pourvoi ou
recours en cassation contrôle l'application du droit selon les conditions du
système concerné. Les délais, effets suspensifs, personnes habilitées et
formalités doivent être vérifiés avant tout recours. Une décision définitive
produit l'autorité attachée à la chose jugée selon son périmètre.

EXÉCUTION ET VICTIME

L'exécution concerne la peine, les mesures de sûreté, la confiscation et la
réparation. Le condamné conserve les droits compatibles avec la sanction et
doit pouvoir accéder aux mécanismes prévus de réduction, aménagement ou
réhabilitation. La victime doit recevoir l'information prévue, pouvoir faire
valoir sa demande et être protégée contre les représailles.

MÉTHODE DE CONSULTATION

Pour analyser un dossier de procédure : construire une chronologie précise;
identifier l'autorité et l'acte; vérifier compétence, base légale, délai,
forme, notification, assistance et proportionnalité; mesurer le grief; choisir
la demande utile — nullité, remise en liberté, acte d'enquête, appel ou
réparation — et contrôler la date limite. Toujours demander la version
officielle du Code de procédure pénale avant de conclure.

Ce cours est un support pédagogique original de JurisIA. Il ne remplace ni un
avocat, ni le texte officiel, ni une décision juridictionnelle dans un dossier
concret.
''';
