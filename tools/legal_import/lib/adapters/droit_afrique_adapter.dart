import '../article_parser.dart';
import '../imported_document.dart';
import 'source_adapter.dart';

/// Adaptateur pour **droit-afrique.com**, qui publie les grands codes
/// burkinabè consolidés (travail, commerce, CGI, foncier, familles…) en HTML
/// et en PDF.
///
/// Pour le HTML, `fetchPlainText` + `parseArticles` suffisent dans la plupart
/// des cas. Pour un PDF, extraire d'abord le texte avec un outil externe
/// (`pdftotext -layout fichier.pdf fichier.txt`) puis passer le `.txt` à
/// `legal_import push` après l'avoir enveloppé en JSON (voir RUNBOOK,
/// section « Textes fournis en PDF »).
///
/// ⚠️ Vérifier les conditions d'utilisation de droit-afrique.com avant tout
/// import de masse ; privilégier Légiburkina (source officielle) quand le
/// texte y est disponible.
class DroitAfriqueAdapter implements SourceAdapter {
  const DroitAfriqueAdapter();

  @override
  String get sourceName => 'Droit-Afrique';

  @override
  Future<ImportedDocument> fetch(String url, {Map<String, dynamic> overrides = const {}}) async {
    final text = await fetchPlainText(url, contentSelector: '.entry-content, article, main');

    final base = ImportedDocument(
      id: 'doc-${slugify(url.split('/').where((s) => s.isNotEmpty).last)}',
      title: overrides['title'] as String? ?? 'Texte burkinabè',
      type: overrides['type'] as String? ?? 'code',
      domain: overrides['domain'] as String? ?? 'autre',
      status: 'modifie',
      officialSourceName: sourceName,
      sourceUrl: url,
      outline: parseOutline(text),
      articles: parseArticles(text),
    );

    return withOverrides(base, overrides);
  }
}
