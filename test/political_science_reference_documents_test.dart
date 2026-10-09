import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/features/library/domain/entities/library_collection.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  final documents = LocalLegalDocumentDataSource()
      .getAll()
      .where((document) => document.tags.contains('pack-sciences-politiques'))
      .toList(growable: false);

  test('le pack expose les 4 PDF distincts et intégraux', () {
    expect(documents, hasLength(4));
    expect(
      documents.every(
        (document) =>
            document.domain == LegalDomain.constitutionnel &&
            document.fileUrl?.toLowerCase().endsWith('.pdf') == true &&
            !document.summaryOnly &&
            document.tags.contains('PDF intégral'),
      ),
      isTrue,
    );
    expect(documents.map((document) => document.id).toSet(), hasLength(4));
    expect(documents.map((document) => document.fileUrl).toSet(), hasLength(4));
  });

  test('la collection Sciences politiques est présente au catalogue', () {
    expect(
      libraryCollections.any(
        (collection) =>
            collection.tag == 'pack-sciences-politiques' &&
            collection.title == 'SCIENCES POLITIQUES',
      ),
      isTrue,
    );
  });
}
