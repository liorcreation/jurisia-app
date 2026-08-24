import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/features/library/data/repositories/library_repository_impl.dart';
import 'package:jurisia_app/features/library/domain/entities/library_search_query.dart';
import 'package:jurisia_app/features/library/domain/repositories/library_repository.dart';
import 'package:jurisia_app/features/library/domain/usecases/search_legal_documents_usecase.dart';
import 'package:jurisia_app/features/library/domain/usecases/toggle_bookmark_usecase.dart';
import 'package:jurisia_app/models/legal_document/legal_document_model.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

class _FakeDataSource implements LegalDocumentDataSource {
  const _FakeDataSource();

  @override
  List<LegalDocument> getAll() => [
        LegalDocument(
          id: 'a',
          title: 'Code civil',
          type: LegalDocumentType.code,
          domain: LegalDomain.civil,
          reference: 'Livre I à IV',
          datePublication: DateTime(1958, 3, 4),
          summary: 'Régit les personnes, la famille, les biens.',
          fullContent: 'Article 1 : toute personne jouit de ses droits civils.',
          tags: const ['famille', 'biens'],
        ),
        LegalDocument(
          id: 'b',
          title: 'Code du travail',
          type: LegalDocumentType.code,
          domain: LegalDomain.travail,
          reference: 'Édition consolidée',
          datePublication: DateTime(1992, 12, 15),
          summary: 'Relations individuelles et collectives de travail.',
          fullContent: 'Article 12 : le contrat de travail peut être à durée déterminée.',
          tags: const ['contrat de travail'],
        ),
        LegalDocument(
          id: 'c',
          title: 'Arrêt sur la rupture abusive',
          type: LegalDocumentType.jurisprudence,
          domain: LegalDomain.travail,
          reference: 'Cass. soc., n° 245/2021',
          datePublication: DateTime(2021, 9, 14),
          summary: "Critères d'appréciation du licenciement abusif.",
          fullContent: "La cour retient que l'absence de préavis prive l'employeur.",
          tags: const ['licenciement'],
        ),
      ];
}

void main() {
  late LibraryRepository repository;
  late SearchLegalDocumentsUseCase searchUseCase;
  late ToggleBookmarkUseCase toggleBookmarkUseCase;

  setUp(() {
    repository = LibraryRepositoryImpl(dataSource: const _FakeDataSource());
    searchUseCase = SearchLegalDocumentsUseCase(repository: repository);
    toggleBookmarkUseCase = ToggleBookmarkUseCase(repository: repository);
  });

  group('LibraryRepositoryImpl.search', () {
    test('returns every document for an empty query', () {
      expect(searchUseCase(const LibrarySearchQuery()), hasLength(3));
    });

    test('filters by keyword across title, summary and tags', () {
      expect(searchUseCase(const LibrarySearchQuery(keyword: 'famille')).map((d) => d.id), ['a']);
      expect(
        searchUseCase(const LibrarySearchQuery(keyword: 'licenciement')).map((d) => d.id),
        ['c'],
      );
    });

    test('filters by keyword matching the reference (numéro de texte/article)', () {
      expect(
        searchUseCase(const LibrarySearchQuery(keyword: 'Cass. soc')).map((d) => d.id),
        ['c'],
      );
    });

    test('keyword search is case-insensitive', () {
      expect(
        searchUseCase(const LibrarySearchQuery(keyword: 'CODE DU TRAVAIL')).map((d) => d.id),
        ['b'],
      );
    });

    test('filters by document type', () {
      final results = searchUseCase(const LibrarySearchQuery(type: LegalDocumentType.code));
      expect(results.map((d) => d.id).toSet(), {'a', 'b'});
    });

    test('filters by legal domain', () {
      final results = searchUseCase(const LibrarySearchQuery(domain: LegalDomain.travail));
      expect(results.map((d) => d.id).toSet(), {'b', 'c'});
    });

    test('filters by publication date range', () {
      final results = searchUseCase(
        LibrarySearchQuery(dateFrom: DateTime(1980, 1, 1), dateTo: DateTime(2022, 1, 1)),
      );
      expect(results.map((d) => d.id).toSet(), {'b', 'c'});
    });

    test('combines several criteria at once', () {
      final results = searchUseCase(
        const LibrarySearchQuery(keyword: 'travail', type: LegalDocumentType.jurisprudence),
      );
      expect(results, isEmpty);

      final matching = searchUseCase(
        const LibrarySearchQuery(domain: LegalDomain.travail, type: LegalDocumentType.jurisprudence),
      );
      expect(matching.map((d) => d.id), ['c']);
    });

    test('returns an empty list when nothing matches', () {
      expect(searchUseCase(const LibrarySearchQuery(keyword: 'inexistant')), isEmpty);
    });
  });

  group('LibraryRepositoryImpl.toggleBookmark', () {
    test('marks and unmarks a document as favorite, reflected by favoritesOnly', () {
      final toggledOn = toggleBookmarkUseCase('a');
      expect(toggledOn.isFavorite, isTrue);
      expect(
        searchUseCase(const LibrarySearchQuery(favoritesOnly: true)).map((d) => d.id),
        ['a'],
      );

      final toggledOff = toggleBookmarkUseCase('a');
      expect(toggledOff.isFavorite, isFalse);
      expect(searchUseCase(const LibrarySearchQuery(favoritesOnly: true)), isEmpty);
    });

    test('throws for an unknown document id', () {
      expect(() => toggleBookmarkUseCase('unknown'), throwsArgumentError);
    });
  });

  group('LibraryRepositoryImpl.recordDownload', () {
    test('increments the download counter without affecting other documents', () {
      final before = repository.findById('a')!.downloadCount;
      final updated = repository.recordDownload('a');
      expect(updated.downloadCount, before + 1);
      expect(repository.findById('b')!.downloadCount, 0);
    });

    test('throws for an unknown document id', () {
      expect(() => repository.recordDownload('unknown'), throwsArgumentError);
    });
  });

  group('LibraryRepositoryImpl.findById', () {
    test('returns null when the document does not exist', () {
      expect(repository.findById('unknown'), isNull);
    });
  });
}
