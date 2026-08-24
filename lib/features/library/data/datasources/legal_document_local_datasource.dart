import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';

/// Frontière data vers la source des documents juridiques. Permet de
/// substituer, plus tard, une source distante (API, base de données) à la
/// base locale sans toucher au reste de l'architecture.
abstract class LegalDocumentDataSource {
  List<LegalDocument> getAll();
}

/// Base de données locale de démonstration couvrant les grandes familles de
/// textes du droit national et de l'espace OHADA : Constitution, codes,
/// lois, décrets, arrêtés, jurisprudence, actes uniformes et modèles
/// d'actes. Les références et numéros cités sont illustratifs.
class LocalLegalDocumentDataSource implements LegalDocumentDataSource {
  const LocalLegalDocumentDataSource();

  @override
  List<LegalDocument> getAll() => _documents;
}

final List<LegalDocument> _documents = [
  LegalDocument(
    id: 'doc-constitution',
    title: 'Constitution',
    type: LegalDocumentType.constitution,
    domain: LegalDomain.constitutionnel,
    reference: 'Texte fondamental',
    datePublication: DateTime(1996, 12, 18),
    summary: 'Loi fondamentale organisant les pouvoirs publics et les droits fondamentaux.',
    fullContent:
        'La Constitution est la loi fondamentale de l\'État. Elle organise la séparation des '
        'pouvoirs exécutif, législatif et judiciaire, fixe les conditions d\'exercice de la '
        'souveraineté nationale et garantit les droits et libertés fondamentaux des citoyens : '
        'égalité devant la loi, liberté d\'opinion et d\'expression, droit à un procès équitable, '
        'inviolabilité du domicile et de la correspondance.\n\n'
        'Toute norme inférieure — loi, décret, arrêté — doit être conforme à la Constitution. Un '
        'contrôle de constitutionnalité permet de vérifier cette conformité, a priori comme a '
        'posteriori selon les cas, devant la juridiction constitutionnelle compétente.\n\n'
        'La Constitution consacre également l\'indépendance de la justice, l\'organisation '
        'décentralisée des collectivités territoriales, et les principes budgétaires encadrant '
        'l\'action de l\'administration publique.',
    tags: const ['institutions', 'droits fondamentaux', 'séparation des pouvoirs'],
  ),
  LegalDocument(
    id: 'doc-code-civil',
    title: 'Code civil',
    type: LegalDocumentType.code,
    domain: LegalDomain.civil,
    reference: 'Livre I à IV',
    datePublication: DateTime(1958, 3, 4),
    summary: 'Régit les personnes, la famille, les biens et les obligations.',
    fullContent:
        'Le Code civil régit l\'état des personnes, les rapports de famille, le régime des biens '
        'et le droit des obligations. Il pose le principe selon lequel toute personne physique '
        'jouit de ses droits civils dès sa naissance, et organise l\'état civil, le mariage, la '
        'filiation, l\'autorité parentale et les successions.\n\n'
        'En matière de biens, il distingue les biens meubles et immeubles, organise la propriété, '
        'ses démembrements (usufruit, servitudes) et les modes d\'acquisition, notamment la '
        'prescription acquisitive.\n\n'
        'Le droit des obligations fixe les conditions de formation, d\'exécution et d\'extinction '
        'des contrats, ainsi que le régime de la responsabilité civile délictuelle et '
        'contractuelle : toute personne qui, par sa faute, cause un dommage à autrui est tenue de '
        'le réparer.',
    tags: const ['contrats', 'famille', 'biens', 'responsabilité civile'],
    relatedDocumentIds: const ['doc-modele-bail-habitation'],
  ),
  LegalDocument(
    id: 'doc-code-travail',
    title: 'Code du travail',
    type: LegalDocumentType.code,
    domain: LegalDomain.travail,
    reference: 'Édition consolidée',
    datePublication: DateTime(1992, 12, 15),
    summary: 'Relations individuelles et collectives de travail.',
    fullContent:
        'Le Code du travail encadre les relations individuelles et collectives entre employeurs '
        'et travailleurs. Il définit le contrat de travail — à durée indéterminée ou déterminée — '
        'ses conditions de formation, de suspension et de rupture, ainsi que les obligations '
        'réciproques des parties : fourniture du travail convenu et paiement du salaire d\'un '
        'côté, exécution personnelle et loyale de la prestation de l\'autre.\n\n'
        'Il fixe la durée légale du travail, les repos et congés payés, les règles d\'hygiène et '
        'de sécurité, ainsi que le salaire minimum interprofessionnel garanti.\n\n'
        'La rupture du contrat de travail à durée indéterminée à l\'initiative de l\'employeur '
        'doit reposer sur un motif légitime et respecter un préavis, sauf faute grave. À défaut, '
        'le licenciement peut être qualifié d\'abusif et ouvrir droit à des dommages et intérêts. '
        'Le Code organise également le droit syndical, les délégués du personnel et la '
        'négociation collective.',
    tags: const ['contrat de travail', 'licenciement', 'négociation collective'],
    relatedDocumentIds: const ['doc-jurisprudence-licenciement', 'doc-modele-cdd'],
  ),
  LegalDocument(
    id: 'doc-code-commerce',
    title: 'Code de commerce',
    type: LegalDocumentType.code,
    domain: LegalDomain.commercial,
    reference: 'Livre I à III',
    datePublication: DateTime(2003, 6, 30),
    summary: 'Statut du commerçant, fonds de commerce et actes de commerce.',
    fullContent:
        'Le Code de commerce définit la qualité de commerçant, les obligations comptables et '
        'déclaratives qui s\'y attachent, ainsi que le régime du fonds de commerce (clientèle, '
        'enseigne, droit au bail, matériel).\n\n'
        'Il énumère les actes réputés actes de commerce par leur forme ou par leur objet, et fixe '
        'les règles spécifiques de preuve applicables entre commerçants, plus souples qu\'en '
        'matière civile.\n\n'
        'Le livre consacré aux difficultés des entreprises organise les procédures de prévention, '
        'de redressement et de liquidation judiciaire, dans un objectif d\'apurement du passif et, '
        'lorsque cela est possible, de sauvegarde de l\'activité et de l\'emploi.',
    tags: const ['commerçant', 'fonds de commerce', 'entreprises en difficulté'],
  ),
  LegalDocument(
    id: 'doc-loi-bail-professionnel',
    title: 'Loi relative au bail à usage professionnel',
    type: LegalDocumentType.loi,
    domain: LegalDomain.commercial,
    reference: 'Loi n° 2016-234',
    datePublication: DateTime(2016, 6, 21),
    summary: 'Encadre les rapports entre bailleurs et preneurs à usage commercial.',
    fullContent:
        'La présente loi encadre les baux portant sur des locaux à usage commercial, industriel '
        'ou artisanal. Elle fixe une durée minimale du bail, les conditions de son renouvellement '
        'et le droit du preneur à une indemnité d\'éviction en cas de refus de renouvellement non '
        'justifié par un motif grave et légitime.\n\n'
        'Le loyer est révisable selon une périodicité encadrée, et toute clause manifestement '
        'abusive au détriment du preneur peut être réputée non écrite par le juge.\n\n'
        'La loi organise également la cession du droit au bail et la sous-location, qui restent '
        'subordonnées, sauf stipulation contraire, à l\'accord préalable du bailleur.',
    tags: const ['bail', 'commerce', 'indemnité d\'éviction'],
  ),
  LegalDocument(
    id: 'doc-loi-donnees-personnelles',
    title: 'Loi relative à la protection des données à caractère personnel',
    type: LegalDocumentType.loi,
    domain: LegalDomain.administratif,
    reference: 'Loi n° 2019-071',
    datePublication: DateTime(2019, 4, 9),
    summary: 'Encadre la collecte et le traitement des données personnelles.',
    fullContent:
        'Cette loi soumet tout traitement de données à caractère personnel au respect des '
        'principes de licéité, de finalité déterminée, de proportionnalité et de sécurité. Le '
        'responsable du traitement doit informer les personnes concernées, recueillir leur '
        'consentement lorsqu\'il est requis, et leur garantir un droit d\'accès, de rectification '
        'et d\'opposition.\n\n'
        'Les traitements sensibles (données de santé, origine, opinions) et les transferts de '
        'données hors du territoire national sont soumis à un régime renforcé, avec autorisation '
        'préalable de l\'autorité de protection des données dans les cas prévus par la loi.\n\n'
        'Le non-respect de ces obligations expose le responsable du traitement à des sanctions '
        'administratives et, le cas échéant, pénales.',
    tags: const ['données personnelles', 'vie privée'],
  ),
  LegalDocument(
    id: 'doc-decret-application-travail',
    title: "Décret d'application relatif à la durée du travail",
    type: LegalDocumentType.decret,
    domain: LegalDomain.travail,
    reference: 'Décret n° 2020-118',
    datePublication: DateTime(2020, 2, 3),
    dateEntreeEnVigueur: DateTime(2020, 5, 1),
    summary: 'Précise les modalités d\'application des dispositions du Code du travail sur la durée légale du travail.',
    fullContent:
        'Le présent décret précise les modalités d\'application des dispositions légales relatives '
        'à la durée du travail. Il fixe la durée hebdomadaire de référence, les conditions de '
        'recours aux heures supplémentaires et leur taux de majoration, ainsi que les dérogations '
        'possibles par voie de convention collective.\n\n'
        'Il détaille également les régimes particuliers applicables au travail de nuit, au travail '
        'posté et aux astreintes, ainsi que les registres et affichages obligatoires que '
        'l\'employeur doit tenir à disposition de l\'inspection du travail.',
    tags: const ['durée du travail', 'heures supplémentaires'],
  ),
  LegalDocument(
    id: 'doc-arrete-smig',
    title: 'Arrêté fixant le salaire minimum interprofessionnel garanti',
    type: LegalDocumentType.arrete,
    domain: LegalDomain.travail,
    reference: 'Arrêté n° 2024-045/MTFP',
    datePublication: DateTime(2024, 1, 15),
    summary: 'Fixe le montant du salaire minimum interprofessionnel garanti (SMIG).',
    fullContent:
        'Le présent arrêté fixe le montant du salaire minimum interprofessionnel garanti '
        'applicable à l\'ensemble des secteurs d\'activité, à l\'exception des régimes '
        'particuliers prévus par convention collective étendue.\n\n'
        'Ce montant s\'entend pour une durée de travail hebdomadaire à temps plein telle que fixée '
        'par le Code du travail et ses textes d\'application. Il est révisé périodiquement en '
        'fonction de l\'évolution du coût de la vie, sur proposition de la commission nationale '
        'consultative du travail.',
    tags: const ['salaire minimum', 'SMIG'],
  ),
  LegalDocument(
    id: 'doc-jurisprudence-licenciement',
    title: 'Arrêt sur la rupture abusive du contrat de travail',
    type: LegalDocumentType.jurisprudence,
    domain: LegalDomain.travail,
    reference: 'Cass. soc., n° 245/2021',
    datePublication: DateTime(2021, 9, 14),
    summary: "Précise les critères d'appréciation du caractère abusif d'un licenciement.",
    fullContent:
        'La Cour rappelle que le licenciement pour motif personnel doit reposer sur une cause '
        'réelle et sérieuse, objectivement vérifiable et étrangère à toute discrimination. '
        'L\'employeur qui invoque une insuffisance professionnelle doit être en mesure d\'en '
        'établir la réalité par des éléments précis et concordants, et non par de simples '
        'appréciations générales.\n\n'
        'En l\'espèce, l\'absence de tout entretien préalable formalisé et de mise en demeure '
        'antérieure prive l\'employeur de la possibilité de démontrer que le salarié avait été '
        'informé des griefs reprochés et mis en mesure d\'y remédier. Le licenciement est en '
        'conséquence déclaré sans cause réelle et sérieuse, et donne lieu à l\'octroi de dommages '
        'et intérêts proportionnés à l\'ancienneté du salarié et au préjudice subi.',
    tags: const ['licenciement', 'préavis', 'cause réelle et sérieuse'],
  ),
  LegalDocument(
    id: 'doc-jurisprudence-vente',
    title: "Arrêt sur la résolution d'une vente pour inexécution",
    type: LegalDocumentType.jurisprudence,
    domain: LegalDomain.civil,
    reference: 'Cass. civ., n° 118/2019',
    datePublication: DateTime(2019, 11, 6),
    summary: "Conditions de la résolution judiciaire d'un contrat de vente pour défaut de livraison.",
    fullContent:
        'La Cour retient que l\'inexécution d\'une obligation essentielle du contrat de vente — en '
        'l\'espèce, le défaut de livraison de la chose vendue dans le délai convenu — justifie la '
        'résolution du contrat aux torts du vendeur, sans qu\'il soit nécessaire que l\'acheteur '
        'établisse un préjudice distinct du seul défaut de délivrance.\n\n'
        'La résolution emporte restitution réciproque des prestations déjà exécutées : le vendeur '
        'restitue le prix perçu, l\'acheteur restitue la chose s\'il l\'a reçue. Des dommages et '
        'intérêts complémentaires peuvent être alloués si l\'acheteur établit un préjudice '
        'supplémentaire directement lié au retard ou au défaut de livraison.',
    tags: const ['vente', 'résolution du contrat', 'inexécution'],
  ),
  LegalDocument(
    id: 'doc-ohada-audcg',
    title: 'Acte uniforme relatif au droit commercial général',
    type: LegalDocumentType.traite,
    domain: LegalDomain.ohada,
    reference: 'AUDCG révisé',
    datePublication: DateTime(2010, 12, 15),
    summary: "Harmonise le droit commercial des États membres de l'espace OHADA.",
    fullContent:
        'L\'Acte uniforme relatif au droit commercial général harmonise, au sein des États membres '
        'de l\'espace OHADA, le statut du commerçant et de l\'entreprenant, l\'organisation du '
        'Registre du commerce et du crédit mobilier, le bail commercial et le régime du fonds de '
        'commerce, ainsi que la vente commerciale et l\'intermédiation commerciale.\n\n'
        'Il institue un statut simplifié de l\'entreprenant, personne physique exerçant une '
        'activité professionnelle civile, commerciale, artisanale ou agricole sans être tenue à '
        'l\'ensemble des obligations comptables et fiscales du commerçant de droit commun.\n\n'
        'En cas de conflit avec une disposition nationale, l\'Acte uniforme, en tant que norme '
        'communautaire, prévaut sur les dispositions de droit interne contraires des États '
        'parties au Traité OHADA.',
    tags: const ['OHADA', 'commerce', 'entreprenant'],
  ),
  LegalDocument(
    id: 'doc-modele-bail-habitation',
    title: "Modèle de contrat de bail à usage d'habitation",
    type: LegalDocumentType.modeleActe,
    domain: LegalDomain.civil,
    reference: 'Modèle standard',
    datePublication: DateTime(2023, 1, 10),
    summary: "Trame prête à personnaliser pour un bail d'habitation.",
    fullContent:
        'Entre les soussignés, d\'une part le bailleur, propriétaire du bien désigné ci-après, et '
        'd\'autre part le preneur, il a été convenu et arrêté ce qui suit :\n\n'
        'Article 1 — Objet : le bailleur loue au preneur, qui accepte, le logement sis à '
        '[adresse], à usage exclusif d\'habitation.\n\n'
        'Article 2 — Durée : le présent bail est conclu pour une durée de [durée], renouvelable '
        'par tacite reconduction sauf congé donné par l\'une des parties dans les conditions et '
        'délais prévus par la loi.\n\n'
        'Article 3 — Loyer et charges : le loyer mensuel est fixé à [montant], payable d\'avance '
        'au plus tard le [jour] de chaque mois, majoré des charges locatives récupérables '
        'énumérées en annexe.\n\n'
        'Article 4 — Dépôt de garantie : un dépôt de garantie de [montant] est versé à la '
        'signature et restitué dans le délai légal après état des lieux de sortie, déduction '
        'faite des sommes justifiées restant dues.',
    tags: const ['bail', 'habitation', 'modèle'],
    relatedDocumentIds: const ['doc-code-civil'],
  ),
  LegalDocument(
    id: 'doc-modele-cdd',
    title: 'Modèle de contrat de travail à durée déterminée',
    type: LegalDocumentType.modeleActe,
    domain: LegalDomain.travail,
    reference: 'Modèle standard',
    datePublication: DateTime(2023, 3, 2),
    summary: 'Trame de contrat à durée déterminée conforme au Code du travail.',
    fullContent:
        'Entre l\'employeur, d\'une part, et le salarié, d\'autre part, il est conclu le présent '
        'contrat de travail à durée déterminée, dans les conditions suivantes :\n\n'
        'Article 1 — Motif du recours : le présent contrat est conclu pour [motif : remplacement, '
        'accroissement temporaire d\'activité, emploi saisonnier].\n\n'
        'Article 2 — Poste et durée : le salarié est engagé en qualité de [intitulé du poste] pour '
        'une durée de [durée], du [date de début] au [date de fin].\n\n'
        'Article 3 — Rémunération : le salarié perçoit une rémunération mensuelle brute de '
        '[montant], versée selon la périodicité en vigueur dans l\'entreprise.\n\n'
        'Article 4 — Fin du contrat : sauf rupture anticipée dans les cas prévus par la loi '
        '(faute grave, accord des parties, force majeure), le contrat prend fin de plein droit à '
        'l\'échéance du terme, sans indemnité autre que, le cas échéant, l\'indemnité de fin de '
        'contrat légalement due.',
    tags: const ['contrat de travail', 'CDD', 'modèle'],
    relatedDocumentIds: const ['doc-code-travail'],
  ),
];
