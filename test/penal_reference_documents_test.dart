import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  test('le pack pénal JurisIA expose trois cours complets originaux', () {
    final documents = const LocalLegalDocumentDataSource(
      familyOnly: false,
      officialOnly: false,
    ).getAll();

    final penal = documents
        .where((document) => document.tags.contains('pack-penal'))
        .toList();

    expect(penal, hasLength(3));
    expect(
      penal.map((document) => document.id),
      containsAll(<String>[
        'doc-jurisia-cours-complet-droit-penal-general',
        'doc-jurisia-cours-complet-droit-penal-special',
        'doc-jurisia-cours-complet-procedure-penale',
      ]),
    );
    expect(penal.every((document) => document.summaryOnly == false), isTrue);
    expect(penal.every((document) => document.hasFullText), isTrue);
    expect(
      penal.any((document) => document.domain == LegalDomain.procedurePenale),
      isTrue,
    );
  });
}
