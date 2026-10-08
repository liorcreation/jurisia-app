import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/features/library/domain/entities/library_collection.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  final documents = LocalLegalDocumentDataSource()
      .getAll()
      .where((document) => document.tags.contains('pack-finances-publiques'))
      .toList(growable: false);

  test('le pack finances publiques expose les 8 PDF uniques intégraux', () {
    expect(documents, hasLength(8));
    expect(
      documents.every(
        (document) =>
            (document.domain == LegalDomain.fiscal ||
                document.domain == LegalDomain.administratif) &&
            document.fileUrl?.toLowerCase().endsWith('.pdf') == true &&
            !document.summaryOnly &&
            document.tags.contains('PDF intégral'),
      ),
      isTrue,
    );
    expect(documents.map((document) => document.id).toSet(), hasLength(8));
    expect(documents.map((document) => document.fileUrl).toSet(), hasLength(8));
  });

  test('la collection Finances publiques est présente dans le catalogue', () {
    expect(
      libraryCollections.any(
        (collection) =>
            collection.tag == 'pack-finances-publiques' &&
            collection.title == 'FINANCES PUBLIQUES',
      ),
      isTrue,
    );
  });
}
