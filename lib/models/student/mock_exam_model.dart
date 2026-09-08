import 'package:equatable/equatable.dart';

import 'evaluation_model.dart';

/// Format choisi par l'étudiant pour tenter l'examen blanc de fin de niveau.
enum MockExamMode { qcmTimed, written, oral }

/// Un examen blanc de fin de niveau (L1, L2…), distinct du quiz de fin de
/// module existant ([ModuleEvaluation]) : porte sur l'ensemble des modules
/// du niveau, noté sur 20, avec un seuil de réussite à 10/20.
class MockExam extends Equatable {
  const MockExam({
    required this.id,
    required this.levelId,
    required this.mode,
    required this.questions,
    required this.generatedAt,
    this.maxScore = 20,
    this.passingScore = 10,
    this.score,
    this.completedAt,
    this.isReducedFallback = false,
  });

  final String id;

  /// [AcademicLevel.name] du niveau concerné (l1, l2, l3, m1, m2).
  final String levelId;
  final MockExamMode mode;
  final List<EvaluationQuestion> questions;
  final DateTime generatedAt;
  final double maxScore;
  final double passingScore;

  /// Score obtenu sur [maxScore], nul tant que l'examen n'est pas corrigé.
  final double? score;
  final DateTime? completedAt;

  /// `true` si les questions proviennent du repli local réduit (IA
  /// indisponible) plutôt que du jeu complet généré par l'IA — l'UI doit
  /// alors le signaler clairement plutôt que de prétendre un examen complet.
  final bool isReducedFallback;

  bool get isCompleted => completedAt != null && score != null;
  bool get isPassed => isCompleted && score! >= passingScore;

  MockExam copyWith({
    String? id,
    String? levelId,
    MockExamMode? mode,
    List<EvaluationQuestion>? questions,
    DateTime? generatedAt,
    double? maxScore,
    double? passingScore,
    double? score,
    DateTime? completedAt,
    bool? isReducedFallback,
  }) {
    return MockExam(
      id: id ?? this.id,
      levelId: levelId ?? this.levelId,
      mode: mode ?? this.mode,
      questions: questions ?? this.questions,
      generatedAt: generatedAt ?? this.generatedAt,
      maxScore: maxScore ?? this.maxScore,
      passingScore: passingScore ?? this.passingScore,
      score: score ?? this.score,
      completedAt: completedAt ?? this.completedAt,
      isReducedFallback: isReducedFallback ?? this.isReducedFallback,
    );
  }

  @override
  List<Object?> get props => [
        id,
        levelId,
        mode,
        questions,
        generatedAt,
        maxScore,
        passingScore,
        score,
        completedAt,
        isReducedFallback,
      ];
}

/// État du verrou de réécriture d'un niveau après un échec à l'examen blanc.
/// Débloqué seulement quand [isLocked] est faux ET [requiresCourseReview]
/// est faux — les deux conditions sont indépendantes et doivent être levées
/// séparément (le délai de 7 jours d'un côté, la reconsultation du cours de
/// l'autre).
class MockExamLockState extends Equatable {
  const MockExamLockState({
    required this.levelId,
    this.lockedUntil,
    this.requiresCourseReview = false,
  });

  final String levelId;
  final DateTime? lockedUntil;
  final bool requiresCourseReview;

  bool get isLocked => lockedUntil != null && DateTime.now().isBefore(lockedUntil!);
  bool get canRetry => !isLocked && !requiresCourseReview;

  Duration? get remaining => isLocked ? lockedUntil!.difference(DateTime.now()) : null;

  MockExamLockState copyWith({
    String? levelId,
    DateTime? lockedUntil,
    bool? requiresCourseReview,
    bool clearLock = false,
  }) {
    return MockExamLockState(
      levelId: levelId ?? this.levelId,
      lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
      requiresCourseReview: requiresCourseReview ?? this.requiresCourseReview,
    );
  }

  factory MockExamLockState.fromJson(Map<String, dynamic> json) {
    return MockExamLockState(
      levelId: json['level_id'] as String,
      lockedUntil: json['locked_until'] != null ? DateTime.parse(json['locked_until'] as String) : null,
      requiresCourseReview: json['requires_course_review'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [levelId, lockedUntil, requiresCourseReview];
}
