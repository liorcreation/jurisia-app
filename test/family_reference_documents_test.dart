import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/models/legal_document/legal_document_model.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  test('les références transmises sont classées dans personnes et famille', () {
    final documents = const LocalLegalDocumentDataSource().getAll();
    final references = documents
        .where(
          (document) =>
              document.id == 'doc-onu-crc-sp-50' ||
              document.id == 'doc-doctrine-mariage-senegal' ||
              document.id == 'doc-doctrine-famille-burkina',
        )
        .toList();

    expect(references, hasLength(3));
    expect(
      references.every((document) => document.domain == LegalDomain.famille),
      isTrue,
    );
    expect(
      references.where(
        (document) => document.type == LegalDocumentType.doctrine,
      ),
      hasLength(2),
    );
    expect(
      references
          .singleWhere((document) => document.type == LegalDocumentType.rapport)
          .summaryOnly,
      isTrue,
    );
  });

  test('le Code de 2025 est la référence active et le Code de 1989 une archive', () {
    final documents = const LocalLegalDocumentDataSource().getAll();
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
  });

  test('les thèses transmises restent des références doctrinales de synthèse', () {
    final documents = const LocalLegalDocumentDataSource().getAll();
    final theses = documents
        .where(
          (document) =>
              document.id == 'doc-these-egalite-mariage-afrique' ||
              document.id == 'doc-these-pluralisme-justice-mossi',
        )
        .toList();

    expect(theses, hasLength(2));
    expect(
      theses.every(
        (document) =>
            document.type == LegalDocumentType.doctrine &&
            document.domain == LegalDomain.famille &&
            document.summaryOnly,
      ),
      isTrue,
    );
  });
}
