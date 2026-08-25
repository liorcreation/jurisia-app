import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../models/legal_document/legal_document_model.dart';
import '../../domain/entities/library_search_query.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/legal_document_local_datasource.dart';

/// Implémentation du [LibraryRepository] s'appuyant sur un
/// [LegalDocumentDataSource]. Conserve l'état des documents (favoris,
/// compteur de téléchargement) en mémoire pour une réactivité immédiate,
/// synchronisé en arrière-plan avec Supabase quand [supabaseClient] et
/// [userId] sont fournis — sinon se comporte comme un catalogue purement
/// local (utilisé tel quel par les tests).
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({required this.dataSource, this.supabaseClient, this.userId})
      : _documents = List.of(dataSource.getAll());

  final LegalDocumentDataSource dataSource;
  final SupabaseClient? supabaseClient;
  final String? userId;
  final List<LegalDocument> _documents;

  bool get _persistenceEnabled => supabaseClient != null && userId != null;

  @override
  Future<void> hydrate() async {
    if (!_persistenceEnabled) return;
    final client = supabaseClient!;

    try {
      final favoriteRows = await client
          .from('library_favorites')
          .select('document_id')
          .eq('user_id', userId!);
      final favoriteIds = (favoriteRows as List)
          .map((row) => row['document_id'] as String)
          .toSet();

      final statsRows = await client
          .from('library_document_stats')
          .select('document_id, download_count');
      final downloadCounts = {
        for (final row in statsRows as List) row['document_id'] as String: row['download_count'] as int,
      };

      for (var i = 0; i < _documents.length; i++) {
        final document = _documents[i];
        _documents[i] = document.copyWith(
          isFavorite: favoriteIds.contains(document.id),
          downloadCount: downloadCounts[document.id] ?? document.downloadCount,
        );
      }
    } catch (error) {
      // Meilleur effort : en cas d'échec réseau, la bibliothèque reste
      // utilisable avec l'état local par défaut (aucun favori, compteurs à
      // zéro) plutôt que de bloquer l'écran.
      // ignore: avoid_print
      print('Échec du chargement des favoris/téléchargements Supabase : $error');
    }
  }

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
    _persistBookmark(updated);
    return updated;
  }

  void _persistBookmark(LegalDocument document) {
    if (!_persistenceEnabled) return;
    final client = supabaseClient!;

    final future = document.isFavorite
        ? client.from('library_favorites').upsert({'user_id': userId, 'document_id': document.id})
        : client.from('library_favorites').delete().eq('user_id', userId!).eq('document_id', document.id);

    future.catchError((Object error) {
      // ignore: avoid_print
      print('Échec de synchronisation du favori ${document.id} : $error');
    });
  }

  @override
  LegalDocument recordDownload(String documentId) {
    final index = _documents.indexWhere((document) => document.id == documentId);
    if (index == -1) {
      throw ArgumentError('Document introuvable : $documentId');
    }
    final updated = _documents[index].copyWith(downloadCount: _documents[index].downloadCount + 1);
    _documents[index] = updated;
    _persistDownload(documentId);
    return updated;
  }

  void _persistDownload(String documentId) {
    if (!_persistenceEnabled) return;
    // Incrément atomique côté serveur : évite qu'un compteur lu-puis-réécrit
    // depuis deux appareils en parallèle ne perde un téléchargement.
    supabaseClient!.rpc('increment_download_count', params: {'doc_id': documentId}).catchError((
      Object error,
    ) {
      // ignore: avoid_print
      print('Échec de synchronisation du téléchargement $documentId : $error');
      return null;
    });
  }
}
