import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import 'jurisia_course_pdf_urls.dart';

/// PDF sources du pack de finances publiques.
/// Les deux copies binaires identiques sur l'UEMOA/Sénégal sont cataloguées
/// une seule fois.
final jurisiaPublicFinanceSourceDocuments = <LegalDocument>[
  LegalDocument(
    id: 'pdf-public-finance-blanc-droit-economique',
    title: 'Du droit public économique au droit public de l’économie',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.administratif,
    reference:
        'F. Blanc — Du droit public économique au droit public de l’économie',
    datePublication: DateTime(2000),
    summary: 'Étude consacrée au droit public économique.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      "F. Blanc, Du droit public economique au droit public de l'economie.pdf",
    ),
    tags: const [
      'pack-finances-publiques',
      'droit public économique',
      'F. Blanc',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-public-finance-chouvel-2020',
    title: 'Finances publiques — François Chouvel (2020)',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.fiscal,
    reference:
        'François Chouvel — Finances publiques, Mémentos, 23e édition, 2020',
    datePublication: DateTime(2020),
    summary: 'Ouvrage de finances publiques, édition 2020.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Finances publiques 2020 _ Intgre la loi de finances pour -- Chouvel, Franois -- Mmentos, 23, 2020 -- Gualino -- 42877e26f3e7c0ce07717932231c389d -- Annas Archive.pdf',
    ),
    tags: const [
      'pack-finances-publiques',
      'finances publiques',
      'François Chouvel',
      '2020',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-public-finance-chouvel',
    title: 'Finances publiques — François Chouvel',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.fiscal,
    reference: 'François Chouvel — Finances publiques',
    datePublication: DateTime(2000),
    summary: 'Document consacré aux finances publiques.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Finances publiques by Francois Chouvel (z-lib.org).pdf',
    ),
    tags: const [
      'pack-finances-publiques',
      'finances publiques',
      'François Chouvel',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-public-finance-hasquenoh-voix-feminines',
    title: 'Les voix féminines du droit public de l’économie',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.administratif,
    reference:
        'I. Hasquenoh — Les voix féminines du droit public de l’économie',
    datePublication: DateTime(2000),
    summary: 'Étude sur les voix féminines du droit public de l’économie.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      "I. Hasquenoh, Les voix feminines du droit public de l'economie.pdf",
    ),
    tags: const [
      'pack-finances-publiques',
      'droit public économique',
      'I. Hasquenoh',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-public-finance-boucheix',
    title: 'Les finances publiques — Philippe Boucheix',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.fiscal,
    reference: 'Philippe Boucheix — Les finances publiques',
    datePublication: DateTime(2000),
    summary: 'Document consacré aux finances publiques.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Les finances publiqu... by Philippe Boucheix  R... (z-lib.or.pdf',
    ),
    tags: const [
      'pack-finances-publiques',
      'finances publiques',
      'Philippe Boucheix',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-public-finance-uemoa-senegal',
    title: 'Les finances publiques dans l’UEMOA — Sénégal',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.fiscal,
    reference: 'Les finances publiques dans l’UEMOA — Sénégal',
    datePublication: DateTime(2000),
    summary:
        'Étude des finances publiques dans l’espace UEMOA, consacrée au Sénégal.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      "LES FINANCES PUBLIQUES DANS L'UEMOA_SENEGAL.pdf",
    ),
    tags: const [
      'pack-finances-publiques',
      'finances publiques',
      'UEMOA',
      'Sénégal',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-public-finance-houser-concours',
    title: 'Les finances publiques aux concours — Matthieu Houser',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.fiscal,
    reference: 'Matthieu Houser — Les finances publiques aux concours',
    datePublication: DateTime(2000),
    summary:
        'Support de finances publiques destiné à la préparation des concours.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Les_finances_publiques_aux_concours_by_Matthieu_Houser_z_lib_org.pdf',
    ),
    tags: const [
      'pack-finances-publiques',
      'finances publiques',
      'Matthieu Houser',
      'concours',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-public-finance-chambon-courants-doctrinaux',
    title: 'Les courants doctrinaux du droit public de l’économie',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.administratif,
    reference:
        'M. Chambon — Les courants doctrinaux du droit public de l’économie',
    datePublication: DateTime(2000),
    summary: 'Étude des courants doctrinaux du droit public de l’économie.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      "M. Chambon, Les courants doctrinaux du droit public de l'economie.pdf",
    ),
    tags: const [
      'pack-finances-publiques',
      'droit public économique',
      'M. Chambon',
      'PDF intégral',
    ],
  ),
];
