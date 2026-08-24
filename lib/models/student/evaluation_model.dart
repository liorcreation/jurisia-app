import 'package:equatable/equatable.dart';

/// Type de question au sein d'une évaluation de fin de module.
enum QuestionType { qcm, casPratique }

/// Une question d'évaluation générée dynamiquement par l'IA : QCM à choix
/// multiples ou cas pratique à réponse rédigée.
class EvaluationQuestion extends Equatable {
  const EvaluationQuestion({
    required this.id,
    required this.type,
    required this.statement,
    required this.points,
    this.options = const [],
    this.correctOptionIndex,
    this.expectedAnswerElements = const [],
    this.explanation = '',
    this.studentAnswer,
    this.awardedPoints,
  });

  final String id;
  final QuestionType type;
  final String statement;

  /// Barème de la question.
  final double points;

  /// Options proposées, uniquement pour un [QuestionType.qcm].
  final List<String> options;

  /// Index de la bonne réponse dans [options], uniquement pour un
  /// [QuestionType.qcm].
  final int? correctOptionIndex;

  /// Éléments de correction attendus dans la réponse, utilisés par l'IA
  /// pour noter un [QuestionType.casPratique].
  final List<String> expectedAnswerElements;

  /// Explication pédagogique de la bonne réponse, affichée après correction.
  final String explanation;

  /// Réponse fournie par l'étudiant (index d'option sous forme de texte
  /// pour un QCM, texte libre pour un cas pratique).
  final String? studentAnswer;

  /// Points obtenus par l'étudiant sur cette question, une fois corrigée.
  final double? awardedPoints;

  EvaluationQuestion copyWith({
    String? id,
    QuestionType? type,
    String? statement,
    double? points,
    List<String>? options,
    int? correctOptionIndex,
    List<String>? expectedAnswerElements,
    String? explanation,
    String? studentAnswer,
    double? awardedPoints,
  }) {
    return EvaluationQuestion(
      id: id ?? this.id,
      type: type ?? this.type,
      statement: statement ?? this.statement,
      points: points ?? this.points,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      expectedAnswerElements: expectedAnswerElements ?? this.expectedAnswerElements,
      explanation: explanation ?? this.explanation,
      studentAnswer: studentAnswer ?? this.studentAnswer,
      awardedPoints: awardedPoints ?? this.awardedPoints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'statement': statement,
      'points': points,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'expectedAnswerElements': expectedAnswerElements,
      'explanation': explanation,
      'studentAnswer': studentAnswer,
      'awardedPoints': awardedPoints,
    };
  }

  factory EvaluationQuestion.fromJson(Map<String, dynamic> json) {
    return EvaluationQuestion(
      id: json['id'] as String,
      type: QuestionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => QuestionType.qcm,
      ),
      statement: json['statement'] as String,
      points: (json['points'] as num).toDouble(),
      options: (json['options'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
      correctOptionIndex: json['correctOptionIndex'] as int?,
      expectedAnswerElements: (json['expectedAnswerElements'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      explanation: json['explanation'] as String? ?? '',
      studentAnswer: json['studentAnswer'] as String?,
      awardedPoints: (json['awardedPoints'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        statement,
        points,
        options,
        correctOptionIndex,
        expectedAnswerElements,
        explanation,
        studentAnswer,
        awardedPoints,
      ];
}

/// Une évaluation de fin de module (QCM + cas pratiques), générée
/// dynamiquement par l'IA. La moyenne requise pour débloquer le module
/// suivant est de 10/20 ; en cas d'échec, une nouvelle tentative propose de
/// nouvelles questions.
class ModuleEvaluation extends Equatable {
  const ModuleEvaluation({
    required this.id,
    required this.moduleId,
    required this.attemptNumber,
    required this.questions,
    required this.generatedAt,
    this.maxScore = 20,
    this.passingScore = 10,
    this.score,
    this.completedAt,
  });

  final String id;
  final String moduleId;

  /// Numéro de la tentative pour ce module (1, 2, 3...).
  final int attemptNumber;

  final List<EvaluationQuestion> questions;
  final DateTime generatedAt;
  final double maxScore;
  final double passingScore;

  /// Score obtenu sur [maxScore], nul tant que l'évaluation n'est pas
  /// corrigée.
  final double? score;

  final DateTime? completedAt;

  bool get isCompleted => completedAt != null && score != null;
  bool get isPassed => isCompleted && score! >= passingScore;

  ModuleEvaluation copyWith({
    String? id,
    String? moduleId,
    int? attemptNumber,
    List<EvaluationQuestion>? questions,
    DateTime? generatedAt,
    double? maxScore,
    double? passingScore,
    double? score,
    DateTime? completedAt,
  }) {
    return ModuleEvaluation(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      questions: questions ?? this.questions,
      generatedAt: generatedAt ?? this.generatedAt,
      maxScore: maxScore ?? this.maxScore,
      passingScore: passingScore ?? this.passingScore,
      score: score ?? this.score,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moduleId': moduleId,
      'attemptNumber': attemptNumber,
      'questions': questions.map((q) => q.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'maxScore': maxScore,
      'passingScore': passingScore,
      'score': score,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ModuleEvaluation.fromJson(Map<String, dynamic> json) {
    return ModuleEvaluation(
      id: json['id'] as String,
      moduleId: json['moduleId'] as String,
      attemptNumber: json['attemptNumber'] as int,
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .map((q) => EvaluationQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 20,
      passingScore: (json['passingScore'] as num?)?.toDouble() ?? 10,
      score: (json['score'] as num?)?.toDouble(),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        moduleId,
        attemptNumber,
        questions,
        generatedAt,
        maxScore,
        passingScore,
        score,
        completedAt,
      ];
}
