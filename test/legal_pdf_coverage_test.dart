import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';

void main() {
  test('every local Obligations pack entry opens a full PDF', () {
    final documents = LocalLegalDocumentDataSource()
        .getAll()
        .where((document) => document.tags.contains('pack-obligations'))
        .toList();

    expect(documents, isNotEmpty);
    for (final document in documents) {
      expect(
        document.fileUrl,
        isNotNull,
        reason: '${document.id} must open a PDF',
      );
      expect(
        document.fileUrl!.toLowerCase(),
        endsWith('.pdf'),
        reason: '${document.id} must use a PDF URL',
      );
      expect(
        document.summaryOnly,
        isFalse,
        reason: '${document.id} must not be labelled as a summary',
      );
    }
  });
}
