import '../article_parser.dart';
import '../imported_document.dart';
import 'source_adapter.dart';

/// Adaptateur pour les Actes uniformes OHADA publiés en texte intégral sur
/// **ohada.org** / **ohada.com**. Les Actes uniformes sont des normes
/// communautaires librement diffusées.
///
/// La page d'un Acte uniforme présente le texte article par article dans le
/// corps principal ; `parseArticles` reconstitue la hiérarchie
/// LIVRE/TITRE/CHAPITRE et découpe sur « Article N ».
class OhadaAdapter implements SourceAdapter {
  const OhadaAdapter();

  @override
  String get sourceName => 'OHADA';

  @override
  Future<ImportedDocument> fetch(String url, {Map<String, dynamic> overrides = const {}}) async {
    // Le contenu utile est généralement dans #content / .article-content ;
    // on retombe sur <body> si le sélecteur ne matche pas.
    final text = await fetchPlainText(url, contentSelector: '#content, .item-page, article');

    final articles = parseArticles(text);
    final outline = parseOutline(text);

    // Titre : première ligne significative ou surcharge manuelle.
    final firstLine = text.split('\n').firstWhere(
          (l) => l.trim().length > 8,
          orElse: () => 'Acte uniforme OHADA',
        );

    final base = ImportedDocument(
      id: 'doc-ohada-${slugify(firstLine).split('-').take(4).join('-')}',
      title: firstLine.trim(),
      type: 'traite',
      domain: 'ohada',
      status: 'enVigueur',
      officialSourceName: sourceName,
      sourceUrl: url,
      outline: outline,
      tags: const ['OHADA'],
      articles: articles,
    );

    final doc = withOverrides(base, overrides);
    if (doc.articles.isEmpty) {
      throw Exception(
        "Aucun article détecté sur $url — vérifier le sélecteur de contenu "
        '(contentSelector) dans OhadaAdapter.',
      );
    }
    return doc;
  }
}
