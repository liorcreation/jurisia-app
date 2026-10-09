import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import 'jurisia_course_pdf_urls.dart';

/// Documents PDF du pack de sciences politiques.
/// Les trois copies portant « (1) » sont des doublons binaires et ne sont
/// donc référencées qu'une seule fois.
final jurisiaPoliticalScienceSourceDocuments = <LegalDocument>[
  LegalDocument(
    id: 'pdf-political-science-dictionary-hermet-badie',
    title: 'Dictionnaire de la science politique',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.constitutionnel,
    reference:
        'Guy Hermet et Bertrand Badie — Dictionnaire de la science politique',
    datePublication: DateTime(2000),
    summary: 'Dictionnaire de science politique transmis à JurisIA.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Dictionnaire de la science poli - Guy Hermet;Bertrand Badie;.pdf',
    ),
    tags: const [
      'pack-sciences-politiques',
      'science politique',
      'Guy Hermet',
      'Bertrand Badie',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-political-science-dictionary-institutions',
    title:
        'Dictionnaire de la science politique et des institutions politiques',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.constitutionnel,
    reference:
        'Dictionnaire de la science politique et des institutions politiques',
    datePublication: DateTime(2000),
    summary:
        'Dictionnaire consacré à la science politique et aux institutions politiques.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl(
      'Dictionnaire_de_la_science_politique_et_des_institutions_politiq.pdf',
    ),
    tags: const [
      'pack-sciences-politiques',
      'science politique',
      'institutions politiques',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-political-science-course',
    title: 'Sciences politiques',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.constitutionnel,
    reference: 'Sciences politiques — support de cours',
    datePublication: DateTime(2000),
    summary: 'Support de cours de sciences politiques transmis à JurisIA.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl('Sciences politiques.pdf'),
    tags: const [
      'pack-sciences-politiques',
      'science politique',
      'cours',
      'PDF intégral',
    ],
  ),
  LegalDocument(
    id: 'pdf-political-science-kelsen-theory-law',
    title: 'Théorie pure du droit — Hans Kelsen',
    type: LegalDocumentType.doctrine,
    domain: LegalDomain.constitutionnel,
    reference: 'Hans Kelsen — Théorie pure du droit (1962)',
    datePublication: DateTime(1962),
    summary: 'Ouvrage de théorie du droit transmis à JurisIA.',
    summaryOnly: false,
    officialSourceName: 'Document transmis à JurisIA',
    fileUrl: jurisiaLibraryPdfUrl('Theorie Pure Du Droit 1962 Hans Kelsen.pdf'),
    tags: const [
      'pack-sciences-politiques',
      'théorie du droit',
      'Hans Kelsen',
      'PDF intégral',
    ],
  ),
];
