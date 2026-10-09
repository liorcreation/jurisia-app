import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/features/library/domain/entities/library_collection.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  test(
    'le pack travail expose trois PDF intégraux sans dupliquer la source',
    () {
    final documents = LocalLegalDocumentDataSource()
        .getAll()
        .where(
          (document) =>
              document.tags.contains('pack-droit-travail-securite-sociale'),
        )
        .toList();

    expect(documents, hasLength(3));
    expect(
      documents.map((document) => document.id),
      containsAll(<String>[
        'pdf-labor-droit-travail-en-pratique-mine-marchand',
        'pdf-labor-introduction-droit-travail-mali',
        'pdf-penal-travail-securite-sociale',
      ]),
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
      documents.where(
        (document) => document.id == 'pdf-penal-travail-securite-sociale',
      ),
      hasLength(1),
    );
    expect(
      libraryCollections.map((collection) => collection.tag),
      contains('pack-droit-travail-securite-sociale'),
    );
    expect(
      documents.where((document) => document.domain == LegalDomain.travail),
      hasLength(2),
    );
  });
}
