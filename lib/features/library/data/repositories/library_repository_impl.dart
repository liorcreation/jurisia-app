import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../domain/entities/library_search_query.dart';
import '../../domain/entities/library_collection.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/legal_document_local_datasource.dart';

/// Implémentation du [LibraryRepository] s'appuyant sur un
/// [LegalDocumentDataSource]. Conserve l'état des documents (favoris,
/// compteur de téléchargement) en mémoire pour une réactivité immédiate,
/// synchronisé en arrière-plan avec Supabase quand [supabaseClient] et
/// [userId] sont fournis — sinon se comporte comme un catalogue purement
/// local (utilisé tel quel par les tests).
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({
    required this.dataSource,
    this.supabaseClient,
    this.userId,
    this.familyOnly = false,
    this.officialOnly = false,
  }) : _documents = List.of(dataSource.getAll());

  final LegalDocumentDataSource dataSource;
  final SupabaseClient? supabaseClient;
  final String? userId;
  final bool familyOnly;
  final bool officialOnly;
  final List<LegalDocument> _documents;

  bool get _persistenceEnabled => supabaseClient != null && userId != null;

  @override
  Future<void> hydrate() async {
    final client = supabaseClient;
    if (client == null) return;

    // 1. Corpus : le serveur (alimenté par tools/legal_import/) fait
    //    autorité ; le catalogue local ne subsiste que pour les textes que
    //    le serveur ne connaît pas encore, et hors ligne.
    await _mergeServerCorpus(client);

    // 2. État personnel : favoris + compteurs de téléchargement.
    if (!_persistenceEnabled) return;
    try {
      final rows = await Future.wait([
        client
            .from('library_favorites')
            .select('document_id')
            .eq('user_id', userId!),
        client
            .from('library_document_stats')
            .select('document_id, download_count'),
      ]);
      final favoriteRows = rows[0];
      final favoriteIds = (favoriteRows as List)
          .map((row) => row['document_id'] as String)
          .toSet();

      final statsRows = rows[1];
      final downloadCounts = {
        for (final row in statsRows as List)
          row['document_id'] as String: row['download_count'] as int,
      };

      for (var i = 0; i < _documents.length; i++) {
        final document = _documents[i];
        _documents[i] = document.copyWith(
          isFavorite: favoriteIds.contains(document.id),
          downloadCount: downloadCounts[document.id] ?? document.downloadCount,
        );
      }
    } catch (error) {
      // ignore: avoid_print
      print(
        'Échec du chargement des favoris/téléchargements Supabase : $error',
      );
    }
  }

  Future<void> _mergeServerCorpus(SupabaseClient client) async {
    try {
      List<dynamic> docRows;
      try {
        docRows = await client.from('legal_documents').select(
          'id,title,type,domain,reference,date_publication,date_entree_en_vigueur,status,summary,full_content,outline,summary_only,official_source_name,file_url,source_url,tags,related_ids,updated_at',
        );
      } catch (_) {
        // Compatibilité avec les environnements Supabase antérieurs à la
        // migration PDF : les documents restent consultables pendant que la
        // colonne file_url est déployée.
        docRows = await client.from('legal_documents').select(
          'id,title,type,domain,reference,date_publication,date_entree_en_vigueur,status,summary,full_content,outline,summary_only,official_source_name,source_url,tags,related_ids,updated_at',
        );
      }
      if (docRows.isEmpty) return;

      final articleRows = await client
          .from('legal_articles')
          .select('document_id,number,heading,body,path,ord')
          .order('ord');
      final articlesByDoc = <String, List<LegalArticle>>{};
      for (final row in articleRows as List) {
        final id = row['document_id'] as String;
        (articlesByDoc[id] ??= <LegalArticle>[]).add(
          LegalArticle(
            number: row['number'] as String,
            heading: row['heading'] as String? ?? '',
            text: row['body'] as String? ?? '',
            path:
                (row['path'] as List?)?.map((e) => e as String).toList() ??
                const [],
          ),
        );
      }

      DateTime? parseDate(Object? v) =>
          v == null ? null : DateTime.tryParse(v as String);

      final serverDocs = <LegalDocument>[
        for (final row in docRows)
          LegalDocument(
            id: row['id'] as String,
            title: row['title'] as String,
            type: LegalDocumentType.values.firstWhere(
              (t) => t.name == row['type'],
              orElse: () => LegalDocumentType.loi,
            ),
            domain: LegalDomain.fromName(row['domain'] as String),
            reference: row['reference'] as String? ?? '',
            datePublication:
                parseDate(row['date_publication']) ?? DateTime(2000),
            dateEntreeEnVigueur: parseDate(row['date_entree_en_vigueur']),
            status: LegalDocumentStatusLabel.fromName(row['status'] as String?),
            summary: row['summary'] as String? ?? '',
            fullContent: row['full_content'] as String? ?? '',
            articles: articlesByDoc[row['id']] ?? const [],
            outline:
                (row['outline'] as List?)?.map((e) => e as String).toList() ??
                const [],
            summaryOnly:
                (row['summary_only'] as bool? ?? false) &&
                (articlesByDoc[row['id']] ?? const []).isEmpty,
            officialSourceName: row['official_source_name'] as String?,
            fileUrl: row['file_url'] as String?,
            sourceUrl: row['source_url'] as String?,
            tags:
                (row['tags'] as List?)?.map((e) => e as String).toList() ??
                const [],
            relatedDocumentIds:
                (row['related_ids'] as List?)
                    ?.map((e) => e as String)
                    .toList() ??
                const [],
          ),
      ];

      // La Bibliothèque publique peut activer un périmètre éditorial fermé,
      // tandis que les modules professionnels gardent accès au catalogue
      // complet pour leurs recherches internes.
      final familyDocs = serverDocs
          .where(
            (document) =>
                (!familyOnly || document.domain == LegalDomain.famille) &&
                (!officialOnly || _isOfficialLibraryDocument(document)),
          )
          .toList(growable: false);
      final serverIds = familyDocs.map((d) => d.id).toSet();
      final localOnly = _documents
          .where((d) => !serverIds.contains(d.id))
          .toList();
      _documents
        ..clear()
        ..addAll(familyDocs)
        ..addAll(localOnly);
    } catch (error) {
      // Corpus serveur indisponible : on garde le catalogue local.
      // ignore: avoid_print
      print('Corpus Supabase indisponible, catalogue local utilisé : $error');
    }
  }

  bool _isOfficialLibraryDocument(LegalDocument document) {
    switch (document.type) {
      case LegalDocumentType.constitution:
      case LegalDocumentType.code:
      case LegalDocumentType.loi:
      case LegalDocumentType.decret:
      case LegalDocumentType.arrete:
      case LegalDocumentType.jurisprudence:
        return true;
      case LegalDocumentType.traite:
      case LegalDocumentType.doctrine:
      case LegalDocumentType.rapport:
      case LegalDocumentType.modeleActe:
        return false;
    }
  }

  @override
  List<LegalDocument> search(LibrarySearchQuery query) {
    final keyword = query.keyword.trim().toLowerCase();

    return _documents.where((document) {
      if (query.favoritesOnly && !document.isFavorite) return false;
      if (query.type != null && document.type != query.type) return false;
      if (query.domain != null && document.domain != query.domain) return false;
      if (query.collectionTag != null &&
          !documentBelongsToLibraryCollection(document, query.collectionTag!)) {
        return false;
      }
      if (query.dateFrom != null &&
          document.datePublication.isBefore(query.dateFrom!)) {
        return false;
      }
      if (query.dateTo != null &&
          document.datePublication.isAfter(query.dateTo!)) {
        return false;
      }
      if (keyword.isNotEmpty && !_matchesKeyword(document, keyword)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<LegalDocument>> searchCorpus(LibrarySearchQuery query) async {
    if (!_persistenceEnabled ||
        query.keyword.trim().isEmpty ||
        query.favoritesOnly) {
      return search(query);
    }

    try {
      final rows = await supabaseClient!.rpc(
        'search_legal_corpus',
        params: {
          'p_query': query.keyword.trim(),
          'p_type': query.type?.name,
          'p_domain': query.domain?.name,
          'p_limit': 100,
        },
      );
      final rankedIds = (rows as List)
          .map((row) => row['id'] as String)
          .toList(growable: false);
      final byId = {for (final document in _documents) document.id: document};
      final filtered = <LegalDocument>[];
      for (final id in rankedIds) {
        final document = byId[id];
        if (document == null) continue;
        if (query.dateFrom != null &&
            document.datePublication.isBefore(query.dateFrom!)) {
          continue;
        }
        if (query.dateTo != null &&
            document.datePublication.isAfter(query.dateTo!)) {
          continue;
        }
        if (query.collectionTag != null &&
            !documentBelongsToLibraryCollection(document, query.collectionTag!)) {
          continue;
        }
        filtered.add(document);
      }
      return filtered;
    } catch (error) {
      // ignore: avoid_print
      print(
        'Recherche plein texte indisponible, recherche locale utilisée : $error',
      );
      return search(query);
    }
  }

  bool _matchesKeyword(LegalDocument document, String keyword) {
    final haystack = <String>[
      document.title,
      document.reference,
      document.summary,
      document.fullContent,
      ...document.outline,
      ...document.tags,
      for (final article in document.articles)
        '${article.number} ${article.heading} ${article.text}',
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
    final index = _documents.indexWhere(
      (document) => document.id == documentId,
    );
    if (index == -1) {
      throw ArgumentError('Document introuvable : $documentId');
    }
    final updated = _documents[index].copyWith(
      isFavorite: !_documents[index].isFavorite,
    );
    _documents[index] = updated;
    _persistBookmark(updated);
    return updated;
  }

  void _persistBookmark(LegalDocument document) {
    if (!_persistenceEnabled) return;
    final client = supabaseClient!;

    final future = document.isFavorite
        ? client.from('library_favorites').upsert({
            'user_id': userId,
            'document_id': document.id,
          })
        : client
              .from('library_favorites')
              .delete()
              .eq('user_id', userId!)
              .eq('document_id', document.id);

    future.catchError((Object error) {
      // ignore: avoid_print
      print('Échec de synchronisation du favori ${document.id} : $error');
    });
  }

  @override
  LegalDocument recordDownload(String documentId) {
    final index = _documents.indexWhere(
      (document) => document.id == documentId,
    );
    if (index == -1) {
      throw ArgumentError('Document introuvable : $documentId');
    }
    final updated = _documents[index].copyWith(
      downloadCount: _documents[index].downloadCount + 1,
    );
    _documents[index] = updated;
    _persistDownload(documentId);
    return updated;
  }

  void _persistDownload(String documentId) {
    if (!_persistenceEnabled) return;
    // Incrément atomique côté serveur : évite qu'un compteur lu-puis-réécrit
    // depuis deux appareils en parallèle ne perde un téléchargement.
    supabaseClient!
        .rpc('increment_download_count', params: {'doc_id': documentId})
        .catchError((Object error) {
          // ignore: avoid_print
          print(
            'Échec de synchronisation du téléchargement $documentId : $error',
          );
          return null;
        });
  }
}
