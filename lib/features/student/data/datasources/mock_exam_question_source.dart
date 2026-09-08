import 'dart:math';

import '../../../../models/student/course_module.dart';
import '../../../../models/student/evaluation_model.dart';
import 'ai_evaluation_generator.dart';
import 'evaluation_question_bank.dart';

/// Jeu de questions généré pour une tentative d'examen blanc, accompagné du
/// signalement honnête d'un repli réduit (voir [isReducedFallback]).
class MockExamQuestionSet {
  const MockExamQuestionSet({required this.questions, required this.isReducedFallback});

  final List<EvaluationQuestion> questions;
  final bool isReducedFallback;
}

/// Compose le jeu de questions d'un examen blanc de fin de niveau : appelle
/// l'IA (déjà branchée sur Groq) sur l'ensemble des modules du niveau, avec
/// un repli local honnête si l'IA est indisponible ou échoue. Toutes les
/// questions sont désormais des questions ouvertes destinées à être posées
/// et répondues à voix haute (conversation vocale unique — plus de format
/// QCM/écrit/oral séparés).
class MockExamQuestionSource {
  MockExamQuestionSource({
    required this.questionBank,
    this.aiGenerator,
    Random? random,
  }) : _random = random ?? Random();

  final EvaluationQuestionBank questionBank;
  final AiEvaluationGenerator? aiGenerator;
  final Random _random;

  /// Nombre de questions de l'examen blanc — repère entre l'ancien devoir
  /// écrit (18) et l'ancien oral (8), pour un entretien vocal complet mais
  /// pas exténuant.
  static const int questionCount = 14;

  Future<MockExamQuestionSet> generate({required List<CourseModule> levelModules}) async {
    List<EvaluationQuestion> questions;
    var isReducedFallback = false;

    if (aiGenerator != null) {
      try {
        questions = await aiGenerator!.generateForLevel(modules: levelModules, questionCount: questionCount);
      } catch (_) {
        (questions, isReducedFallback) = _localFallback(levelModules);
      }
    } else {
      (questions, isReducedFallback) = _localFallback(levelModules);
    }

    // Chaque question pèse une part égale du total de 20 points, quelle que
    // soit sa source — l'IA ne respecte pas toujours le barème demandé, et
    // le repli local utilise un barème fixe de 5 points pensé pour le quiz
    // de module (4 questions), pas pour un examen de 14 questions.
    final perQuestion = questions.isEmpty ? 0.0 : 20 / questions.length;
    final rescaled = questions.map((q) => q.copyWith(points: perQuestion)).toList();

    return MockExamQuestionSet(questions: rescaled, isReducedFallback: isReducedFallback);
  }

  (List<EvaluationQuestion>, bool) _localFallback(List<CourseModule> levelModules) {
    final candidates = <EvaluationQuestion>[];
    for (final module in levelModules) {
      candidates.addAll(
        questionBank.candidatesFor(module.id).where((q) => q.type == QuestionType.casPratique),
      );
    }
    candidates.shuffle(_random);

    if (candidates.length >= questionCount) {
      return (candidates.take(questionCount).toList(), false);
    }
    // Repli réduit assumé : jamais de questions fabriquées ou répétées en
    // silence pour atteindre artificiellement le compte demandé.
    return (candidates, true);
  }
}
