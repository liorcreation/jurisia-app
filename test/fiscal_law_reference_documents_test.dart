import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/features/library/domain/entities/library_collection.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  final fiscalDocuments = LocalLegalDocumentDataSource()
      .getAll()
      .where(
        (document) => document.tags.contains('pack-droit-fiscal-international'),
      )
      .toList(growable: false);

  test('le pack fiscal expose les 17 PDF uniques intégraux', () {
    expect(fiscalDocuments, hasLength(17));
    expect(
      fiscalDocuments.every(
        (document) =>
            document.domain == LegalDomain.fiscal &&
            document.fileUrl?.toLowerCase().endsWith('.pdf') == true &&
            !document.summaryOnly &&
            document.tags.contains('PDF intégral'),
      ),
      isTrue,
    );
    expect(
      fiscalDocuments.map((document) => document.id).toSet(),
      hasLength(17),
    );
    expect(
      fiscalDocuments.map((document) => document.fileUrl).toSet(),
      hasLength(17),
    );
  });

  test('la collection fiscale est disponible dans le catalogue des packs', () {
    expect(
      libraryCollections.any(
        (collection) =>
            collection.tag == 'pack-droit-fiscal-international' &&
            collection.title == 'DROIT FISCAL ET FISCALITÉ INTERNATIONALE',
      ),
      isTrue,
    );
  });
}
