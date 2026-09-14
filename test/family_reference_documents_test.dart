import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/models/legal_document/legal_document_model.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  test('le catalogue local est strictement limité au droit de la famille', () {
    final documents = const LocalLegalDocumentDataSource(
      familyOnly: true,
      officialOnly: false,
    ).getAll();

    expect(documents, isNotEmpty);
    expect(
      documents.every((document) => document.domain == LegalDomain.famille),
      isTrue,
    );
    expect(
      documents.where((document) => document.type == LegalDocumentType.code),
      hasLength(2),
    );
  });

  test('les références transmises sont classées dans personnes et famille', () {
    final documents = const LocalLegalDocumentDataSource(
      familyOnly: true,
      officialOnly: false,
    ).getAll();
    expect(
      documents.every((document) => document.domain == LegalDomain.famille),
      isTrue,
    );
    expect(documents.where((document) => document.type == LegalDocumentType.doctrine), isNotEmpty);
    expect(documents.where((document) => document.type == LegalDocumentType.rapport), isNotEmpty);
  });

  test(
    'le Code de 2025 est la référence active et le Code de 1989 une archive',
    () {
      final documents = const LocalLegalDocumentDataSource(
        familyOnly: true,
        officialOnly: false,
      ).getAll();
      final currentCode = documents.singleWhere(
        (document) => document.id == 'doc-code-personnes-famille',
      );
      final archiveCode = documents.singleWhere(
        (document) => document.id == 'doc-code-personnes-famille-1989',
      );

      expect(currentCode.status, LegalDocumentStatus.enVigueur);
      expect(currentCode.reference, contains('012-2025/ALT'));
      expect(currentCode.datePublication, DateTime(2025, 9, 1));
      expect(archiveCode.status, LegalDocumentStatus.abroge);
      expect(archiveCode.relatedDocumentIds, contains(currentCode.id));
    },
  );

  test('les sept PDF transmis sont présents dans le périmètre famille', () {
      final documents = const LocalLegalDocumentDataSource(
        familyOnly: true,
        officialOnly: false,
      ).getAll();
      expect(
        documents.map((document) => document.id),
        containsAll(<String>[
          'doc-code-personnes-famille',
          'doc-code-personnes-famille-1989',
          'doc-onu-crc-sp-50',
          'doc-doctrine-mariage-senegal',
          'doc-doctrine-famille-burkina',
          'doc-these-egalite-mariage-afrique',
          'doc-these-pluralisme-justice-mossi',
        ]),
      );
    });
}
