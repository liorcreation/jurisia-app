/// Ajustement rapide applicable à un document déjà généré, depuis la barre
/// d'outils de l'espace de rédaction.
enum QuickAdjustment { stricter, simplifyJargon, addConfidentiality, adjustPenalties }

extension QuickAdjustmentDetails on QuickAdjustment {
  String get label {
    switch (this) {
      case QuickAdjustment.stricter:
        return 'Rendre plus strict';
      case QuickAdjustment.simplifyJargon:
        return 'Simplifier le jargon';
      case QuickAdjustment.addConfidentiality:
        return 'Ajouter une clause de confidentialité';
      case QuickAdjustment.adjustPenalties:
        return 'Modifier les pénalités';
    }
  }

  /// Instruction transmise à l'IA pour appliquer cet ajustement.
  String get instruction {
    switch (this) {
      case QuickAdjustment.stricter:
        return 'Renforce la rigueur juridique du document : précise les obligations de chaque '
            'partie, ajoute les garanties et sanctions nécessaires en cas de manquement, et '
            'réduis toute ambiguïté de rédaction.';
      case QuickAdjustment.simplifyJargon:
        return 'Reformule le document dans un langage plus clair et accessible, en conservant '
            'intégralement sa portée juridique, mais en réduisant le jargon technique superflu.';
      case QuickAdjustment.addConfidentiality:
        return 'Ajoute une clause de confidentialité complète et équilibrée, adaptée à ce type de '
            'document, couvrant la durée de l\'obligation et les exceptions usuelles.';
      case QuickAdjustment.adjustPenalties:
        return 'Revois les clauses de pénalités et de sanctions en cas de manquement pour '
            'qu\'elles soient plus précises, proportionnées et opposables.';
    }
  }
}
