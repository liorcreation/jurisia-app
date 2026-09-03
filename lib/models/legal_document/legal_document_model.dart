import 'package:equatable/equatable.dart';

import 'legal_domain.dart';

/// Nature d'un document de la bibliothèque juridique.
enum LegalDocumentType {
  constitution,
  code,
  loi,
  decret,
  arrete,
  jurisprudence,
  traite,
  modeleActe,
}

extension LegalDocumentTypeLabel on LegalDocumentType {
  String get label {
    switch (this) {
      case LegalDocumentType.constitution:
        return 'Constitution';
      case LegalDocumentType.code:
        return 'Code';
      case LegalDocumentType.loi:
        return 'Loi';
      case LegalDocumentType.decret:
        return 'Décret';
      case LegalDocumentType.arrete:
        return 'Arrêté';
      case LegalDocumentType.jurisprudence:
        return 'Jurisprudence';
      case LegalDocumentType.traite:
        return 'Traité';
      case LegalDocumentType.modeleActe:
        return "Modèle d'acte";
    }
  }
}

/// État d'un texte dans l'ordonnancement juridique.
enum LegalDocumentStatus { enVigueur, modifie, abroge, projet }

extension LegalDocumentStatusLabel on LegalDocumentStatus {
  String get label {
    switch (this) {
      case LegalDocumentStatus.enVigueur:
        return 'En vigueur';
      case LegalDocumentStatus.modifie:
        return 'En vigueur (modifié)';
      case LegalDocumentStatus.abroge:
        return 'Abrogé';
      case LegalDocumentStatus.projet:
        return 'Projet / avant-projet';
    }
  }

  static LegalDocumentStatus fromName(String? value) {
    for (final status in LegalDocumentStatus.values) {
      if (status.name == value) return status;
    }
    return LegalDocumentStatus.enVigueur;
  }
}

/// Un article d'un texte structuré (code, acte uniforme, loi article par
/// article). Le [path] porte la hiérarchie éditoriale (« Livre I », « Titre
/// II », « Chapitre 1 ») pour construire le sommaire.
class LegalArticle extends Equatable {
  const LegalArticle({
    required this.number,
    required this.text,
    this.heading = '',
    this.path = const [],
  });

  /// Numéro affiché (« 1 », « 12 bis », « L. 122-4 »…).
  final String number;

  /// Intitulé propre à l'article, s'il en a un.
  final String heading;

  /// Corps de l'article.
  final String text;

  /// Chemin hiérarchique (division éditoriale) menant à l'article.
  final List<String> path;

  Map<String, dynamic> toJson() => {
        'number': number,
        'heading': heading,
        'text': text,
        'path': path,
      };

  factory LegalArticle.fromJson(Map<String, dynamic> json) => LegalArticle(
        number: json['number'] as String,
        heading: json['heading'] as String? ?? '',
        text: json['text'] as String? ?? '',
        path: (json['path'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      );

  @override
  List<Object?> get props => [number, heading, text, path];
}

/// Un document juridique référencé dans la bibliothèque : texte officiel,
/// décision de justice ou modèle d'acte.
class LegalDocument extends Equatable {
  const LegalDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.domain,
    required this.reference,
    required this.datePublication,
    this.dateEntreeEnVigueur,
    this.status = LegalDocumentStatus.enVigueur,
    this.summary = '',
    this.fullContent = '',
    this.articles = const [],
    this.outline = const [],
    this.summaryOnly = false,
    this.officialSourceName,
    this.fileUrl,
    this.sourceUrl,
    this.tags = const [],
    this.relatedDocumentIds = const [],
    this.isFavorite = false,
    this.viewCount = 0,
    this.downloadCount = 0,
  });

  final String id;
  final String title;
  final LegalDocumentType type;
  final LegalDomain domain;

  /// Référence officielle : numéro d'article, de loi, de décret, ou
  /// numéro de répertoire pour une décision de justice.
  final String reference;

  final DateTime datePublication;
  final DateTime? dateEntreeEnVigueur;
  final LegalDocumentStatus status;

  final String summary;

  /// Texte intégral en prose (utilisé quand [articles] est vide).
  final String fullContent;

  /// Texte structuré article par article. Non vide ⇒ la visionneuse
  /// affiche un sommaire hiérarchique.
  final List<LegalArticle> articles;

  /// Plan éditorial du texte (« Livre I — Des personnes »…), affiché même
  /// lorsque le texte intégral n'a pas encore été importé.
  final List<String> outline;

  /// `true` lorsque le document ne porte encore qu'une **synthèse** (résumé,
  /// plan, lien vers la source) et non le texte intégral. Sert à afficher le
  /// bandeau « Résumé — texte intégral à venir ».
  final bool summaryOnly;

  /// Nom lisible de la source faisant autorité (« Légiburkina »,
  /// « Journal Officiel du Faso », « OHADA »…).
  final String? officialSourceName;

  final String? fileUrl;
  final String? sourceUrl;
  final List<String> tags;
  final List<String> relatedDocumentIds;
  final bool isFavorite;
  final int viewCount;
  final int downloadCount;

  /// `true` si le texte est disponible article par article.
  bool get isStructured => articles.isNotEmpty;

  /// `true` si la fiche n'expose qu'une synthèse : le drapeau [summaryOnly]
  /// est posé et aucun texte structuré n'est encore disponible.
  bool get awaitingFullText => summaryOnly && articles.isEmpty;

  /// `true` si le texte intégral (prose ou articles) est consultable dans
  /// l'application.
  bool get hasFullText => articles.isNotEmpty || fullContent.trim().isNotEmpty;

  LegalDocument copyWith({
    String? id,
    String? title,
    LegalDocumentType? type,
    LegalDomain? domain,
    String? reference,
    DateTime? datePublication,
    DateTime? dateEntreeEnVigueur,
    LegalDocumentStatus? status,
    String? summary,
    String? fullContent,
    List<LegalArticle>? articles,
    List<String>? outline,
    bool? summaryOnly,
    String? officialSourceName,
    String? fileUrl,
    String? sourceUrl,
    List<String>? tags,
    List<String>? relatedDocumentIds,
    bool? isFavorite,
    int? viewCount,
    int? downloadCount,
  }) {
    return LegalDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      domain: domain ?? this.domain,
      reference: reference ?? this.reference,
      datePublication: datePublication ?? this.datePublication,
      dateEntreeEnVigueur: dateEntreeEnVigueur ?? this.dateEntreeEnVigueur,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      fullContent: fullContent ?? this.fullContent,
      articles: articles ?? this.articles,
      outline: outline ?? this.outline,
      summaryOnly: summaryOnly ?? this.summaryOnly,
      officialSourceName: officialSourceName ?? this.officialSourceName,
      fileUrl: fileUrl ?? this.fileUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      tags: tags ?? this.tags,
      relatedDocumentIds: relatedDocumentIds ?? this.relatedDocumentIds,
      isFavorite: isFavorite ?? this.isFavorite,
      viewCount: viewCount ?? this.viewCount,
      downloadCount: downloadCount ?? this.downloadCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'domain': domain.name,
      'reference': reference,
      'datePublication': datePublication.toIso8601String(),
      'dateEntreeEnVigueur': dateEntreeEnVigueur?.toIso8601String(),
      'status': status.name,
      'summary': summary,
      'fullContent': fullContent,
      'articles': articles.map((a) => a.toJson()).toList(),
      'outline': outline,
      'summaryOnly': summaryOnly,
      'officialSourceName': officialSourceName,
      'fileUrl': fileUrl,
      'sourceUrl': sourceUrl,
      'tags': tags,
      'relatedDocumentIds': relatedDocumentIds,
      'isFavorite': isFavorite,
      'viewCount': viewCount,
      'downloadCount': downloadCount,
    };
  }

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      type: LegalDocumentType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => LegalDocumentType.loi,
      ),
      domain: LegalDomain.fromName(json['domain'] as String),
      reference: json['reference'] as String,
      datePublication: DateTime.parse(json['datePublication'] as String),
      dateEntreeEnVigueur: json['dateEntreeEnVigueur'] != null
          ? DateTime.parse(json['dateEntreeEnVigueur'] as String)
          : null,
      status: LegalDocumentStatusLabel.fromName(json['status'] as String?),
      summary: json['summary'] as String? ?? '',
      fullContent: json['fullContent'] as String? ?? '',
      articles: (json['articles'] as List<dynamic>? ?? const [])
          .map((e) => LegalArticle.fromJson(e as Map<String, dynamic>))
          .toList(),
      outline: (json['outline'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      summaryOnly: json['summaryOnly'] as bool? ?? false,
      officialSourceName: json['officialSourceName'] as String?,
      fileUrl: json['fileUrl'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      relatedDocumentIds: (json['relatedDocumentIds'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      viewCount: json['viewCount'] as int? ?? 0,
      downloadCount: json['downloadCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        domain,
        reference,
        datePublication,
        dateEntreeEnVigueur,
        status,
        summary,
        fullContent,
        articles,
        outline,
        summaryOnly,
        officialSourceName,
        fileUrl,
        sourceUrl,
        tags,
        relatedDocumentIds,
        isFavorite,
        viewCount,
        downloadCount,
      ];
}
