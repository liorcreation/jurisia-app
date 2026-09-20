import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  test('le pack bancaire et assurances expose trois cours complets originaux', () {
    final documents = const LocalLegalDocumentDataSource(
      familyOnly: false,
      officialOnly: false,
    ).getAll();

    final bankingInsurance = documents
        .where((document) =>
            document.tags.contains('pack-droit-bancaire-assurances'))
        .toList();

    expect(bankingInsurance, hasLength(3));
    expect(
      bankingInsurance.map((document) => document.id),
      containsAll(<String>[
        'doc-jurisia-droit-bancaire-general',
        'doc-jurisia-droit-bancaire-umoa',
        'doc-jurisia-droit-assurances-cima',
      ]),
    );
    expect(
      bankingInsurance.every((document) => document.summaryOnly == false),
      isTrue,
    );
    expect(
      bankingInsurance.every((document) => document.hasFullText),
      isTrue,
    );
    expect(
      bankingInsurance.map((document) => document.domain),
      containsAll(<LegalDomain>[
        LegalDomain.commercial,
        LegalDomain.ohada,
      ]),
    );
  });
}
