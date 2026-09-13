import '../legal_document/legal_domain.dart';

/// Parcours de formation proposé par JurisIA.
enum TrainingType { certifying, lmd }

extension TrainingTypeDetails on TrainingType {
  String get label => switch (this) {
    TrainingType.certifying => 'Formation certifiante',
    TrainingType.lmd => 'Système LMD',
  };

  String get databaseValue => name;
}

/// Catégorie thématique affichée dans le catalogue de formations.
///
/// [isAvailable] est distinct de [trainingType] : le catalogue peut ainsi
/// présenter un parcours futur sans le rendre sélectionnable.
class TrainingCategory {
  const TrainingCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.trainingType,
    required this.isAvailable,
    required this.domain,
    required this.icon,
    this.subtitle,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String description;
  final TrainingType trainingType;
  final bool isAvailable;
  final LegalDomain domain;
  final String icon;
  final String? subtitle;
  final int sortOrder;

  factory TrainingCategory.fromJson(Map<String, dynamic> json) {
    final rawType = (json['training_type'] ?? json['trainingType'])?.toString();
    final rawDomain = json['domain']?.toString();
    return TrainingCategory(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      trainingType: TrainingType.values.firstWhere(
        (value) => value.name == rawType,
        orElse: () => TrainingType.certifying,
      ),
      isAvailable:
          json['is_available'] as bool? ??
          json['isAvailable'] as bool? ??
          false,
      domain: LegalDomain.values.firstWhere(
        (value) => value.name == rawDomain,
        orElse: () => LegalDomain.autre,
      ),
      icon: json['icon']?.toString() ?? 'school',
      subtitle: (json['subtitle'] as String?)?.trim().isEmpty == true
          ? null
          : json['subtitle']?.toString(),
      sortOrder: (json['sort_order'] ?? json['sortOrder']) as int? ?? 0,
    );
  }

  TrainingCategory copyWith({
    String? title,
    String? description,
    TrainingType? trainingType,
    bool? isAvailable,
    LegalDomain? domain,
    String? icon,
    String? subtitle,
    int? sortOrder,
  }) {
    return TrainingCategory(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      trainingType: trainingType ?? this.trainingType,
      isAvailable: isAvailable ?? this.isAvailable,
      domain: domain ?? this.domain,
      icon: icon ?? this.icon,
      subtitle: subtitle ?? this.subtitle,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'trainingType': trainingType.name,
    'isAvailable': isAvailable,
    'domain': domain.name,
    'icon': icon,
    'subtitle': subtitle,
    'sortOrder': sortOrder,
  };

  /// Projection prête à être envoyée à Supabase (colonnes snake_case).
  Map<String, dynamic> toDatabaseRow() => {
    'id': id,
    'title': title,
    'description': description,
    'training_type': trainingType.databaseValue,
    'is_available': isAvailable,
    'domain': domain.name,
    'icon': icon,
    'subtitle': subtitle,
    'sort_order': sortOrder,
  };
}
