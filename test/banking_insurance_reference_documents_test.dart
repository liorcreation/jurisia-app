import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

void main() {
  test(
    'le pack bancaire et assurances expose ses cours et PDF de référence',
    () {
      final documents = const LocalLegalDocumentDataSource(
        familyOnly: false,
        officialOnly: false,
      ).getAll();

      final bankingInsurance = documents
          .where(
            (document) =>
                document.tags.contains('pack-droit-bancaire-assurances'),
          )
          .toList();

      expect(bankingInsurance, hasLength(8));
      expect(
        bankingInsurance.map((document) => document.id),
        containsAll(<String>[
          'doc-jurisia-droit-bancaire-general',
          'doc-jurisia-droit-bancaire-umoa',
          'doc-jurisia-droit-assurances-cima',
          'pdf-insurance-liability-civil-2018',
          'pdf-insurance-course-rouen',
          'pdf-insurance-risk-management-wagner-fuino',
          'pdf-insurance-enterprise-bergeron',
          'pdf-insurance-enterprise-risks-medjebeur',
        ]),
      );
      expect(
        bankingInsurance.every((document) => document.summaryOnly == false),
        isTrue,
      );
      expect(
        bankingInsurance
            .where((document) => document.id.startsWith('doc-jurisia-'))
            .every((document) => document.hasFullText),
        isTrue,
      );
      final insurancePdfSources = bankingInsurance
          .where((document) => document.id.startsWith('pdf-insurance-'))
          .toList();
      expect(insurancePdfSources, hasLength(5));
      expect(
        insurancePdfSources.every(
          (document) =>
              document.summaryOnly == false &&
              document.fileUrl?.endsWith('.pdf') == true,
        ),
        isTrue,
      );
      expect(
        bankingInsurance.map((document) => document.domain),
        containsAll(<LegalDomain>[LegalDomain.commercial, LegalDomain.ohada]),
      );
    },
  );
}
