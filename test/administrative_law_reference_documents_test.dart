import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  test('le pack administratif expose trois cours complets originaux', () {
    final documents = const LocalLegalDocumentDataSource(
      familyOnly: false,
      officialOnly: false,
    ).getAll();

    final administrative = documents
        .where((document) =>
            document.tags.contains('pack-droit-administratif'))
        .toList();

    expect(administrative, hasLength(3));
    expect(
      administrative.map((document) => document.id),
      containsAll(<String>[
        'doc-jurisia-action-administrative',
        'doc-jurisia-contrats-administratifs',
        'doc-jurisia-contentieux-administratif',
      ]),
    );
    expect(
      administrative.every((document) => document.summaryOnly == false),
      isTrue,
    );
    expect(
      administrative.every((document) => document.hasFullText),
      isTrue,
    );
    expect(
      administrative.every(
        (document) => document.domain == LegalDomain.administratif,
      ),
      isTrue,
    );
  });
}
