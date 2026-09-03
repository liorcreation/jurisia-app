/// Forme normalisée d'un texte juridique, prête à être écrite dans
/// `legal_documents` / `legal_articles`. Un adaptateur de source produit
/// exclusivement des objets de ce type.
class ImportedDocument {
  ImportedDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.domain,
    this.reference = '',
    this.datePublication,
    this.dateEntreeEnVigueur,
    this.status = 'enVigueur',
    this.summary = '',
    this.fullContent = '',
    this.outline = const [],
    this.officialSourceName,
    this.sourceUrl,
    this.tags = const [],
    this.relatedIds = const [],
    this.articles = const [],
  });

  /// Identifiant stable (`doc-<slug>`), réutilisé à chaque réimport pour
  /// mettre à jour la même ligne.
  final String id;
  final String title;

  /// constitution | code | loi | decret | arrete | jurisprudence | traite | modeleActe
  final String type;

  /// civil | penal | commercial | travail | famille | administratif | fiscal |
  /// constitutionnel | foncier | ohada | procedureCivile | procedurePenale | autre
  final String domain;

  final String reference;
  final DateTime? datePublication;
  final DateTime? dateEntreeEnVigueur;

  /// enVigueur | modifie | abroge | projet
  final String status;

  final String summary;

  /// Prose intégrale (laisser vide si le texte est fourni article par article).
  final String fullContent;

  final List<String> outline;
  final String? officialSourceName;
  final String? sourceUrl;
  final List<String> tags;
  final List<String> relatedIds;
  final List<ImportedArticle> articles;

  Map<String, dynamic> toDocumentRow() => {
        'id': id,
        'title': title,
        'type': type,
        'domain': domain,
        'reference': reference,
        'date_publication': _date(datePublication),
        'date_entree_en_vigueur': _date(dateEntreeEnVigueur),
        'status': status,
        'summary': summary,
        'full_content': fullContent,
        'outline': outline,
        'official_source_name': officialSourceName,
        'source_url': sourceUrl,
        'tags': tags,
        'related_ids': relatedIds,
        'imported_at': DateTime.now().toUtc().toIso8601String(),
      };

  List<Map<String, dynamic>> toArticleRows() => [
        for (var i = 0; i < articles.length; i++)
          {
            'document_id': id,
            'ord': i,
            'number': articles[i].number,
            'heading': articles[i].heading,
            'body': articles[i].body,
            'path': articles[i].path,
          },
      ];

  Map<String, dynamic> toJson() => {
        ...toDocumentRow(),
        'articles': [for (final a in articles) a.toJson()],
      };

  static ImportedDocument fromJson(Map<String, dynamic> j) => ImportedDocument(
        id: j['id'] as String,
        title: j['title'] as String,
        type: j['type'] as String,
        domain: j['domain'] as String,
        reference: j['reference'] as String? ?? '',
        datePublication: _parse(j['date_publication']),
        dateEntreeEnVigueur: _parse(j['date_entree_en_vigueur']),
        status: j['status'] as String? ?? 'enVigueur',
        summary: j['summary'] as String? ?? '',
        fullContent: j['full_content'] as String? ?? '',
        outline: (j['outline'] as List?)?.cast<String>() ?? const [],
        officialSourceName: j['official_source_name'] as String?,
        sourceUrl: j['source_url'] as String?,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        relatedIds: (j['related_ids'] as List?)?.cast<String>() ?? const [],
        articles: [
          for (final a in (j['articles'] as List? ?? const []))
            ImportedArticle.fromJson(a as Map<String, dynamic>),
        ],
      );

  static String? _date(DateTime? d) =>
      d == null ? null : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parse(Object? v) => v == null ? null : DateTime.tryParse(v as String);
}

class ImportedArticle {
  ImportedArticle({
    required this.number,
    required this.body,
    this.heading = '',
    this.path = const [],
  });

  final String number;
  final String heading;
  final String body;
  final List<String> path;

  Map<String, dynamic> toJson() => {
        'number': number,
        'heading': heading,
        'body': body,
        'path': path,
      };

  static ImportedArticle fromJson(Map<String, dynamic> j) => ImportedArticle(
        number: j['number'] as String,
        heading: j['heading'] as String? ?? '',
        body: j['body'] as String? ?? '',
        path: (j['path'] as List?)?.cast<String>() ?? const [],
      );
}
