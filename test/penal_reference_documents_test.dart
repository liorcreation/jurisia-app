import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  test('le pack pénal expose ses cours et les PDF sources intégraux', () {
    final documents = const LocalLegalDocumentDataSource(
      familyOnly: false,
      officialOnly: false,
    ).getAll();

    final penal = documents
        .where((document) => document.tags.contains('pack-penal'))
        .toList();

    expect(penal, hasLength(11));
    expect(
      penal.map((document) => document.id),
      containsAll(<String>[
        'doc-jurisia-cours-complet-droit-penal-general',
        'doc-jurisia-cours-complet-droit-penal-special',
        'doc-jurisia-cours-complet-procedure-penale',
        'pdf-penal-code-burkina-1996',
        'pdf-penal-exercices-corriges',
        'pdf-penal-compare-pradel-2016',
        'pdf-penal-general-larcier-part-1',
        'pdf-penal-general-larcier-part-2',
        'pdf-penal-travail-securite-sociale',
        'pdf-penal-general-barres',
        'pdf-procedure-penale-verny-2018',
      ]),
    );
    expect(penal.every((document) => !document.summaryOnly), isTrue);
    expect(
      penal.where(
        (document) =>
            document.id.startsWith('pdf-penal-') ||
            document.id.startsWith('pdf-procedure-penale-'),
      ),
      hasLength(8),
    );
    expect(
      penal.every(
        (document) => document.fileUrl?.contains('/legal-source-pdfs/') == true,
      ),
      isTrue,
    );
    expect(
      penal
          .where((document) => document.id.startsWith('doc-jurisia-'))
          .every((document) => document.hasFullText),
      isTrue,
    );
    expect(
      penal.any((document) => document.domain == LegalDomain.procedurePenale),
      isTrue,
    );
  });
}
