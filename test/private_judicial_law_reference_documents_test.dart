import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  test('le pack DJP expose trois cours complets originaux', () {
    final documents = const LocalLegalDocumentDataSource(
      familyOnly: false,
      officialOnly: false,
    ).getAll();

    final privateJudicialLaw = documents
        .where((document) =>
            document.tags.contains('pack-droit-judiciaire-prive'))
        .toList();

    expect(privateJudicialLaw, hasLength(3));
    expect(
      privateJudicialLaw.map((document) => document.id),
      containsAll(<String>[
        'doc-jurisia-fondements-droit-judiciaire-prive',
        'doc-jurisia-procedure-civile-complete',
        'doc-jurisia-juridictions-execution-civile',
      ]),
    );
    expect(
      privateJudicialLaw.every((document) => document.summaryOnly == false),
      isTrue,
    );
    expect(
      privateJudicialLaw.every((document) => document.hasFullText),
      isTrue,
    );
    expect(
      privateJudicialLaw.every(
        (document) => document.domain == LegalDomain.procedureCivile,
      ),
      isTrue,
    );
  });
}
