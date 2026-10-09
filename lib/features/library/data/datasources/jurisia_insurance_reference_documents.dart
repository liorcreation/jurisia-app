import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import 'jurisia_course_pdf_urls.dart';

/// PDF de référence transmis pour compléter le volet assurances du pack
/// bancaire et assurances.
final jurisiaInsuranceReferenceDocuments = <LegalDocument>[
  LegalDocument(
    id: 'pdf-insurance-liability-civil-2018',
    title: 'Responsabilité civile et assurances — Actualités 2018',
    type: LegalDocumentType.rapport,
    domain: LegalDomain.commercial,
    reference:
        'Ordre des avocats de Paris, Commission Assurances et Responsabilité civile — réunion du 18 janvier 2018',
    datePublication: DateTime(2018, 1, 18),
    summary:
        'Dossier de veille consacré aux actualités législatives et jurisprudentielles en droit des assurances.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'assurances_et_responsabilite_civile_18_janvier_2018.pdf',
    ),
    tags: const [
      'pack-droit-bancaire-assurances',
      'droit des assurances',
      'responsabilité civile',
      'veille juridique',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-insurance-course-rouen',
    title: 'Droit approfondi des assurances — Université de Rouen',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.commercial,
    reference: 'Cours universitaire — Droit approfondi des assurances',
    datePublication: DateTime(2013, 8, 21),
    summary:
        'Cours universitaire portant sur la théorie générale du droit des assurances, les assurances de dommages et les assurances de personnes.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Droit cours, droit approfondi des Assurances.pdf',
    ),
    tags: const [
      'pack-droit-bancaire-assurances',
      'droit des assurances',
      'cours universitaire',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-insurance-risk-management-wagner-fuino',
    title: 'Gestion du risque et introduction aux assurances',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.commercial,
    reference:
        'Joël Wagner et Michel Fuino — Gestion du risque & introduction aux assurances',
    datePublication: DateTime(2021, 12, 21),
    summary:
        'Ouvrage introductif consacré à la gestion des risques et aux mécanismes fondamentaux de l’assurance.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Gestion_du_risque_et_introduction_aux_assurances__ed1_v1.pdf',
    ),
    tags: const [
      'pack-droit-bancaire-assurances',
      'droit des assurances',
      'gestion du risque',
      'Joël Wagner',
      'Michel Fuino',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-insurance-enterprise-bergeron',
    title: 'Le droit des assurances et l’entreprise',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.commercial,
    reference: 'Jean-Guy Bergeron — Le droit des assurances et l’entreprise',
    datePublication: DateTime(1983),
    summary:
        'Étude doctrinale sur le contrat d’assurance et ses liens avec l’activité de l’entreprise.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      "LE DROIT DES ASSURANCES ET L'ENTREPRISE.pdf",
    ),
    tags: const [
      'pack-droit-bancaire-assurances',
      'droit des assurances',
      'entreprise',
      'Jean-Guy Bergeron',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-insurance-enterprise-risks-medjebeur',
    title: 'Les assurances des risques d’entreprises',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.commercial,
    reference: 'Nora Fodil Medjebeur — Thèse de doctorat, Université d’Oran 2',
    datePublication: DateTime(2000),
    summary:
        'Thèse consacrée aux assurances des risques d’entreprise et à leur cadre juridique.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      "Les assurances des risques d'entreprises.pdf",
    ),
    tags: const [
      'pack-droit-bancaire-assurances',
      'droit des assurances',
      'risques d’entreprise',
      'Nora Fodil Medjebeur',
      'thèse',
      'PDF intégral',
    ],
  ),
];
