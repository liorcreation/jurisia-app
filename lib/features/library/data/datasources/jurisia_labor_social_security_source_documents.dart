import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import 'jurisia_course_pdf_urls.dart';

/// Références PDF transmises pour le pack travail et sécurité sociale.
/// Le document pénal/social commun aux deux matières est catalogué une seule
/// fois dans jurisia_penal_source_documents.dart et porte les deux tags.
final jurisiaLaborSocialSecuritySourceDocuments = <LegalDocument>[
  LegalDocument(
    id: 'pdf-labor-droit-travail-en-pratique-mine-marchand',
    title: 'Le droit du travail en pratique',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.travail,
    reference: 'Michel Miné et Daniel Marchand — 2009',
    datePublication: DateTime(2009, 5, 14),
    summary:
        'Ouvrage de droit du travail présentant les règles et pratiques françaises dans leur édition de 2009 ; les évolutions ultérieures doivent être vérifiées séparément.',
    summaryOnly: false,
    officialSourceName: 'PDF transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl('Droit du travail (3) (1).pdf'),
    tags: const [
      'pack-droit-travail-securite-sociale',
      'droit du travail',
      'relations professionnelles',
      'France',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-labor-introduction-droit-travail-mali',
    title: 'Introduction au droit du travail — Mali',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.travail,
    reference:
        'Centre de recherches, de documentations et de sondage d’opinions — Dr de Souza, juriste-consultant',
    datePublication: DateTime(2014, 10, 15),
    summary:
        'Cours d’introduction centré sur le droit du travail malien et ses sources, notamment la loi n° 92-020 du 23 septembre 1992 citée dans le document.',
    summaryOnly: false,
    officialSourceName: 'PDF transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl('INTRODUCTION AU DROIT DU TRAVAIL (1).pdf'),
    tags: const [
      'pack-droit-travail-securite-sociale',
      'droit du travail',
      'droit malien',
      'cours',
      'PDF intégral',
    ],
  ),
];
