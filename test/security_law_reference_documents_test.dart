import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/features/library/domain/entities/library_collection.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  final suretyDocuments = LocalLegalDocumentDataSource()
      .getAll()
      .where((document) => document.tags.contains('pack-droit-suretes'))
      .toList(growable: false);

  test('le pack sûretés expose les 7 PDF uniques intégraux', () {
    expect(suretyDocuments, hasLength(7));
    expect(
      suretyDocuments.every(
        (document) =>
            (document.domain == LegalDomain.ohada ||
                document.domain == LegalDomain.civil) &&
            document.fileUrl?.toLowerCase().endsWith('.pdf') == true &&
            !document.summaryOnly &&
            document.tags.contains('PDF intégral'),
      ),
      isTrue,
    );
    expect(
      suretyDocuments.map((document) => document.id).toSet(),
      hasLength(7),
    );
    expect(
      suretyDocuments.map((document) => document.fileUrl).toSet(),
      hasLength(7),
    );
  });

  test('la collection sûretés est présente dans le catalogue', () {
    expect(
      libraryCollections.any(
        (collection) =>
            collection.tag == 'pack-droit-suretes' &&
            collection.title == 'DROIT DES SÛRETÉS',
      ),
      isTrue,
    );
  });
}
