import 'dart:math';

import '../../../../models/student/course_module.dart';
import '../../../../models/student/evaluation_model.dart';
import '../../../../models/student/mock_exam_model.dart';
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
/// un repli local honnête si l'IA est indisponible ou échoue.
class MockExamQuestionSource {
  MockExamQuestionSource({
    required this.questionBank,
    this.aiGenerator,
    Random? random,
  }) : _random = random ?? Random();

  final EvaluationQuestionBank questionBank;
  final AiEvaluationGenerator? aiGenerator;
  final Random _random;

  /// 40 questions QCM à 5 secondes, notées sur 20.
  static const int qcmTimedQuestionCount = 40;

  /// Devoir écrit : 16 à 20 questions, on en fixe 18.
  static const int writtenQuestionCount = 18;

  /// Examen oral : un jeu volontairement plus court, les questions étant
  /// posées et répondues à voix haute plutôt que lues et cochées — le
  /// porteur n'a pas fixé de nombre pour ce mode, 8 questions gardent
  /// l'épreuve orale dans une durée raisonnable.
  static const int oralQuestionCount = 8;

  int questionCountFor(MockExamMode mode) {
    switch (mode) {
      case MockExamMode.qcmTimed:
        return qcmTimedQuestionCount;
      case MockExamMode.written:
        return writtenQuestionCount;
      case MockExamMode.oral:
        return oralQuestionCount;
    }
  }

  bool _isWrittenOnly(MockExamMode mode) => mode != MockExamMode.qcmTimed;

  Future<MockExamQuestionSet> generate({
    required List<CourseModule> levelModules,
    required MockExamMode mode,
  }) async {
    final questionCount = questionCountFor(mode);
    final writtenOnly = _isWrittenOnly(mode);

    List<EvaluationQuestion> questions;
    var isReducedFallback = false;

    if (aiGenerator != null) {
      try {
        questions = await aiGenerator!.generateForLevel(
          modules: levelModules,
          questionCount: questionCount,
          writtenOnly: writtenOnly,
        );
      } catch (_) {
        (questions, isReducedFallback) = _localFallback(levelModules, questionCount, writtenOnly);
      }
    } else {
      (questions, isReducedFallback) = _localFallback(levelModules, questionCount, writtenOnly);
    }

    // Chaque question pèse une part égale du total de 20 points, quelle que
    // soit sa source — l'IA ne respecte pas toujours le barème demandé, et
    // le repli local utilise un barème fixe de 5 points pensé pour le quiz
    // de module (4 questions), pas pour un examen de 8 à 40 questions.
    final perQuestion = questions.isEmpty ? 0.0 : 20 / questions.length;
    final rescaled = questions.map((q) => q.copyWith(points: perQuestion)).toList();

    return MockExamQuestionSet(questions: rescaled, isReducedFallback: isReducedFallback);
  }

  (List<EvaluationQuestion>, bool) _localFallback(
    List<CourseModule> levelModules,
    int questionCount,
    bool writtenOnly,
  ) {
    final candidates = <EvaluationQuestion>[];
    for (final module in levelModules) {
      final moduleCandidates = questionBank.candidatesFor(module.id);
      candidates.addAll(
        writtenOnly
            ? moduleCandidates.where((q) => q.type == QuestionType.casPratique)
            : moduleCandidates.where((q) => q.type == QuestionType.qcm),
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
