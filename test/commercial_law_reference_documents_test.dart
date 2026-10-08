import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/features/library/domain/entities/library_collection.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  test('le pack commercial expose ses 12 PDF intégraux sans doublon', () {
    final documents = LocalLegalDocumentDataSource()
        .getAll()
        .where(
          (document) =>
              document.tags.contains('pack-droit-commercial-societes'),
        )
        .toList();

    expect(documents, hasLength(12));
    expect(
      documents.every((document) => document.domain == LegalDomain.commercial),
      isTrue,
    );
    expect(
      documents.every(
        (document) =>
            document.fileUrl?.toLowerCase().endsWith('.pdf') == true &&
            !document.summaryOnly,
      ),
      isTrue,
    );
    expect(
      libraryCollections.map((collection) => collection.tag),
      contains('pack-droit-commercial-societes'),
    );
  });
}
