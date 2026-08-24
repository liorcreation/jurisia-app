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
    this.summary = '',
    this.fullContent = '',
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

  final String summary;
  final String fullContent;
  final String? fileUrl;
  final String? sourceUrl;
  final List<String> tags;
  final List<String> relatedDocumentIds;
  final bool isFavorite;
  final int viewCount;
  final int downloadCount;

  LegalDocument copyWith({
    String? id,
    String? title,
    LegalDocumentType? type,
    LegalDomain? domain,
    String? reference,
    DateTime? datePublication,
    DateTime? dateEntreeEnVigueur,
    String? summary,
    String? fullContent,
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
      summary: summary ?? this.summary,
      fullContent: fullContent ?? this.fullContent,
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
      'summary': summary,
      'fullContent': fullContent,
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
      summary: json['summary'] as String? ?? '',
      fullContent: json['fullContent'] as String? ?? '',
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
        summary,
        fullContent,
        fileUrl,
        sourceUrl,
        tags,
        relatedDocumentIds,
        isFavorite,
        viewCount,
        downloadCount,
      ];
}
