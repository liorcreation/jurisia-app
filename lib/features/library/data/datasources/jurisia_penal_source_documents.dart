import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import 'jurisia_course_pdf_urls.dart';

/// PDF sources déposés pour les packs de droit pénal général et de procédure
/// pénale. Les textes sont ouverts depuis leur fichier intégral d'origine.
final jurisiaPenalSourceDocuments = <LegalDocument>[
  LegalDocument(
    id: 'pdf-penal-code-burkina-1996',
    title: 'Code pénal du Burkina Faso — édition 1996 (archive)',
    type: LegalDocumentType.code,
    domain: LegalDomain.penal,
    reference: 'Loi n° 043/96/ADP du 13 novembre 1996 — version historique',
    datePublication: DateTime(1996, 11, 13),
    status: LegalDocumentStatus.abroge,
    summary:
        'Texte historique du Code pénal burkinabè. Consulter l’édition applicable aux faits avant toute utilisation.',
    summaryOnly: false,
    officialSourceName: 'Copie PDF transmise à JurisIA — archive historique',
    fileUrl: jurisiaLibraryPdfUrl('CODE PENAL du Burkina Faso.pdf'),
    tags: const [
      'pack-penal',
      'droit pénal général',
      'Burkina Faso',
      'archive historique',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-penal-exercices-corriges',
    title: 'Droit pénal — exercices corrigés',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.penal,
    reference: 'Support d’exercices transmis à JurisIA',
    datePublication: DateTime(2020, 6, 24),
    summary:
        'Exercices corrigés de droit pénal pour s’entraîner à la qualification et au raisonnement.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      '@SciencesJuridiques Droit pnal Exercice-Corrig.pdf',
    ),
    tags: const [
      'pack-penal',
      'droit pénal général',
      'exercices corrigés',
      'méthodologie',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-penal-compare-pradel-2016',
    title: 'Droit pénal comparé — Jean Pradel',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.penal,
    reference: 'Jean Pradel — Précis, Dalloz, édition 2016',
    datePublication: DateTime(2016),
    summary:
        'Étude de droit pénal comparé. Le fichier transmis est consultable en PDF intégral.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Droit pnal compar (Prcis) (French Edition) -- Pradel, Jean -- 2016 -- Dalloz -- f37cec40964beb26192c0790f678b442 -- Annas Archive.pdf',
    ),
    tags: const [
      'pack-penal',
      'droit pénal comparé',
      'Jean Pradel',
      'doctrine',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-penal-general-larcier-part-1',
    title: 'Droit pénal général — Larcier (partie 1/2)',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.penal,
    reference: 'PDF intégral réparti — pages 1 à 209 sur 419',
    datePublication: DateTime(2020, 4, 19),
    summary:
        'Première partie du PDF Larcier, pages 1 à 209. Le volume 2/2 contient la suite sans omission.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA — volume 1/2',
    fileUrl: jurisiaLibraryPdfUrl('penal-general-larcier-part-1-of-2.pdf'),
    tags: const [
      'pack-penal',
      'droit pénal général',
      'Larcier',
      'doctrine',
      'PDF intégral',
      'volume 1/2',
    ],
  ),
  LegalDocument(
    id: 'pdf-penal-general-larcier-part-2',
    title: 'Droit pénal général — Larcier (partie 2/2)',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.penal,
    reference: 'PDF intégral réparti — pages 210 à 419 sur 419',
    datePublication: DateTime(2020, 4, 19),
    summary:
        'Seconde partie du PDF Larcier, pages 210 à 419. Elle complète le volume 1/2.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA — volume 2/2',
    fileUrl: jurisiaLibraryPdfUrl('penal-general-larcier-part-2-of-2.pdf'),
    tags: const [
      'pack-penal',
      'droit pénal général',
      'Larcier',
      'doctrine',
      'PDF intégral',
      'volume 2/2',
    ],
  ),
  LegalDocument(
    id: 'pdf-penal-travail-securite-sociale',
    title: 'Droit pénal du travail et de la sécurité sociale',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.penal,
    reference: 'Guy — document transmis à JurisIA',
    datePublication: DateTime(2007, 10, 25),
    summary:
        'Ressource consacrée aux infractions et règles pénales liées au travail et à la sécurité sociale.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Droit_pnal_du_travail_et_le_droit_de_la_scurit_sociale_de_BOU.pdf',
    ),
    tags: const [
      'pack-penal',
      'pack-droit-travail-securite-sociale',
      'droit pénal du travail',
      'sécurité sociale',
      'droit social',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-penal-general-barres',
    title: 'Droit pénal général — Garance Barrès',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.penal,
    reference: 'Garance Barrès — support daté de 2016 dans les métadonnées PDF',
    datePublication: DateTime(2016, 1, 20),
    summary:
        'Support de droit pénal général consultable dans son PDF intégral.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl('Droit-pnal-gnral.pdf'),
    tags: const [
      'pack-penal',
      'droit pénal général',
      'Garance Barrès',
      'cours',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-procedure-penale-verny-2018',
    title: 'Procédure pénale — Édouard Verny',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.procedurePenale,
    reference: 'Édouard Verny — Cours Dalloz, 6e édition, Paris, 2018',
    datePublication: DateTime(2018),
    summary:
        'Cours de procédure pénale, 6e édition, disponible dans son PDF intégral.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Je partage Procdure pnale (Cours Dalloz) Sixime dition -- Edouard Verny -- Cours Dalloz_ Serie Droit prive, 6e edition, Paris, 2018 -- Dalloz -- 9782247179718 -- a8dac1d7784be6ace18b8125ce1fbe18 -- Annas Archive avec vous.pdf',
    ),
    tags: const [
      'pack-penal',
      'procédure pénale',
      'Édouard Verny',
      'Cours Dalloz',
      'PDF intégral',
    ],
  ),
];
