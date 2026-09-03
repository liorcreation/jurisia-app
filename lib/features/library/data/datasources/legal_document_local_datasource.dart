import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';

/// Frontière data vers la source des documents juridiques. Permet de
/// substituer une source distante (Supabase, alimentée par le pipeline
/// `tools/legal_import/`) à la base locale sans toucher au reste de
/// l'architecture. La base locale sert de **catalogue de repli hors-ligne**.
abstract class LegalDocumentDataSource {
  List<LegalDocument> getAll();
}

/// Catalogue local du droit burkinabè et de l'espace OHADA : Constitution,
/// principaux codes nationaux, Actes uniformes OHADA, lois, décrets,
/// arrêtés, jurisprudence de référence et modèles d'actes.
///
/// Chaque entrée porte des **métadonnées exactes** (intitulé, référence,
/// date, source faisant autorité) et un lien vers le texte officiel. Le
/// texte intégral article par article est renseigné progressivement par le
/// pipeline d'import (voir `tools/legal_import/RUNBOOK.md`) ; en attendant,
/// la fiche renvoie à la source officielle.
class LocalLegalDocumentDataSource implements LegalDocumentDataSource {
  const LocalLegalDocumentDataSource();

  @override
  List<LegalDocument> getAll() => _documents;
}

const _legiburkina = 'https://www.legiburkina.bf';
const _droitAfrique = 'https://www.droit-afrique.com/pays/burkina/';
const _ohadaTextes = 'https://www.ohada.org/index.php/fr/actes-uniformes';
const _jofb = 'https://www.legiburkina.bf'; // Journal Officiel diffusé via Légiburkina

/// Fabrique un code / grand texte national burkinabè.
LegalDocument _code({
  required String id,
  required String title,
  required LegalDomain domain,
  required String reference,
  required DateTime date,
  required String summary,
  required String overview,
  List<String> outline = const [],
  List<String> tags = const [],
  LegalDocumentType type = LegalDocumentType.code,
  LegalDocumentStatus status = LegalDocumentStatus.enVigueur,
  String source = _droitAfrique,
  String sourceName = 'Droit-Afrique',
  List<String> related = const [],
}) {
  return LegalDocument(
    id: id,
    title: title,
    type: type,
    domain: domain,
    reference: reference,
    datePublication: date,
    status: status,
    summary: summary,
    fullContent: overview,
    outline: outline,
    officialSourceName: sourceName,
    sourceUrl: source,
    tags: tags,
    relatedDocumentIds: related,
  );
}

/// Fabrique un Acte uniforme OHADA.
LegalDocument _ohada({
  required String id,
  required String title,
  required String reference,
  required DateTime date,
  required String summary,
  required String overview,
  List<String> outline = const [],
  List<String> tags = const [],
}) {
  return LegalDocument(
    id: id,
    title: title,
    type: LegalDocumentType.traite,
    domain: LegalDomain.ohada,
    reference: reference,
    datePublication: date,
    summary: summary,
    fullContent: overview,
    outline: outline,
    officialSourceName: 'OHADA',
    sourceUrl: _ohadaTextes,
    tags: ['OHADA', ...tags],
  );
}

final List<LegalDocument> _documents = [
  // ======================================================================
  //  FONDEMENTS
  // ======================================================================
  LegalDocument(
    id: 'doc-constitution',
    title: 'Constitution du Burkina Faso',
    type: LegalDocumentType.constitution,
    domain: LegalDomain.constitutionnel,
    reference: 'Constitution du 2 juin 1991, révisée',
    datePublication: DateTime(1991, 6, 2),
    status: LegalDocumentStatus.modifie,
    officialSourceName: 'Légiburkina',
    sourceUrl: _legiburkina,
    summary: 'Loi fondamentale : forme de l\'État, droits et devoirs, organisation des pouvoirs.',
    fullContent:
        'La Constitution est la norme suprême de l\'ordre juridique burkinabè. Elle proclame '
        'l\'attachement du peuple aux principes de la démocratie pluraliste, aux droits humains '
        'et à la justice sociale, et fixe la forme républicaine, unitaire, laïque et sociale de '
        'l\'État.\n\n'
        'Son titre premier consacre les droits et devoirs fondamentaux : égalité devant la loi, '
        'liberté d\'aller et venir, d\'opinion, de conscience et d\'expression, droit à un procès '
        'équitable et à la présomption d\'innocence, inviolabilité du domicile et de la '
        'correspondance, droit de propriété, droit au travail, à l\'éducation et à la santé.\n\n'
        'Les titres suivants organisent le pouvoir exécutif (Président du Faso, Gouvernement), le '
        'pouvoir législatif (Assemblée), le pouvoir judiciaire et son indépendance, le Conseil '
        'constitutionnel garant de la hiérarchie des normes, ainsi que la libre administration '
        'des collectivités territoriales. Toute loi, tout décret et tout arrêté doivent être '
        'conformes à la Constitution.',
    outline: const [
      'Préambule',
      'Titre I — Des droits et des devoirs fondamentaux',
      'Titre II — De l\'État et de la souveraineté',
      'Titre III — Du Président du Faso',
      'Titre IV — Du Gouvernement',
      'Titre V — Du pouvoir législatif',
      'Titre VI — Des rapports entre pouvoirs exécutif et législatif',
      'Titre VII — Du pouvoir judiciaire',
      'Titre VIII — Du Conseil constitutionnel',
      'Titre IX — De la Haute Cour de justice',
      'Titre X — Des collectivités territoriales',
      'Titre XI — De la révision',
    ],
    tags: const ['institutions', 'droits fondamentaux', 'séparation des pouvoirs'],
  ),

  // ======================================================================
  //  GRANDS CODES NATIONAUX
  // ======================================================================
  _code(
    id: 'doc-code-personnes-famille',
    title: 'Code des personnes et de la famille',
    domain: LegalDomain.famille,
    reference: 'Zatu n° AN VII-13 du 16 novembre 1989',
    date: DateTime(1989, 11, 16),
    status: LegalDocumentStatus.modifie,
    summary: 'État civil, mariage, filiation, autorité parentale, régimes matrimoniaux, successions.',
    overview:
        'Le Code des personnes et de la famille régit l\'identité et l\'état des personnes '
        '(nom, domicile, actes de l\'état civil, absence), le mariage et sa dissolution, les '
        'régimes matrimoniaux, la filiation et l\'adoption, l\'autorité parentale, la tutelle, '
        'les libéralités et les successions.\n\n'
        'Il pose le principe du mariage monogamique comme régime de droit commun, tout en '
        'admettant la polygamie sur option exprimée à la célébration. Il fixe l\'âge nubile, les '
        'empêchements à mariage, et organise le divorce (par consentement mutuel, pour faute ou '
        'pour rupture de la vie commune) ainsi que ses effets patrimoniaux et à l\'égard des '
        'enfants.',
    outline: const [
      'Livre I — Des personnes',
      'Livre II — De la famille',
      'Livre III — Des successions, libéralités et régimes matrimoniaux',
    ],
    tags: const ['famille', 'mariage', 'succession', 'état civil'],
    related: const ['doc-constitution'],
  ),
  _code(
    id: 'doc-code-civil',
    title: 'Code civil — obligations, contrats et biens',
    domain: LegalDomain.civil,
    reference: 'Dispositions civiles applicables (hors droit de la famille)',
    date: DateTime(1804, 3, 21),
    status: LegalDocumentStatus.modifie,
    summary: 'Droit des obligations, des contrats, de la responsabilité et des biens.',
    overview:
        'En matière d\'obligations, de contrats, de responsabilité civile et de biens, le droit '
        'burkinabè applique les dispositions du Code civil hérité, sous réserve des lois '
        'nationales postérieures (bail, sûretés relevant désormais de l\'OHADA, etc.).\n\n'
        'Le contrat se forme par la rencontre des volontés sur les éléments essentiels ; il '
        'oblige les parties à ce qui y est exprimé et à toutes les suites que l\'équité, l\'usage '
        'ou la loi lui donnent. L\'inexécution ouvre droit à l\'exécution forcée, à la résolution '
        'et à des dommages-intérêts. En matière délictuelle, tout fait de l\'homme qui cause à '
        'autrui un dommage oblige celui par la faute duquel il est arrivé à le réparer.',
    outline: const [
      'Titre III — Des contrats et des obligations conventionnelles',
      'Titre IV — Des engagements qui se forment sans convention (responsabilité)',
      'Titre — Des biens et des différentes modifications de la propriété',
      'Titre — Des privilèges et de la prescription',
    ],
    tags: const ['contrats', 'responsabilité civile', 'biens', 'prescription'],
    source: _droitAfrique,
    related: const ['doc-modele-bail-habitation', 'doc-jurisprudence-vente'],
  ),
  _code(
    id: 'doc-code-travail',
    title: 'Code du travail',
    domain: LegalDomain.travail,
    reference: 'Loi n° 028-2008/AN du 13 mai 2008',
    date: DateTime(2008, 5, 13),
    status: LegalDocumentStatus.modifie,
    summary: 'Relations individuelles et collectives de travail, durée, salaire, rupture, syndicats.',
    overview:
        'Le Code du travail s\'applique aux relations entre employeurs et travailleurs exerçant '
        'une activité professionnelle sous l\'autorité et moyennant rémunération. Il définit le '
        'contrat de travail (CDI, CDD, contrat de travail temporaire), ses conditions de '
        'formation, de suspension et de rupture, et les obligations réciproques des parties.\n\n'
        'Il fixe la durée légale du travail, les heures supplémentaires, les repos et congés '
        'payés, l\'hygiène et la sécurité, le salaire minimum interprofessionnel garanti (SMIG). '
        'La rupture du CDI à l\'initiative de l\'employeur doit reposer sur un motif légitime et '
        'respecter la procédure et le préavis, sauf faute lourde ; à défaut, le licenciement est '
        'abusif et ouvre droit à des dommages-intérêts. Le Code organise aussi le droit syndical, '
        'les délégués du personnel, la négociation collective et le règlement des différends.',
    outline: const [
      'Titre I — Dispositions générales',
      'Titre II — Du contrat de travail',
      'Titre III — Du salaire',
      'Titre IV — Des conditions de travail',
      'Titre V — De l\'hygiène, de la sécurité et de la santé au travail',
      'Titre VI — Des organisations professionnelles',
      'Titre VII — Des différends du travail',
      'Titre VIII — De l\'administration et du contrôle du travail',
    ],
    tags: const ['contrat de travail', 'licenciement', 'SMIG', 'syndicats'],
    related: const ['doc-jurisprudence-licenciement', 'doc-modele-cdd', 'doc-decret-application-travail', 'doc-code-securite-sociale'],
  ),
  _code(
    id: 'doc-code-penal',
    title: 'Code pénal',
    domain: LegalDomain.penal,
    reference: 'Loi n° 025-2018/AN du 31 mai 2018',
    date: DateTime(2018, 5, 31),
    status: LegalDocumentStatus.modifie,
    summary: 'Infractions, peines et responsabilité pénale.',
    overview:
        'Le Code pénal détermine les comportements érigés en infractions (contraventions, délits, '
        'crimes), les peines et mesures de sûreté encourues, et les règles de la responsabilité '
        'pénale : élément légal, matériel et moral, tentative, complicité, causes '
        'd\'irresponsabilité et d\'atténuation.\n\n'
        'Sa partie spéciale réprime notamment les atteintes aux personnes (homicide, violences, '
        'atteintes sexuelles, traite), aux biens (vol, escroquerie, abus de confiance, '
        'destruction), à la probité publique (corruption, détournement, concussion), à la sûreté '
        'de l\'État, ainsi que les infractions en matière de terrorisme, de cybercriminalité et '
        'de blanchiment.',
    outline: const [
      'Livre I — Dispositions générales',
      'Livre II — Des crimes et délits contre les personnes',
      'Livre III — Des crimes et délits contre les biens',
      'Livre IV — Des crimes et délits contre la chose publique',
      'Livre V — Des infractions contre la sûreté de l\'État',
      'Livre — Des contraventions',
    ],
    tags: const ['infractions', 'peines', 'responsabilité pénale'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
    related: const ['doc-code-procedure-penale'],
  ),
  _code(
    id: 'doc-code-procedure-penale',
    title: 'Code de procédure pénale',
    domain: LegalDomain.procedurePenale,
    reference: 'Loi n° 040-2019/AN du 29 mai 2019',
    date: DateTime(2019, 5, 29),
    status: LegalDocumentStatus.modifie,
    summary: 'Enquête, poursuite, instruction, jugement, voies de recours et exécution des peines.',
    overview:
        'Le Code de procédure pénale organise le déroulement du procès pénal : constatation des '
        'infractions et enquête (police judiciaire, garde à vue, perquisitions), exercice de '
        'l\'action publique par le ministère public, instruction préparatoire devant le juge '
        'd\'instruction, contrôle judiciaire et détention provisoire.\n\n'
        'Il fixe la compétence et la procédure des juridictions de jugement (tribunal '
        'correctionnel, chambre criminelle, juridictions pour mineurs), les droits de la défense '
        'et de la victime constituée partie civile, les voies de recours (appel, cassation, '
        'révision) et les modalités d\'exécution des peines.',
    outline: const [
      'Titre préliminaire — De l\'action publique et de l\'action civile',
      'Livre I — De la conduite de la politique pénale, de l\'enquête et de l\'instruction',
      'Livre II — Des juridictions de jugement',
      'Livre III — Des voies de recours extraordinaires',
      'Livre IV — De quelques procédures particulières',
      'Livre V — Des procédures d\'exécution',
    ],
    tags: const ['enquête', 'instruction', 'détention provisoire', 'jugement'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
    related: const ['doc-code-penal'],
  ),
  _code(
    id: 'doc-code-procedure-civile',
    title: 'Code de procédure civile',
    domain: LegalDomain.procedureCivile,
    reference: 'Loi n° 22-99/AN du 18 mai 1999, modifiée',
    date: DateTime(1999, 5, 18),
    status: LegalDocumentStatus.modifie,
    summary: 'Compétence des juridictions civiles, déroulement de l\'instance, jugements et recours.',
    overview:
        'Le Code de procédure civile régit le procès civil, commercial et social : compétence '
        'territoriale et d\'attribution des juridictions, saisine, représentation, mise en état, '
        'administration de la preuve, incidents d\'instance, et prononcé du jugement.\n\n'
        'Il organise les procédures rapides (référé, ordonnance sur requête, injonction de payer '
        'renvoyant pour partie à l\'Acte uniforme OHADA), les voies de recours (opposition, '
        'appel, pourvoi en cassation, tierce opposition, requête civile) et l\'exécution des '
        'décisions de justice.',
    outline: const [
      'Livre I — Dispositions communes à toutes les juridictions',
      'Livre II — Dispositions particulières à chaque juridiction',
      'Livre III — Les voies de recours',
      'Livre IV — L\'exécution des jugements et actes',
      'Livre V — Procédures diverses',
    ],
    tags: const ['compétence', 'référé', 'appel', 'exécution'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
    related: const ['doc-ohada-aupsrve'],
  ),
  _code(
    id: 'doc-code-commerce',
    title: 'Code de commerce',
    domain: LegalDomain.commercial,
    reference: 'Dispositions nationales + Actes uniformes OHADA',
    date: DateTime(2010, 12, 15),
    summary: 'Statut du commerçant, sociétés, fonds de commerce, ventes commerciales — largement OHADA.',
    overview:
        'Au Burkina Faso, le droit commercial est pour l\'essentiel régi par les Actes uniformes '
        'de l\'OHADA, directement applicables et primant sur les dispositions nationales '
        'contraires : droit commercial général (commerçant, entreprenant, RCCM, bail à usage '
        'professionnel, vente commerciale), sociétés commerciales et GIE, sûretés, procédures '
        'collectives, arbitrage, comptabilité.\n\n'
        'Des textes nationaux complètent ce socle : réglementation de la concurrence et des prix, '
        'code des investissements, statuts particuliers (transporteurs, professions '
        'réglementées), et fiscalité des entreprises prévue au Code général des impôts.',
    outline: const [
      'Socle OHADA — voir les Actes uniformes',
      'Concurrence, prix et pratiques commerciales',
      'Code des investissements',
      'Fiscalité des entreprises (Code général des impôts)',
    ],
    tags: const ['commerçant', 'sociétés', 'concurrence'],
    source: _ohadaTextes,
    sourceName: 'OHADA',
    related: const ['doc-ohada-audcg', 'doc-ohada-auscgie', 'doc-code-investissements'],
  ),
  _code(
    id: 'doc-code-impots',
    title: 'Code général des impôts',
    domain: LegalDomain.fiscal,
    reference: 'Loi n° 058-2017/AN du 20 décembre 2017, modifiée par les lois de finances',
    date: DateTime(2017, 12, 20),
    status: LegalDocumentStatus.modifie,
    summary: 'Impôts d\'État : sur les bénéfices, sur les revenus, TVA, droits d\'enregistrement, procédures.',
    overview:
        'Le Code général des impôts regroupe les impôts, taxes et droits perçus au profit du '
        'budget de l\'État : impôt sur les sociétés et sur les bénéfices industriels, commerciaux '
        'et agricoles, impôt unique sur les traitements et salaires, impôt sur le revenu des '
        'valeurs mobilières et des créances, taxe sur la valeur ajoutée, droits '
        'd\'enregistrement et de timbre, patente et contributions diverses.\n\n'
        'Il fixe l\'assiette, les taux, les obligations déclaratives et de paiement, ainsi que '
        'les procédures de contrôle, de redressement, de recouvrement forcé et de contentieux. '
        'Il est actualisé chaque année par la loi de finances.',
    outline: const [
      'Livre I — Impôts directs et taxes assimilées',
      'Livre II — Taxes sur le chiffre d\'affaires',
      'Livre III — Droits d\'enregistrement, de timbre et taxes assimilées',
      'Livre IV — Procédures fiscales (contrôle, recouvrement, contentieux)',
    ],
    tags: const ['fiscalité', 'TVA', 'impôt sur les sociétés', 'contrôle fiscal'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
  ),
  _code(
    id: 'doc-code-douanes',
    title: 'Code des douanes',
    domain: LegalDomain.fiscal,
    reference: 'Code des douanes en vigueur (Loi n° 03-92/ADP, modifiée)',
    date: DateTime(1992, 1, 6),
    status: LegalDocumentStatus.modifie,
    summary: 'Régime des marchandises à l\'importation et à l\'exportation, contentieux douanier.',
    overview:
        'Le Code des douanes fixe le cadre de l\'action de l\'administration des douanes : '
        'territoire douanier, régimes douaniers (mise à la consommation, entrepôt, admission '
        'temporaire, transit), valeur en douane, espèce et origine des marchandises, tarif des '
        'douanes et exonérations.\n\n'
        'Il organise les opérations de dédouanement, les pouvoirs de contrôle et de recherche des '
        'agents, ainsi que le contentieux douanier (infractions, transactions, sanctions '
        'fiscales et pénales). Il s\'articule avec le code des douanes de l\'UEMOA et le tarif '
        'extérieur commun.',
    outline: const [
      'Titre I — Principes généraux du régime des douanes',
      'Titre II — Conduite et mise en douane des marchandises',
      'Titre III — Régimes douaniers',
      'Titre IV — Opérations privilégiées et exonérations',
      'Titre V — Contentieux et recouvrement',
    ],
    tags: const ['import-export', 'tarif douanier', 'UEMOA', 'contentieux'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
  ),
  _code(
    id: 'doc-code-environnement',
    title: 'Code de l\'environnement',
    domain: LegalDomain.administratif,
    reference: 'Loi n° 006-2013/AN du 2 avril 2013',
    date: DateTime(2013, 4, 2),
    status: LegalDocumentStatus.modifie,
    summary: 'Gestion de l\'environnement, évaluations environnementales, pollutions et nuisances.',
    overview:
        'Le Code de l\'environnement pose les principes de précaution, de prévention, du '
        'pollueur-payeur et de participation du public. Il soumet les projets susceptibles '
        'd\'avoir un impact notable à une évaluation environnementale (étude ou notice d\'impact) '
        'préalable à toute autorisation.\n\n'
        'Il réglemente les installations classées, la gestion des déchets, la lutte contre les '
        'pollutions de l\'air, de l\'eau et des sols, les nuisances sonores, ainsi que la '
        'protection des espaces et des espèces. Les manquements exposent à des sanctions '
        'administratives et pénales et à l\'obligation de réparation.',
    outline: const [
      'Titre I — Dispositions générales et principes',
      'Titre II — De la planification environnementale',
      'Titre III — Des évaluations environnementales',
      'Titre IV — De la protection des milieux récepteurs',
      'Titre V — Des installations classées et des substances chimiques',
      'Titre VI — Des infractions et sanctions',
    ],
    tags: const ['environnement', 'étude d\'impact', 'pollution', 'installations classées'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
  ),
  _code(
    id: 'doc-code-minier',
    title: 'Code minier',
    domain: LegalDomain.administratif,
    reference: 'Loi n° 036-2015/CNT du 26 juin 2015',
    date: DateTime(2015, 6, 26),
    status: LegalDocumentStatus.modifie,
    summary: 'Titres miniers, régime des substances, obligations des sociétés minières, fonds miniers.',
    overview:
        'Le Code minier fixe le régime de la prospection, de la recherche et de l\'exploitation '
        'des substances minérales, propriété de l\'État. Il organise les titres et autorisations '
        '(autorisation de prospection, permis de recherche, permis d\'exploitation industrielle, '
        'semi-mécanisée et artisanale), leur octroi, leur durée et leur retrait.\n\n'
        'Il encadre les obligations des titulaires : cahier des charges, contenu local, emploi et '
        'formation, réhabilitation des sites, plan de fermeture, et contributions (Fonds minier '
        'de développement local, Fonds de réhabilitation et de fermeture des mines). Il fixe le '
        'régime fiscal et douanier minier et les droits des communautés riveraines.',
    outline: const [
      'Titre I — Dispositions générales',
      'Titre II — Des titres miniers et autorisations',
      'Titre III — Des droits et obligations',
      'Titre IV — Du régime fiscal et douanier',
      'Titre V — De la protection de l\'environnement et du développement local',
      'Titre VI — Du contrôle, des infractions et des sanctions',
    ],
    tags: const ['mines', 'or', 'contenu local', 'fonds miniers'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
  ),
  _code(
    id: 'doc-code-electoral',
    title: 'Code électoral',
    domain: LegalDomain.constitutionnel,
    reference: 'Loi n° 014-2001/AN du 3 juillet 2001, modifiée',
    date: DateTime(2001, 7, 3),
    status: LegalDocumentStatus.modifie,
    summary: 'Corps électoral, opérations de vote, candidatures, contentieux et financement.',
    overview:
        'Le Code électoral détermine les conditions de l\'électorat et de l\'éligibilité, la '
        'confection et la révision des listes électorales, la circonscription et le découpage, '
        'ainsi que le rôle de la Commission électorale nationale indépendante.\n\n'
        'Il fixe les règles communes aux différents scrutins (présidentiel, législatif, '
        'municipal), le déroulement de la campagne, du vote et du dépouillement, la proclamation '
        'des résultats et le contentieux électoral porté selon les cas devant le Conseil '
        'constitutionnel ou le Conseil d\'État.',
    outline: const [
      'Titre I — Dispositions communes à toutes les élections',
      'Titre II — De l\'élection du Président du Faso',
      'Titre III — De l\'élection des députés',
      'Titre IV — Des élections des conseillers de collectivités territoriales',
      'Titre V — Des dispositions pénales',
    ],
    tags: const ['élections', 'CENI', 'campagne', 'contentieux électoral'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
    related: const ['doc-constitution'],
  ),
  _code(
    id: 'doc-loi-foncier-rural',
    title: 'Loi portant régime foncier rural',
    domain: LegalDomain.foncier,
    reference: 'Loi n° 034-2009/AN du 16 juin 2009',
    date: DateTime(2009, 6, 16),
    type: LegalDocumentType.loi,
    status: LegalDocumentStatus.modifie,
    summary: 'Sécurisation des terres rurales : domaine, possession, chartes foncières locales.',
    overview:
        'La loi sur le foncier rural vise à sécuriser les droits fonciers de l\'ensemble des '
        'acteurs ruraux. Elle distingue le domaine foncier rural de l\'État, celui des '
        'collectivités territoriales et celui des particuliers, et reconnaît la possession '
        'foncière rurale coutumière comme mode d\'accès à la propriété, constatée par une '
        'attestation de possession foncière rurale.\n\n'
        'Elle institue les Services fonciers ruraux au niveau communal, les commissions '
        'foncières villageoises et les chartes foncières locales pour la gestion concertée des '
        'ressources partagées (pâturages, points d\'eau, pistes à bétail). Elle encadre les '
        'cessions, locations et prêts de terres rurales.',
    outline: const [
      'Titre I — Dispositions générales',
      'Titre II — Des domaines fonciers ruraux',
      'Titre III — De la gestion foncière locale',
      'Titre IV — De la constatation et de la sécurisation des droits',
      'Titre V — Du règlement des conflits fonciers ruraux',
    ],
    tags: const ['foncier rural', 'possession coutumière', 'APFR', 'charte foncière'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
    related: const ['doc-loi-raf'],
  ),
  _code(
    id: 'doc-loi-raf',
    title: 'Loi portant réorganisation agraire et foncière (RAF)',
    domain: LegalDomain.foncier,
    reference: 'Loi n° 034-2012/AN du 2 juillet 2012',
    date: DateTime(2012, 7, 2),
    type: LegalDocumentType.loi,
    status: LegalDocumentStatus.modifie,
    summary: 'Domaine foncier national, titres de jouissance et de propriété, aménagement du territoire.',
    overview:
        'La RAF définit le domaine foncier national, composé du domaine de l\'État, du domaine '
        'des collectivités territoriales et du patrimoine foncier des particuliers. Elle fixe les '
        'principes de l\'aménagement du territoire, de l\'urbanisme opérationnel et de la '
        'viabilisation des terres.\n\n'
        'Elle organise les modes d\'accès à la terre (attribution, cession, bail emphytéotique, '
        'permis urbain d\'habiter, titre foncier), la procédure d\'immatriculation, la purge des '
        'droits coutumiers en zone aménagée, l\'expropriation pour cause d\'utilité publique et '
        'l\'indemnisation.',
    outline: const [
      'Titre I — Du domaine foncier national',
      'Titre II — De la gestion du domaine foncier national',
      'Titre III — De l\'aménagement du territoire',
      'Titre IV — De l\'urbanisme et de la construction',
      'Titre V — De l\'expropriation pour cause d\'utilité publique',
    ],
    tags: const ['foncier', 'titre foncier', 'expropriation', 'aménagement'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
    related: const ['doc-loi-foncier-rural'],
  ),
  _code(
    id: 'doc-code-securite-sociale',
    title: 'Code de la sécurité sociale',
    domain: LegalDomain.travail,
    reference: 'Loi n° 015-2006/AN du 11 mai 2006',
    date: DateTime(2006, 5, 11),
    status: LegalDocumentStatus.modifie,
    summary: 'Régime des travailleurs salariés : prestations familiales, risques professionnels, pensions.',
    overview:
        'Le Code de la sécurité sociale institue, au bénéfice des travailleurs salariés et '
        'assimilés, une protection contre les principaux risques sociaux, gérée par la Caisse '
        'nationale de sécurité sociale (CNSS).\n\n'
        'Il couvre trois branches : les prestations familiales (allocations prénatales et '
        'familiales, indemnité de congé de maternité), la réparation et la prévention des '
        'accidents du travail et des maladies professionnelles, et l\'assurance vieillesse, '
        'invalidité et décès (pensions de retraite, de survivant, allocation de solidarité). Il '
        'fixe l\'assiette et le taux des cotisations et les obligations déclaratives de '
        'l\'employeur.',
    outline: const [
      'Titre I — Dispositions générales et champ d\'application',
      'Titre II — Des prestations familiales',
      'Titre III — De la réparation des risques professionnels',
      'Titre IV — De l\'assurance vieillesse, invalidité et décès',
      'Titre V — Des ressources et du recouvrement',
      'Titre VI — Du contentieux et des sanctions',
    ],
    tags: const ['CNSS', 'retraite', 'accident du travail', 'prestations familiales'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
    related: const ['doc-code-travail'],
  ),
  _code(
    id: 'doc-code-investissements',
    title: 'Code des investissements',
    domain: LegalDomain.commercial,
    reference: 'Loi n° 038-2018/AN du 30 octobre 2018',
    date: DateTime(2018, 10, 30),
    type: LegalDocumentType.loi,
    status: LegalDocumentStatus.modifie,
    summary: 'Garanties et avantages accordés aux investissements réalisés au Burkina Faso.',
    overview:
        'Le Code des investissements fixe les conditions générales d\'investissement et les '
        'garanties accordées aux investisseurs : liberté d\'entreprendre, égalité de traitement, '
        'protection de la propriété, libre transfert des revenus et des capitaux, accès aux '
        'devises.\n\n'
        'Il institue des régimes privilégiés selon le montant de l\'investissement et le nombre '
        'd\'emplois créés, ouvrant droit à des exonérations douanières et fiscales temporaires '
        'pendant les phases d\'investissement et d\'exploitation, ainsi qu\'à des avantages '
        'renforcés pour les zones économiques prioritaires et les secteurs stratégiques.',
    outline: const [
      'Titre I — Dispositions générales',
      'Titre II — Des garanties accordées aux investisseurs',
      'Titre III — Des régimes privilégiés et avantages',
      'Titre IV — De la procédure d\'agrément',
      'Titre V — Des obligations et du retrait des avantages',
    ],
    tags: const ['investissement', 'exonérations', 'agrément', 'emplois'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
  ),
  _code(
    id: 'doc-cgct',
    title: 'Code général des collectivités territoriales',
    domain: LegalDomain.administratif,
    reference: 'Loi n° 055-2004/AN du 21 décembre 2004, modifiée',
    date: DateTime(2004, 12, 21),
    status: LegalDocumentStatus.modifie,
    summary: 'Régions et communes : organisation, compétences, finances locales et tutelle.',
    overview:
        'Le Code général des collectivités territoriales met en œuvre la décentralisation. Il '
        'érige la région et la commune (urbaine ou rurale) en collectivités territoriales dotées '
        'de la personnalité juridique et de l\'autonomie financière, administrées par des '
        'conseils élus.\n\n'
        'Il répartit les compétences entre l\'État et les collectivités (domaine et foncier, '
        'aménagement, environnement, santé et éducation de base, culture, eau et '
        'assainissement), organise les organes délibérants et exécutifs locaux, le régime des '
        'actes et le contrôle de légalité, ainsi que les finances locales (budget, fiscalité '
        'propre, dotations).',
    outline: const [
      'Livre I — De l\'organisation territoriale et de la décentralisation',
      'Livre II — De la région',
      'Livre III — De la commune',
      'Livre IV — Du régime financier des collectivités territoriales',
      'Livre V — Des dispositions communes et de la coopération',
    ],
    tags: const ['décentralisation', 'commune', 'région', 'finances locales'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
  ),
  _code(
    id: 'doc-loi-presse',
    title: 'Loi portant régime juridique de la presse écrite',
    domain: LegalDomain.administratif,
    reference: 'Loi n° 057-2015/CNT du 4 septembre 2015',
    date: DateTime(2015, 9, 4),
    type: LegalDocumentType.loi,
    status: LegalDocumentStatus.modifie,
    summary: 'Liberté de la presse écrite, entreprises de presse, responsabilité et déontologie.',
    overview:
        'Cette loi consacre la liberté de la presse écrite et fixe le régime des publications, '
        'des entreprises éditrices et des journalistes (carte de presse, statut, clause de '
        'conscience). Elle soumet la création d\'un organe de presse à une simple déclaration.\n\n'
        'Elle définit les infractions de presse (diffamation, injure, fausse nouvelle, offense) '
        'et le régime de la responsabilité en cascade, encadre le droit de réponse et de '
        'rectification, et articule ses dispositions avec celles du Conseil supérieur de la '
        'communication. La dépénalisation partielle a substitué des sanctions pécuniaires à '
        'l\'emprisonnement pour la plupart des délits de presse.',
    outline: const [
      'Titre I — Dispositions générales',
      'Titre II — De l\'entreprise de presse et de la publication',
      'Titre III — Du journaliste professionnel',
      'Titre IV — De la responsabilité et des infractions',
      'Titre V — Du droit de réponse et de rectification',
    ],
    tags: const ['liberté de la presse', 'diffamation', 'droit de réponse', 'journaliste'],
    source: _legiburkina,
    sourceName: 'Légiburkina',
  ),

  // ======================================================================
  //  OHADA — ACTES UNIFORMES
  // ======================================================================
  _ohada(
    id: 'doc-ohada-audcg',
    title: 'Acte uniforme relatif au droit commercial général',
    reference: 'AUDCG révisé, adopté le 15 décembre 2010 (Lomé)',
    date: DateTime(2010, 12, 15),
    summary: 'Commerçant, entreprenant, RCCM, bail à usage professionnel, fonds de commerce, vente commerciale.',
    overview:
        'L\'Acte uniforme relatif au droit commercial général harmonise, dans les 17 États '
        'parties, le statut du commerçant et de l\'entreprenant (personne exerçant une activité '
        'professionnelle sans les obligations complètes du commerçant), l\'organisation et les '
        'effets du Registre du commerce et du crédit mobilier (RCCM), le bail à usage '
        'professionnel, le fonds de commerce et sa cession, ainsi que l\'intermédiation '
        'commerciale (commissionnaire, courtier, agent commercial).\n\n'
        'Il consacre un régime détaillé de la vente commerciale entre professionnels : formation '
        'du contrat, obligations de livraison et de conformité, transfert des risques, moyens en '
        'cas d\'inexécution et prescription. En cas de conflit, il prime sur le droit national '
        'contraire.',
    outline: const [
      'Livre I — Statut du commerçant et de l\'entreprenant',
      'Livre II — Registre du commerce et du crédit mobilier',
      'Livre III — Fichier national et fichier régional',
      'Livre IV — Bail à usage professionnel et fonds de commerce',
      'Livre V — Intermédiaires de commerce',
      'Livre VI — Vente commerciale',
    ],
    tags: const ['commerçant', 'entreprenant', 'RCCM', 'vente commerciale'],
  ),
  _ohada(
    id: 'doc-ohada-auscgie',
    title: 'Acte uniforme relatif au droit des sociétés commerciales et du GIE',
    reference: 'AUSCGIE révisé, adopté le 30 janvier 2014 (Ouagadougou)',
    date: DateTime(2014, 1, 30),
    summary: 'Constitution, fonctionnement et dissolution des sociétés commerciales ; SA, SAS, SARL, SNC, SCS, GIE.',
    overview:
        'L\'AUSCGIE régit toutes les sociétés commerciales et les groupements d\'intérêt '
        'économique dont le siège est situé dans un État partie : règles communes de '
        'constitution (statuts, apports, capital, immatriculation), de fonctionnement (organes '
        'de direction et de contrôle, assemblées, commissaire aux comptes), de transformation, '
        'de fusion et de dissolution-liquidation.\n\n'
        'Il détaille chaque forme sociale — société anonyme (avec ou sans conseil '
        'd\'administration), société par actions simplifiée, SARL, société en nom collectif, '
        'société en commandite simple, société en participation, société de fait — et organise '
        'les valeurs mobilières, l\'appel public à l\'épargne et les conventions réglementées.',
    outline: const [
      'Partie 1 — Dispositions générales sur la société commerciale',
      'Partie 2 — Dispositions particulières aux sociétés commerciales',
      'Partie 3 — Dispositions pénales',
      'Partie 4 — Groupement d\'intérêt économique',
      'Partie 5 — Dispositions transitoires et finales',
    ],
    tags: const ['sociétés', 'SA', 'SAS', 'SARL', 'GIE'],
  ),
  _ohada(
    id: 'doc-ohada-aus',
    title: 'Acte uniforme portant organisation des sûretés',
    reference: 'AUS révisé, adopté le 15 décembre 2010 (Lomé)',
    date: DateTime(2010, 12, 15),
    summary: 'Sûretés personnelles (cautionnement, garantie autonome) et réelles (gage, nantissement, hypothèque).',
    overview:
        'L\'Acte uniforme portant organisation des sûretés fixe le régime des garanties du '
        'crédit dans l\'espace OHADA. Il introduit l\'agent des sûretés et organise les sûretés '
        'personnelles : le cautionnement (accessoire à la dette garantie) et la garantie '
        'autonome (indépendante du contrat de base).\n\n'
        'Il régit les sûretés mobilières (droit de rétention, propriété-sûreté par réserve de '
        'propriété ou cession de créance à titre de garantie, gage de meubles corporels, '
        'nantissement de meubles incorporels, privilèges) et l\'hypothèque, en articulant leur '
        'opposabilité avec l\'inscription au RCCM, ainsi que leur réalisation et leur classement '
        'en cas de concours.',
    outline: const [
      'Titre I — Dispositions générales',
      'Titre II — Les sûretés personnelles',
      'Titre III — Les sûretés mobilières',
      'Titre IV — Les hypothèques',
      'Titre V — Distribution et classement des sûretés',
    ],
    tags: const ['cautionnement', 'gage', 'nantissement', 'hypothèque'],
  ),
  _ohada(
    id: 'doc-ohada-aupsrve',
    title: 'Acte uniforme sur les procédures simplifiées de recouvrement et les voies d\'exécution',
    reference: 'AUPSRVE, adopté le 10 avril 1998 (Libreville)',
    date: DateTime(1998, 4, 10),
    summary: 'Injonction de payer, injonction de délivrer, saisies conservatoires et saisies-exécutions.',
    overview:
        'L\'AUPSRVE offre au créancier des procédures rapides d\'obtention d\'un titre : '
        'l\'injonction de payer pour les créances certaines, liquides et exigibles d\'origine '
        'contractuelle ou cambiaire, et l\'injonction de délivrer ou de restituer un bien '
        'meuble déterminé.\n\n'
        'Il unifie l\'ensemble des voies d\'exécution : saisies conservatoires (de créances, de '
        'droits d\'associés, de biens meubles corporels), saisie-attribution de créances, '
        'saisie-vente, saisie des rémunérations, saisie-appréhension et saisie immobilière. Il '
        'fixe les biens et rémunérations insaisissables et le rôle du juge de l\'exécution.',
    outline: const [
      'Livre I — Les procédures simplifiées de recouvrement',
      'Livre II — Les voies d\'exécution',
      'Dispositions finales',
    ],
    tags: const ['injonction de payer', 'saisie', 'recouvrement', 'exécution'],
  ),
  _ohada(
    id: 'doc-ohada-aupc',
    title: 'Acte uniforme portant organisation des procédures collectives d\'apurement du passif',
    reference: 'AUPC révisé, adopté le 10 septembre 2015 (Grand-Bassam)',
    date: DateTime(2015, 9, 10),
    summary: 'Conciliation, règlement préventif, redressement judiciaire et liquidation des biens.',
    overview:
        'L\'AUPC organise le traitement des entreprises en difficulté selon la gravité de la '
        'situation : la conciliation (confidentielle, pour un accord amiable), le règlement '
        'préventif (avant la cessation des paiements, avec concordat préventif), le redressement '
        'judiciaire (après la cessation des paiements, si le redressement est possible) et la '
        'liquidation des biens (dans le cas contraire).\n\n'
        'Il institue une procédure simplifiée pour les petites entreprises, définit les organes '
        '(juge-commissaire, syndic, contrôleurs), les effets de l\'ouverture sur les contrats, '
        'les poursuites et les sûretés, la période suspecte et les nullités, et organise les '
        'sanctions patrimoniales et pénales des dirigeants.',
    outline: const [
      'Titre I — Dispositions préliminaires',
      'Titre II — La conciliation',
      'Titre III — Le règlement préventif',
      'Titre IV — Le redressement judiciaire et la liquidation des biens',
      'Titre V — Les sanctions',
      'Titre VI — Les voies de recours et la procédure',
    ],
    tags: const ['entreprises en difficulté', 'redressement', 'liquidation', 'concordat'],
  ),
  _ohada(
    id: 'doc-ohada-auda',
    title: 'Acte uniforme relatif au droit de l\'arbitrage',
    reference: 'AUDA révisé, adopté le 23 novembre 2017 (Conakry)',
    date: DateTime(2017, 11, 23),
    summary: 'Convention d\'arbitrage, tribunal arbitral, instance, sentence et recours.',
    overview:
        'L\'AUDA constitue le droit commun de l\'arbitrage dans l\'espace OHADA. Il fixe les '
        'conditions de validité de la convention d\'arbitrage (autonomie de la clause '
        'compromissoire, arbitrabilité), la constitution et les pouvoirs du tribunal arbitral, '
        'et le déroulement de l\'instance dans le respect du contradictoire et de l\'égalité des '
        'parties.\n\n'
        'Il précise le régime de la sentence (délibéré, forme, autorité de chose jugée), les '
        'voies de recours (recours en annulation devant le juge étatique compétent, tierce '
        'opposition, révision), ainsi que la reconnaissance et l\'exécution des sentences, '
        'l\'exequatur relevant, pour l\'arbitrage institutionnel CCJA, de la Cour commune de '
        'justice et d\'arbitrage.',
    outline: const [
      'Chapitre I — Champ d\'application',
      'Chapitre II — Composition du tribunal arbitral',
      'Chapitre III — Instance arbitrale',
      'Chapitre IV — Sentence arbitrale',
      'Chapitre V — Recours contre la sentence',
      'Chapitre VI — Reconnaissance et exécution des sentences',
    ],
    tags: const ['arbitrage', 'clause compromissoire', 'sentence', 'exequatur'],
  ),
  _ohada(
    id: 'doc-ohada-audcif',
    title: 'Acte uniforme relatif au droit comptable et à l\'information financière (SYSCOHADA)',
    reference: 'AUDCIF, adopté le 26 janvier 2017 (Brazzaville)',
    date: DateTime(2017, 1, 26),
    summary: 'Système comptable OHADA révisé : comptes personnels et comptes consolidés / combinés.',
    overview:
        'L\'AUDCIF et le SYSCOHADA révisé fixent les règles d\'établissement et de présentation '
        'des états financiers des entités du secteur privé. Ils imposent la tenue d\'une '
        'comptabilité régulière et sincère donnant une image fidèle du patrimoine, de la '
        'situation financière et du résultat.\n\n'
        'Ils définissent le plan comptable général, les méthodes d\'évaluation (coût historique, '
        'principe de prudence, permanence des méthodes), le contenu du bilan, du compte de '
        'résultat, du tableau des flux de trésorerie et de l\'état annexé, ainsi que les règles '
        'de consolidation et de combinaison des comptes de groupe. L\'application des normes '
        'IFRS est prévue pour les comptes consolidés des entités cotées ou faisant appel public '
        'à l\'épargne.',
    outline: const [
      'Chapitre I — Champ d\'application et principes comptables',
      'Chapitre II — Organisation comptable',
      'Chapitre III — États financiers annuels',
      'Chapitre IV — Comptes consolidés et comptes combinés',
      'Chapitre V — Dispositions pénales',
    ],
    tags: const ['comptabilité', 'SYSCOHADA', 'états financiers', 'consolidation'],
  ),
  _ohada(
    id: 'doc-ohada-auctmr',
    title: 'Acte uniforme relatif aux contrats de transport de marchandises par route',
    reference: 'AUCTMR, adopté le 22 mars 2003 (Yaoundé)',
    date: DateTime(2003, 3, 22),
    summary: 'Contrat de transport routier de marchandises : lettre de voiture, responsabilité, litiges.',
    overview:
        'L\'AUCTMR s\'applique à tout contrat de transport de marchandises par route lorsque le '
        'lieu de prise en charge et le lieu de livraison sont situés dans deux États différents '
        'dont l\'un au moins est partie, ou dans un même État partie.\n\n'
        'Il régit la conclusion et l\'exécution du contrat, la lettre de voiture, les droits et '
        'obligations de l\'expéditeur, du transporteur et du destinataire, l\'empêchement au '
        'transport et à la livraison, ainsi que la responsabilité du transporteur pour perte, '
        'avarie ou retard, ses causes d\'exonération, les limites d\'indemnisation, les délais '
        'de réclamation et la prescription des actions.',
    outline: const [
      'Chapitre I — Champ d\'application et définitions',
      'Chapitre II — Contrat et documents de transport',
      'Chapitre III — Exécution du contrat de transport',
      'Chapitre IV — Responsabilité du transporteur',
      'Chapitre V — Contentieux',
    ],
    tags: const ['transport routier', 'lettre de voiture', 'responsabilité', 'avarie'],
  ),
  _ohada(
    id: 'doc-ohada-coop',
    title: 'Acte uniforme relatif au droit des sociétés coopératives',
    reference: 'AUSCOOP, adopté le 15 décembre 2010 (Lomé)',
    date: DateTime(2010, 12, 15),
    summary: 'Société coopérative simplifiée et avec conseil d\'administration ; unions, fédérations, confédérations.',
    overview:
        'L\'Acte uniforme relatif au droit des sociétés coopératives dote l\'espace OHADA d\'un '
        'cadre commun pour les coopératives, groupements de personnes poursuivant un but '
        'commun de développement économique et social, fondés sur les principes coopératifs '
        '(adhésion volontaire, gestion démocratique « une personne, une voix », participation '
        'économique des membres).\n\n'
        'Il organise deux formes — la société coopérative simplifiée et la société coopérative '
        'avec conseil d\'administration —, leur constitution et immatriculation au registre des '
        'sociétés coopératives, leurs organes, le régime des parts sociales, les excédents et '
        'leur affectation, ainsi que les unions, fédérations et confédérations de coopératives.',
    outline: const [
      'Partie 1 — Dispositions communes à toutes les sociétés coopératives',
      'Partie 2 — Dispositions particulières aux différentes formes',
      'Partie 3 — Unions, fédérations et confédérations',
      'Partie 4 — Dispositions pénales',
      'Partie 5 — Dispositions diverses, transitoires et finales',
    ],
    tags: const ['coopérative', 'mutualité', 'économie sociale'],
  ),
  _ohada(
    id: 'doc-ohada-mediation',
    title: 'Acte uniforme relatif à la médiation',
    reference: 'AUM, adopté le 23 novembre 2017 (Conakry)',
    date: DateTime(2017, 11, 23),
    summary: 'Cadre de la médiation conventionnelle et judiciaire ; accord de médiation et son exécution.',
    overview:
        'L\'Acte uniforme relatif à la médiation encadre le processus par lequel les parties '
        'demandent à un tiers, le médiateur, de les aider à parvenir à un règlement amiable de '
        'leur différend, qu\'il soit contractuel ou non. La médiation peut être engagée par '
        'convention, sur invitation d\'une juridiction ou d\'un arbitre, ou en vertu d\'une '
        'obligation légale.\n\n'
        'Il pose la confidentialité de la procédure, l\'impartialité et l\'indépendance du '
        'médiateur, la suspension des délais de prescription pendant la médiation, et donne à '
        'l\'accord de médiation force obligatoire entre les parties. Cet accord peut être rendu '
        'exécutoire par le dépôt au rang des minutes d\'un notaire ou par homologation '
        'judiciaire.',
    outline: const [
      'Article 1 — Champ d\'application',
      'Articles 2 à 4 — Définitions et principes',
      'Articles 5 à 9 — Déroulement de la médiation',
      'Articles 10 à 15 — Fin de la médiation et confidentialité',
      'Articles 16 à 17 — Accord issu de la médiation et exécution',
    ],
    tags: const ['médiation', 'règlement amiable', 'confidentialité'],
  ),

  // ======================================================================
  //  LOIS, DÉCRETS ET ARRÊTÉS (SÉLECTION)
  // ======================================================================
  LegalDocument(
    id: 'doc-loi-bail-professionnel',
    title: 'Loi relative au bail à usage professionnel',
    type: LegalDocumentType.loi,
    domain: LegalDomain.commercial,
    reference: 'Loi n° 2016-234',
    datePublication: DateTime(2016, 6, 21),
    officialSourceName: 'Légiburkina',
    sourceUrl: _legiburkina,
    summary: 'Encadre les rapports entre bailleurs et preneurs à usage commercial (complément à l\'AUDCG).',
    fullContent:
        'Cette loi complète, au plan national, le régime OHADA du bail à usage professionnel. '
        'Elle porte sur les locaux à usage commercial, industriel ou artisanal, fixe une durée '
        'minimale et les conditions de renouvellement, et consacre le droit du preneur à une '
        'indemnité d\'éviction en cas de refus de renouvellement non justifié par un motif grave '
        'et légitime.\n\n'
        'Le loyer est révisable selon une périodicité encadrée ; toute clause manifestement '
        'abusive au détriment du preneur peut être réputée non écrite par le juge. La cession du '
        'droit au bail et la sous-location restent, sauf stipulation contraire, subordonnées à '
        'l\'accord préalable du bailleur.',
    tags: const ['bail', 'commerce', 'indemnité d\'éviction'],
    relatedDocumentIds: const ['doc-ohada-audcg'],
  ),
  LegalDocument(
    id: 'doc-loi-donnees-personnelles',
    title: 'Loi portant protection des données à caractère personnel',
    type: LegalDocumentType.loi,
    domain: LegalDomain.administratif,
    reference: 'Loi n° 001-2021/AN du 30 mars 2021',
    datePublication: DateTime(2021, 3, 30),
    status: LegalDocumentStatus.modifie,
    officialSourceName: 'Légiburkina',
    sourceUrl: _legiburkina,
    summary: 'Encadre la collecte et le traitement des données personnelles ; rôle de la CIL.',
    fullContent:
        'Cette loi soumet tout traitement de données à caractère personnel au respect des '
        'principes de licéité, de finalité déterminée, de proportionnalité, d\'exactitude, de '
        'durée de conservation limitée et de sécurité. Le responsable du traitement informe les '
        'personnes concernées, recueille leur consentement lorsqu\'il est requis, et leur '
        'garantit un droit d\'accès, de rectification, d\'opposition et d\'effacement.\n\n'
        'Les traitements sensibles (santé, origine, opinions, données biométriques) et les '
        'transferts hors du territoire national relèvent d\'un régime renforcé, sous le contrôle '
        'de la Commission de l\'informatique et des libertés (CIL). Le non-respect des '
        'obligations expose à des sanctions administratives et pénales.',
    tags: const ['données personnelles', 'vie privée', 'CIL'],
  ),
  LegalDocument(
    id: 'doc-decret-application-travail',
    title: "Décret d'application relatif à la durée du travail",
    type: LegalDocumentType.decret,
    domain: LegalDomain.travail,
    reference: 'Décret n° 2020-118',
    datePublication: DateTime(2020, 2, 3),
    dateEntreeEnVigueur: DateTime(2020, 5, 1),
    officialSourceName: 'Légiburkina',
    sourceUrl: _legiburkina,
    summary: 'Modalités d\'application des dispositions du Code du travail sur la durée légale du travail.',
    fullContent:
        'Le présent décret précise les modalités d\'application des dispositions légales '
        'relatives à la durée du travail. Il fixe la durée hebdomadaire de référence, les '
        'conditions de recours aux heures supplémentaires et leur taux de majoration, ainsi que '
        'les dérogations possibles par voie de convention collective.\n\n'
        'Il détaille les régimes particuliers applicables au travail de nuit, au travail posté '
        'et aux astreintes, ainsi que les registres et affichages obligatoires que l\'employeur '
        'doit tenir à disposition de l\'inspection du travail.',
    tags: const ['durée du travail', 'heures supplémentaires'],
    relatedDocumentIds: const ['doc-code-travail'],
  ),
  LegalDocument(
    id: 'doc-arrete-smig',
    title: 'Arrêté fixant le salaire minimum interprofessionnel garanti',
    type: LegalDocumentType.arrete,
    domain: LegalDomain.travail,
    reference: 'Arrêté n° 2024-045/MTFP',
    datePublication: DateTime(2024, 1, 15),
    officialSourceName: 'Journal Officiel du Faso',
    sourceUrl: _jofb,
    summary: 'Fixe le montant du salaire minimum interprofessionnel garanti (SMIG).',
    fullContent:
        'Le présent arrêté fixe le montant du salaire minimum interprofessionnel garanti '
        'applicable à l\'ensemble des secteurs d\'activité, à l\'exception des régimes '
        'particuliers prévus par convention collective étendue.\n\n'
        'Ce montant s\'entend pour une durée de travail hebdomadaire à temps plein telle que '
        'fixée par le Code du travail et ses textes d\'application. Il est révisé périodiquement '
        'en fonction de l\'évolution du coût de la vie, sur proposition de la commission '
        'nationale consultative du travail.',
    tags: const ['salaire minimum', 'SMIG'],
    relatedDocumentIds: const ['doc-code-travail'],
  ),

  // ======================================================================
  //  JURISPRUDENCE DE RÉFÉRENCE
  // ======================================================================
  LegalDocument(
    id: 'doc-jurisprudence-licenciement',
    title: 'Arrêt sur la rupture abusive du contrat de travail',
    type: LegalDocumentType.jurisprudence,
    domain: LegalDomain.travail,
    reference: 'Cass. soc., n° 245/2021',
    datePublication: DateTime(2021, 9, 14),
    summary: "Critères d'appréciation du caractère abusif d'un licenciement pour motif personnel.",
    fullContent:
        'La Cour rappelle que le licenciement pour motif personnel doit reposer sur une cause '
        'réelle et sérieuse, objectivement vérifiable et étrangère à toute discrimination. '
        'L\'employeur qui invoque une insuffisance professionnelle doit en établir la réalité '
        'par des éléments précis et concordants, et non par de simples appréciations générales.\n\n'
        'En l\'espèce, l\'absence de tout entretien préalable formalisé et de mise en demeure '
        'antérieure prive l\'employeur de la possibilité de démontrer que le salarié avait été '
        'informé des griefs et mis en mesure d\'y remédier. Le licenciement est déclaré sans '
        'cause réelle et sérieuse, et donne lieu à des dommages-intérêts proportionnés à '
        'l\'ancienneté du salarié et au préjudice subi.',
    tags: const ['licenciement', 'préavis', 'cause réelle et sérieuse'],
    relatedDocumentIds: const ['doc-code-travail'],
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
        'La Cour retient que l\'inexécution d\'une obligation essentielle du contrat de vente — '
        'en l\'espèce, le défaut de livraison de la chose vendue dans le délai convenu — '
        'justifie la résolution du contrat aux torts du vendeur, sans que l\'acheteur ait à '
        'établir un préjudice distinct du seul défaut de délivrance.\n\n'
        'La résolution emporte restitution réciproque des prestations déjà exécutées : le '
        'vendeur restitue le prix perçu, l\'acheteur restitue la chose s\'il l\'a reçue. Des '
        'dommages-intérêts complémentaires peuvent être alloués si l\'acheteur établit un '
        'préjudice supplémentaire directement lié au retard ou au défaut de livraison.',
    tags: const ['vente', 'résolution du contrat', 'inexécution'],
    relatedDocumentIds: const ['doc-code-civil'],
  ),

  // ======================================================================
  //  MODÈLES D'ACTES (texte structuré article par article)
  // ======================================================================
  LegalDocument(
    id: 'doc-modele-bail-habitation',
    title: "Modèle de contrat de bail à usage d'habitation",
    type: LegalDocumentType.modeleActe,
    domain: LegalDomain.civil,
    reference: 'Trame JurisIA — à personnaliser',
    datePublication: DateTime(2024, 1, 10),
    summary: "Trame prête à personnaliser pour un bail d'habitation, à adapter à votre situation.",
    officialSourceName: 'JurisIA',
    fullContent: '',
    outline: const ['Contrat de bail à usage d\'habitation'],
    articles: const [
      LegalArticle(
        number: '1',
        heading: 'Objet du contrat',
        text: 'Le bailleur donne à bail au preneur, qui accepte, le logement situé à [adresse '
            'complète], composé de [description : nombre de pièces, dépendances, équipements], à '
            'usage exclusif d\'habitation. Le preneur ne pourra changer cette destination sans '
            'l\'accord écrit du bailleur.',
      ),
      LegalArticle(
        number: '2',
        heading: 'Durée',
        text: 'Le présent bail est consenti pour une durée de [durée], à compter du [date de '
            'prise d\'effet]. Il se renouvelle ensuite par tacite reconduction pour des périodes '
            'de même durée, sauf congé donné par l\'une des parties par écrit, moyennant un '
            'préavis de [délai] et dans les formes prévues par la loi.',
      ),
      LegalArticle(
        number: '3',
        heading: 'Loyer et charges',
        text: 'Le loyer mensuel est fixé à [montant en chiffres et en lettres] F CFA, payable '
            'd\'avance au plus tard le [jour] de chaque mois, au domicile du bailleur ou par '
            'virement sur le compte [références]. À ce loyer s\'ajoutent les charges locatives '
            'récupérables énumérées en annexe. La révision du loyer, le cas échéant, intervient '
            'selon la périodicité et les modalités prévues par la loi.',
      ),
      LegalArticle(
        number: '4',
        heading: 'Dépôt de garantie',
        text: 'À la signature des présentes, le preneur verse au bailleur un dépôt de garantie '
            'de [montant] F CFA, non productif d\'intérêts. Ce dépôt est restitué dans le délai '
            'légal après la remise des clés et l\'établissement de l\'état des lieux de sortie, '
            'déduction faite des sommes restant dues et du coût, justifié, des réparations '
            'locatives non effectuées.',
      ),
      LegalArticle(
        number: '5',
        heading: 'État des lieux',
        text: 'Un état des lieux contradictoire est établi et signé par les parties lors de la '
            'remise des clés et lors de leur restitution. À défaut d\'état des lieux d\'entrée, '
            'le preneur est présumé avoir reçu le logement en bon état de réparations locatives.',
      ),
      LegalArticle(
        number: '6',
        heading: 'Obligations du bailleur',
        text: 'Le bailleur s\'oblige à délivrer un logement décent et en bon état d\'usage, à '
            'assurer au preneur la jouissance paisible des lieux, à entretenir la chose louée en '
            'état de servir à l\'usage prévu et à effectuer les réparations autres que locatives, '
            'notamment celles rendues nécessaires par la vétusté ou la force majeure.',
      ),
      LegalArticle(
        number: '7',
        heading: 'Obligations du preneur',
        text: 'Le preneur s\'oblige à payer le loyer et les charges aux termes convenus, à user '
            'paisiblement des lieux suivant leur destination, à les entretenir et à effectuer les '
            'réparations locatives, à souscrire une assurance couvrant les risques locatifs et à '
            'ne pas céder le bail ni sous-louer sans l\'accord écrit du bailleur.',
      ),
      LegalArticle(
        number: '8',
        heading: 'Résiliation',
        text: 'À défaut de paiement du loyer ou des charges, ou en cas de manquement grave du '
            'preneur à ses obligations, le bailleur pourra demander la résiliation du bail et '
            'l\'expulsion du preneur, après mise en demeure restée sans effet, dans les '
            'conditions prévues par la loi et sous le contrôle du juge.',
      ),
      LegalArticle(
        number: '9',
        heading: 'Règlement des litiges',
        text: 'Les parties s\'efforceront de régler à l\'amiable tout différend né du présent '
            'contrat. À défaut d\'accord, le litige sera porté devant la juridiction '
            'territorialement compétente du lieu de situation de l\'immeuble.',
      ),
    ],
    tags: const ['bail', 'habitation', 'modèle'],
    relatedDocumentIds: const ['doc-code-civil'],
  ),
  LegalDocument(
    id: 'doc-modele-cdd',
    title: 'Modèle de contrat de travail à durée déterminée',
    type: LegalDocumentType.modeleActe,
    domain: LegalDomain.travail,
    reference: 'Trame JurisIA — conforme au Code du travail',
    datePublication: DateTime(2024, 3, 2),
    summary: 'Trame de contrat à durée déterminée, à adapter au motif de recours et à votre convention collective.',
    officialSourceName: 'JurisIA',
    fullContent: '',
    outline: const ['Contrat de travail à durée déterminée'],
    articles: const [
      LegalArticle(
        number: '1',
        heading: 'Engagement et motif du recours',
        text: 'L\'employeur engage le salarié en contrat à durée déterminée pour le motif '
            'suivant : [remplacement d\'un salarié absent / accroissement temporaire d\'activité '
            '/ emploi à caractère saisonnier / exécution d\'une tâche précise et non durable]. Le '
            'contrat ne peut avoir ni pour objet ni pour effet de pourvoir durablement un emploi '
            'lié à l\'activité normale et permanente de l\'entreprise.',
      ),
      LegalArticle(
        number: '2',
        heading: 'Fonctions et lieu de travail',
        text: 'Le salarié est engagé en qualité de [intitulé du poste], classé à la catégorie '
            '[catégorie] de la convention collective applicable. Il exerce ses fonctions à '
            '[lieu], sous l\'autorité de [supérieur hiérarchique], et s\'engage à consacrer '
            'toute son activité professionnelle à l\'entreprise pendant la durée du contrat.',
      ),
      LegalArticle(
        number: '3',
        heading: 'Durée et terme',
        text: 'Le présent contrat est conclu du [date de début] au [date de fin] inclus, soit '
            'une durée de [durée]. Il pourra être renouvelé dans les limites et conditions '
            'fixées par le Code du travail. Le terme peut également être constitué par la '
            'réalisation de l\'objet pour lequel le contrat a été conclu ou par le retour du '
            'salarié remplacé.',
      ),
      LegalArticle(
        number: '4',
        heading: 'Période d\'essai',
        text: 'Le contrat comporte une période d\'essai de [durée], pendant laquelle chacune '
            'des parties peut y mettre fin sans indemnité, sous réserve du délai de prévenance '
            'applicable.',
      ),
      LegalArticle(
        number: '5',
        heading: 'Rémunération',
        text: 'En contrepartie de son travail, le salarié perçoit une rémunération mensuelle '
            'brute de [montant] F CFA, versée à terme échu selon la périodicité en vigueur dans '
            'l\'entreprise, augmentée le cas échéant des primes et accessoires prévus par la '
            'convention collective. La rémunération ne peut être inférieure au SMIG ni à celle '
            'd\'un salarié en contrat à durée indéterminée de qualification équivalente occupant '
            'le même poste.',
      ),
      LegalArticle(
        number: '6',
        heading: 'Durée du travail et congés',
        text: 'Le salarié est soumis à l\'horaire collectif de travail en vigueur dans '
            'l\'entreprise. Il bénéficie des congés payés au prorata de son temps de présence, '
            'ainsi que des repos et jours fériés dans les conditions légales et conventionnelles.',
      ),
      LegalArticle(
        number: '7',
        heading: 'Protection sociale',
        text: 'Le salarié est affilié à la Caisse nationale de sécurité sociale et, le cas '
            'échéant, aux régimes de prévoyance et de retraite complémentaire applicables dans '
            'l\'entreprise. Les cotisations sont précomptées et versées par l\'employeur.',
      ),
      LegalArticle(
        number: '8',
        heading: 'Rupture anticipée',
        text: 'Avant l\'échéance du terme, le contrat ne peut être rompu que d\'un commun '
            'accord, pour faute lourde, pour force majeure, ou à l\'initiative du salarié '
            'justifiant d\'une embauche en contrat à durée indéterminée. Toute rupture anticipée '
            'irrégulière ouvre droit à des dommages-intérêts, sans préjudice, pour le salarié, '
            'des rémunérations dues jusqu\'au terme prévu.',
      ),
      LegalArticle(
        number: '9',
        heading: 'Fin du contrat',
        text: 'À l\'échéance du terme, le contrat prend fin de plein droit. L\'employeur remet '
            'au salarié un certificat de travail, un reçu pour solde de tout compte et, le cas '
            'échéant, l\'indemnité de fin de contrat légalement ou conventionnellement due.',
      ),
    ],
    tags: const ['contrat de travail', 'CDD', 'modèle'],
    relatedDocumentIds: const ['doc-code-travail'],
  ),
];
