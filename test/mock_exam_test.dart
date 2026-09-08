import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jurisia_app/core/ai/groq_api_datasource.dart';
import 'package:jurisia_app/features/student/data/datasources/ai_answer_grader.dart';
import 'package:jurisia_app/features/student/data/datasources/evaluation_question_bank.dart';
import 'package:jurisia_app/features/student/data/datasources/mock_exam_question_source.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';
import 'package:jurisia_app/models/student/course_module.dart';
import 'package:jurisia_app/models/student/evaluation_model.dart';
import 'package:jurisia_app/models/student/mock_exam_model.dart';
import 'package:jurisia_app/models/student/student_level.dart';

http.StreamedResponse _sse(String body) {
  return http.StreamedResponse(Stream.value(utf8.encode(body)), 200);
}

CourseModule _module(String id, int order) {
  return CourseModule(
    id: id,
    level: AcademicLevel.l1,
    order: order,
    title: 'Module $id',
    description: 'desc',
    domain: LegalDomain.civil,
  );
}

void main() {
  group('MockExamLockState', () {
    test('canRetry est vrai sans aucun verrou', () {
      const state = MockExamLockState(levelId: 'l1');
      expect(state.isLocked, isFalse);
      expect(state.canRetry, isTrue);
    });

    test('isLocked est vrai tant que lockedUntil est dans le futur', () {
      final state = MockExamLockState(
        levelId: 'l1',
        lockedUntil: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(state.isLocked, isTrue);
      expect(state.canRetry, isFalse);
    });

    test('canRetry reste faux tant que requiresCourseReview est vrai, même le délai écoulé', () {
      final state = MockExamLockState(
        levelId: 'l1',
        lockedUntil: DateTime.now().subtract(const Duration(hours: 1)),
        requiresCourseReview: true,
      );
      expect(state.isLocked, isFalse);
      expect(state.canRetry, isFalse);
    });

    test('canRetry redevient vrai une fois les deux conditions levées', () {
      final state = MockExamLockState(
        levelId: 'l1',
        lockedUntil: DateTime.now().subtract(const Duration(hours: 1)),
        requiresCourseReview: false,
      );
      expect(state.canRetry, isTrue);
    });
  });

  group('MockExamQuestionSource — repli local', () {
    test('signale isReducedFallback quand la banque locale ne suffit pas pour 40 questions', () async {
      final source = MockExamQuestionSource(questionBank: const LocalEvaluationQuestionBank());
      final result = await source.generate(
        levelModules: [_module('l1-module-1', 1), _module('l1-module-2', 2), _module('l1-module-3', 3)],
        mode: MockExamMode.qcmTimed,
      );

      // La banque locale ne compte que 4 QCM par module réel (l1-module-1..3).
      expect(result.isReducedFallback, isTrue);
      expect(result.questions.length, lessThan(MockExamQuestionSource.qcmTimedQuestionCount));
    });

    test('répartit toujours 20 points au total, quel que soit le nombre de questions', () async {
      final source = MockExamQuestionSource(questionBank: const LocalEvaluationQuestionBank());
      final result = await source.generate(
        levelModules: [_module('l1-module-1', 1)],
        mode: MockExamMode.qcmTimed,
      );

      final total = result.questions.fold<double>(0, (sum, q) => sum + q.points);
      expect(total, closeTo(20, 0.01));
    });

    test('le mode écrit ne tire que des questions de type casPratique', () async {
      final source = MockExamQuestionSource(questionBank: const LocalEvaluationQuestionBank());
      final result = await source.generate(
        levelModules: [_module('l1-module-1', 1), _module('l1-module-2', 2)],
        mode: MockExamMode.written,
      );

      expect(result.questions, isNotEmpty);
      expect(result.questions.every((q) => q.type == QuestionType.casPratique), isTrue);
    });
  });

  group('AiAnswerGrader', () {
    const question = EvaluationQuestion(
      id: 'q1',
      type: QuestionType.casPratique,
      statement: 'Expliquez la hiérarchie des normes.',
      points: 5,
      expectedAnswerElements: ['hiérarchie des normes', 'constitution'],
      studentAnswer: 'La constitution prime sur la loi, selon la hiérarchie des normes.',
    );

    test('utilise la fraction renvoyée par une réponse IA valide', () async {
      final client = MockClient.streaming((request, _) async {
        const payload = '{"fraction":0.8,"justification":"Bonne réponse, un élément manquant."}';
        return _sse('data: {"choices":[{"delta":{"content":${jsonEncode(payload)}}}]}\n\ndata: [DONE]\n\n');
      });
      final grader = AiAnswerGrader(dataSource: GroqDataSource(client: client));

      final result = await grader.grade(question);

      expect(result.fraction, 0.8);
      expect(result.justification, contains('Bonne réponse'));
    });

    test('se replie sur l\'heuristique de mots-clés si la réponse IA est invalide', () async {
      final client = MockClient.streaming((request, _) async {
        return _sse('data: {"choices":[{"delta":{"content":"pas du json"}}]}\n\ndata: [DONE]\n\n');
      });
      final grader = AiAnswerGrader(dataSource: GroqDataSource(client: client));

      final result = await grader.grade(question);

      // Heuristique : 2 éléments attendus, tous deux présents dans la réponse.
      expect(result.fraction, 1.0);
    });

    test('renvoie une fraction nulle sans réponse fournie, sans appeler l\'IA', () async {
      final client = MockClient.streaming((request, _) async {
        fail('ne devrait pas être appelé pour une réponse vide');
      });
      final grader = AiAnswerGrader(dataSource: GroqDataSource(client: client));

      final result = await grader.grade(question.copyWith(studentAnswer: ''));

      expect(result.fraction, 0);
    });
  });
}
