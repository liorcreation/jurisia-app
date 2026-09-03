import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'imported_document.dart';

/// Écrit un [ImportedDocument] dans Supabase via l'API REST (PostgREST), en
/// utilisant la **clé service_role** (jamais la clé anon) — seule habilitée
/// à écrire dans `legal_documents` / `legal_articles` d'après la RLS de
/// `migration_010`.
///
/// Variables d'environnement attendues :
///   SUPABASE_URL          ex. https://xxxx.supabase.co
///   SUPABASE_SERVICE_KEY  clé « service_role » du projet
class SupabaseWriter {
  SupabaseWriter({String? url, String? serviceKey})
      : _url = (url ?? Platform.environment['SUPABASE_URL'] ?? '').replaceAll(RegExp(r'/$'), ''),
        _key = serviceKey ?? Platform.environment['SUPABASE_SERVICE_KEY'] ?? '' {
    if (_url.isEmpty || _key.isEmpty) {
      throw StateError(
        'SUPABASE_URL et SUPABASE_SERVICE_KEY doivent être définis dans '
        "l'environnement avant `legal_import push`.",
      );
    }
  }

  final String _url;
  final String _key;

  Map<String, String> get _headers => {
        'apikey': _key,
        'Authorization': 'Bearer $_key',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      };

  /// Upsert de la fiche puis remplacement complet de ses articles.
  Future<void> push(ImportedDocument doc) async {
    final docRes = await http.post(
      Uri.parse('$_url/rest/v1/legal_documents?on_conflict=id'),
      headers: _headers,
      body: jsonEncode([doc.toDocumentRow()]),
    );
    _check(docRes, 'upsert legal_documents ${doc.id}');

    // Remise à zéro des articles existants pour ce document.
    final del = await http.delete(
      Uri.parse('$_url/rest/v1/legal_articles?document_id=eq.${doc.id}'),
      headers: _headers,
    );
    _check(del, 'delete legal_articles ${doc.id}');

    final rows = doc.toArticleRows();
    if (rows.isEmpty) return;

    // Insertion par lots de 200 articles.
    for (var i = 0; i < rows.length; i += 200) {
      final batch = rows.sublist(i, i + 200 > rows.length ? rows.length : i + 200);
      final res = await http.post(
        Uri.parse('$_url/rest/v1/legal_articles'),
        headers: _headers,
        body: jsonEncode(batch),
      );
      _check(res, 'insert legal_articles ${doc.id} [$i..]');
    }
  }

  void _check(http.Response res, String what) {
    if (res.statusCode >= 300) {
      throw HttpException('Supabase $what → ${res.statusCode} ${res.body}');
    }
  }
}
