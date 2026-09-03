import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../imported_document.dart';

/// Contrat commun à toutes les sources. Un adaptateur sait, pour une URL
/// donnée, produire un [ImportedDocument] normalisé.
abstract class SourceAdapter {
  /// Nom lisible de la source (repris dans `official_source_name`).
  String get sourceName;

  /// Récupère et normalise le texte à [url]. [overrides] permet de renseigner
  /// à la main les métadonnées que la page ne porte pas (type, domain,
  /// reference, date…), sous la forme d'une map JSON partielle
  /// d'[ImportedDocument].
  Future<ImportedDocument> fetch(String url, {Map<String, dynamic> overrides = const {}});
}

/// Télécharge une page et renvoie son texte, un paragraphe par ligne, en
/// retirant scripts, styles, en-têtes de navigation et pieds de page.
Future<String> fetchPlainText(String url, {String? contentSelector}) async {
  final res = await http.get(
    Uri.parse(url),
    headers: {
      'User-Agent': 'JurisIA-legal-import/0.1 (+https://jurisia-app.pages.dev)',
      'Accept': 'text/html,application/xhtml+xml',
    },
  );
  if (res.statusCode >= 300) {
    throw Exception('GET $url → ${res.statusCode}');
  }

  final document = html_parser.parse(res.body);
  for (final tag in ['script', 'style', 'nav', 'header', 'footer', 'aside', 'noscript']) {
    for (final el in document.querySelectorAll(tag)) {
      el.remove();
    }
  }

  final root = contentSelector != null
      ? (document.querySelector(contentSelector) ?? document.body)
      : document.body;
  if (root == null) return '';

  final buffer = StringBuffer();
  for (final node in root.querySelectorAll('p, li, h1, h2, h3, h4, div')) {
    // On ne garde que les feuilles textuelles pour éviter les doublons.
    if (node.children.any((c) => ['P', 'LI', 'DIV'].contains(c.localName?.toUpperCase()))) {
      continue;
    }
    final text = node.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isNotEmpty) buffer.writeln(text);
  }
  return buffer.toString();
}

/// Applique une map de surcharges JSON à un document déjà construit.
ImportedDocument withOverrides(ImportedDocument base, Map<String, dynamic> o) {
  if (o.isEmpty) return base;
  final merged = base.toJson()..addAll(o);
  return ImportedDocument.fromJson(merged);
}

String slugify(String input) => input
    .toLowerCase()
    .replaceAll(RegExp(r"[àâä]"), 'a')
    .replaceAll(RegExp(r"[éèêë]"), 'e')
    .replaceAll(RegExp(r"[îï]"), 'i')
    .replaceAll(RegExp(r"[ôö]"), 'o')
    .replaceAll(RegExp(r"[ûü]"), 'u')
    .replaceAll(RegExp(r"[ç]"), 'c')
    .replaceAll(RegExp(r"[^a-z0-9]+"), '-')
    .replaceAll(RegExp(r"(^-|-$)"), '');
