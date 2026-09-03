import '../article_parser.dart';
import '../imported_document.dart';
import 'source_adapter.dart';

/// Adaptateur pour **legiburkina.bf** — la base de données juridique
/// **officielle** du Secrétariat Général du Gouvernement. À privilégier
/// systématiquement : c'est la source faisant autorité pour les lois,
/// décrets et arrêtés, et elle diffuse aussi le Journal Officiel du Faso.
///
/// La fiche d'un texte sur Légiburkina porte ses métadonnées (nature,
/// numéro, date de signature, date de publication au JO, état
/// d'abrogation/modification) dans un bloc structuré, et le texte intégral
/// dans le corps. Renseigner `contentSelector` / les sélecteurs de
/// métadonnées ci-dessous après inspection d'une fiche réelle.
class LegiburkinaAdapter implements SourceAdapter {
  const LegiburkinaAdapter();

  @override
  String get sourceName => 'Légiburkina';

  @override
  Future<ImportedDocument> fetch(String url, {Map<String, dynamic> overrides = const {}}) async {
    final text = await fetchPlainText(url, contentSelector: 'main, #content, .texte-integral');

    final base = ImportedDocument(
      id: 'doc-${slugify(url.split('/').where((s) => s.isNotEmpty).last)}',
      title: overrides['title'] as String? ?? 'Texte officiel',
      type: overrides['type'] as String? ?? 'loi',
      domain: overrides['domain'] as String? ?? 'autre',
      status: overrides['status'] as String? ?? 'enVigueur',
      officialSourceName: sourceName,
      sourceUrl: url,
      outline: parseOutline(text),
      articles: parseArticles(text),
      // TODO(legiburkina): extraire numéro / date de signature / date JO
      //   depuis le bloc de métadonnées de la fiche, une fois le HTML réel
      //   inspecté ; les fournir en attendant via `overrides`.
    );

    return withOverrides(base, overrides);
  }
}
