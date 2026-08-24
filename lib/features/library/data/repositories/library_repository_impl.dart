import '../../../../models/legal_document/legal_document_model.dart';
import '../../domain/entities/library_search_query.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/legal_document_local_datasource.dart';

/// Implémentation du [LibraryRepository] s'appuyant sur un
/// [LegalDocumentDataSource]. Conserve l'état des documents (favoris,
/// compteur de téléchargement) en mémoire pour la durée de la session.
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({required this.dataSource}) : _documents = List.of(dataSource.getAll());

  final LegalDocumentDataSource dataSource;
  final List<LegalDocument> _documents;

  @override
  List<LegalDocument> search(LibrarySearchQuery query) {
    final keyword = query.keyword.trim().toLowerCase();

    return _documents.where((document) {
      if (query.favoritesOnly && !document.isFavorite) return false;
      if (query.type != null && document.type != query.type) return false;
      if (query.domain != null && document.domain != query.domain) return false;
      if (query.dateFrom != null && document.datePublication.isBefore(query.dateFrom!)) {
        return false;
      }
      if (query.dateTo != null && document.datePublication.isAfter(query.dateTo!)) {
        return false;
      }
      if (keyword.isNotEmpty && !_matchesKeyword(document, keyword)) return false;
      return true;
    }).toList();
  }

  bool _matchesKeyword(LegalDocument document, String keyword) {
    final haystack = <String>[
      document.title,
      document.reference,
      document.summary,
      document.fullContent,
      ...document.tags,
    ].join(' | ').toLowerCase();
    return haystack.contains(keyword);
  }

  @override
  LegalDocument? findById(String id) {
    for (final document in _documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  @override
  LegalDocument toggleBookmark(String documentId) {
    final index = _documents.indexWhere((document) => document.id == documentId);
    if (index == -1) {
      throw ArgumentError('Document introuvable : $documentId');
    }
    final updated = _documents[index].copyWith(isFavorite: !_documents[index].isFavorite);
    _documents[index] = updated;
    return updated;
  }

  @override
  LegalDocument recordDownload(String documentId) {
    final index = _documents.indexWhere((document) => document.id == documentId);
    if (index == -1) {
      throw ArgumentError('Document introuvable : $documentId');
    }
    final updated = _documents[index].copyWith(downloadCount: _documents[index].downloadCount + 1);
    _documents[index] = updated;
    return updated;
  }
}
