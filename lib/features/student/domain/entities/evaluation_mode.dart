import 'dart:math';

/// Formats d'évaluation proposés à la fin de chaque module.
enum EvaluationMode { timedQcm, written, voice }

extension EvaluationModeDetails on EvaluationMode {
  String get label => switch (this) {
        EvaluationMode.timedQcm => 'QCM diapos chronométrées',
        EvaluationMode.written => 'Devoir questions-réponses',
        EvaluationMode.voice => 'Examen oral Voice Mode',
      };

  String get shortLabel => switch (this) {
        EvaluationMode.timedQcm => 'QCM 5 secondes',
        EvaluationMode.written => 'Devoir analytique',
        EvaluationMode.voice => 'Voice Mode',
      };

  String get description => switch (this) {
        EvaluationMode.timedQcm =>
          '40 diapositives, 5 secondes par question, pour tester vos réflexes juridiques.',
        EvaluationMode.written =>
          '18 questions et cas pratiques, corrigés analytiquement par JurisIA.',
        EvaluationMode.voice =>
          '14 questions contextualisées avec synthèse vocale, reconnaissance vocale et orbe réactive.',
      };

  int get questionCount => switch (this) {
        EvaluationMode.timedQcm => 40,
        EvaluationMode.written => 18,
        EvaluationMode.voice => 14,
      };

  bool get isTimed => this == EvaluationMode.timedQcm;
  bool get isVoice => this == EvaluationMode.voice;
}

/// Sélection locale, imprévisible et testable du format d'évaluation.
///
/// Le contexte du module est fourni à l'appelant pour que le choix soit
/// déclenché au moment de l'évaluation, sans dépendre d'un aller-retour réseau
/// qui pourrait retarder l'armement du plein écran et du proctoring.
class EvaluationModeSelector {
  EvaluationModeSelector({Random? random}) : _random = random ?? Random();

  final Random _random;

  EvaluationMode select({required String moduleId}) {
    // La lecture du module est volontairement effectuée avant cet appel dans
    // le repository. Le moduleId reste un paramètre explicite pour éviter un
    // tirage global détaché du contexte d'examen.
    if (moduleId.trim().isEmpty) {
      throw ArgumentError.value(moduleId, 'moduleId', 'Le module est requis.');
    }
    return EvaluationMode.values[_random.nextInt(EvaluationMode.values.length)];
  }
}
