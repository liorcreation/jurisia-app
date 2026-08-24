import 'drafting_request.dart';

/// Niveau de risque d'une clause identifiée lors d'un audit de contrat.
enum RiskLevel {
  faible,
  moyen,
  eleve;

  static RiskLevel fromName(String name) {
    return RiskLevel.values.firstWhere((value) => value.name == name, orElse: () => RiskLevel.moyen);
  }
}

extension RiskLevelLabel on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.faible:
        return 'Risque faible';
      case RiskLevel.moyen:
        return 'Risque moyen';
      case RiskLevel.eleve:
        return 'Risque élevé';
    }
  }
}

/// Une clause identifiée comme abusive ou à risque lors d'un audit, avec
/// une proposition de reformulation.
class ClauseRisk {
  const ClauseRisk({
    required this.clauseExcerpt,
    required this.riskLevel,
    required this.explanation,
    required this.suggestedRewrite,
  });

  final String clauseExcerpt;
  final RiskLevel riskLevel;
  final String explanation;
  final String suggestedRewrite;
}

/// Un texte de la bibliothèque juridique consulté par l'IA pour enrichir sa
/// réponse, restitué à titre de source.
class CitedLegalSource {
  const CitedLegalSource({required this.title, required this.reference});

  final String title;
  final String reference;
}

/// Résultat produit par le service IA professionnel : acte rédigé, note de
/// synthèse, ou audit de contrat avec ses risques identifiés.
class LegalDraftingResult {
  const LegalDraftingResult({
    required this.id,
    required this.mode,
    required this.title,
    required this.content,
    required this.generatedAt,
    this.risks = const [],
    this.citedSources = const [],
    this.isFavorite = false,
  });

  final String id;
  final DraftingMode mode;
  final String title;
  final String content;
  final DateTime generatedAt;

  /// Clauses à risque identifiées, renseigné uniquement en mode
  /// [DraftingMode.audit].
  final List<ClauseRisk> risks;

  final List<CitedLegalSource> citedSources;
  final bool isFavorite;

  LegalDraftingResult copyWith({
    String? content,
    List<ClauseRisk>? risks,
    List<CitedLegalSource>? citedSources,
    bool? isFavorite,
    DateTime? generatedAt,
  }) {
    return LegalDraftingResult(
      id: id,
      mode: mode,
      title: title,
      content: content ?? this.content,
      generatedAt: generatedAt ?? this.generatedAt,
      risks: risks ?? this.risks,
      citedSources: citedSources ?? this.citedSources,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
