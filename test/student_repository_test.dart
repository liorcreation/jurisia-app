import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/features/student/data/datasources/evaluation_question_bank.dart';
import 'package:jurisia_app/features/student/data/datasources/student_curriculum_local_datasource.dart';
import 'package:jurisia_app/features/student/data/repositories/student_repository_impl.dart';
import 'package:jurisia_app/features/student/domain/repositories/student_repository.dart';
import 'package:jurisia_app/features/student/domain/usecases/generate_evaluation_usecase.dart';
import 'package:jurisia_app/features/student/domain/usecases/get_student_modules_usecase.dart';
import 'package:jurisia_app/features/student/domain/usecases/grade_evaluation_usecase.dart';
import 'package:jurisia_app/features/student/domain/usecases/validate_module_usecase.dart';
import 'package:jurisia_app/models/student/evaluation_model.dart';
import 'package:jurisia_app/models/student/student_level.dart';

StudentRepository _buildRepository({int seed = 1}) {
  return StudentRepositoryImpl(
    curriculumDataSource: const LocalStudentCurriculumDataSource(),
    questionBank: const LocalEvaluationQuestionBank(),
    random: Random(seed),
  );
}

void main() {
  group('Déblocage séquentiel des modules', () {
    test('seul le premier module de L1 est débloqué au départ', () {
      final repository = _buildRepository();
      final modules = GetStudentModulesUseCase(repository: repository).call(AcademicLevel.l1);

      expect(modules, hasLength(3));
      expect(modules[0].isUnlocked, isTrue);
      expect(modules[1].isUnlocked, isFalse);
      expect(modules[2].isUnlocked, isFalse);
    });

    test('valider le module 1 avec 12/20 débloque le module 2 mais pas le module 3', () {
      final repository = _buildRepository();
      final validate = ValidateModuleUseCase(repository: repository);

      final result = validate(moduleId: 'l1-module-1', score: 12);

      expect(result.passed, isTrue);
      expect(result.unlockedNextModuleId, 'l1-module-2');

      final modules = repository.modulesForLevel(AcademicLevel.l1);
      expect(modules[0].isCompleted, isTrue);
      expect(modules[0].lastScore, 12);
      expect(modules[1].isUnlocked, isTrue);
      expect(modules[2].isUnlocked, isFalse);
    });

    test('une note inférieure à 10/20 ne débloque pas le module suivant', () {
      final repository = _buildRepository();
      final validate = ValidateModuleUseCase(repository: repository);

      final result = validate(moduleId: 'l1-module-1', score: 8);

      expect(result.passed, isFalse);
      expect(result.unlockedNextModuleId, isNull);

      final modules = repository.modulesForLevel(AcademicLevel.l1);
      expect(modules[0].isCompleted, isFalse);
      expect(modules[1].isUnlocked, isFalse);
    });

    test('la validation de tous les modules d\'un niveau débloque le niveau supérieur', () {
      final repository = _buildRepository();
      final validate = ValidateModuleUseCase(repository: repository);

      expect(repository.isLevelUnlocked(AcademicLevel.l2), isFalse);

      validate(moduleId: 'l1-module-1', score: 15);
      validate(moduleId: 'l1-module-2', score: 15);
      final result = validate(moduleId: 'l1-module-3', score: 15);

      expect(result.levelCompleted, isTrue);
      expect(result.unlockedNextLevel, AcademicLevel.l2);
      expect(repository.isLevelUnlocked(AcademicLevel.l2), isTrue);
      expect(repository.isLevelUnlocked(AcademicLevel.l3), isFalse);
    });

    test('L1 est toujours débloqué', () {
      final repository = _buildRepository();
      expect(repository.isLevelUnlocked(AcademicLevel.l1), isTrue);
    });

    test('valider un module inexistant lève une erreur', () {
      final repository = _buildRepository();
      final validate = ValidateModuleUseCase(repository: repository);
      expect(() => validate(moduleId: 'inexistant', score: 15), throwsArgumentError);
    });
  });

  group('Génération et renouvellement des évaluations', () {
    test('une évaluation générée compte quatre questions notées sur 20 au total', () async {
      final repository = _buildRepository();
      final generate = GenerateEvaluationUseCase(repository: repository);

      final evaluation = await generate('l1-module-1');

      expect(evaluation.questions, hasLength(4));
      expect(evaluation.questions.fold<double>(0, (sum, q) => sum + q.points), 20);
      expect(evaluation.attemptNumber, 1);
    });

    test('le numéro de tentative augmente à chaque nouvelle génération', () async {
      final repository = _buildRepository();
      final generate = GenerateEvaluationUseCase(repository: repository);

      final first = await generate('l1-module-1');
      final second = await generate('l1-module-1');

      expect(first.attemptNumber, 1);
      expect(second.attemptNumber, 2);
    });

    test('deux tentatives successives renouvellent le jeu de questions', () async {
      final repository = _buildRepository(seed: 7);
      final generate = GenerateEvaluationUseCase(repository: repository);

      final first = await generate('l1-module-2');
      final second = await generate('l1-module-2');

      expect(
        first.questions.map((q) => q.id).toSet(),
        isNot(equals(second.questions.map((q) => q.id).toSet())),
      );
    });
  });

  group('Historique et moyennes de progression', () {
    test('recordEvaluationResult alimente l\'historique des tentatives et la meilleure note', () async {
      final repository = _buildRepository();
      final generate = GenerateEvaluationUseCase(repository: repository);

      final evaluation = await generate('l1-module-1');
      repository.recordEvaluationResult(
        moduleId: 'l1-module-1',
        evaluationId: evaluation.id,
        score: 14,
      );

      final progress = repository.progressForLevel(AcademicLevel.l1);
      final moduleProgress = progress.moduleProgress['l1-module-1']!;

      expect(moduleProgress.bestScore, 14);
      expect(moduleProgress.attempts, hasLength(1));
      expect(moduleProgress.attempts.first.isCompleted, isTrue);
      expect(moduleProgress.attempts.first.isPassed, isTrue);
    });
  });

  group('GradeEvaluationUseCase', () {
    const grade = GradeEvaluationUseCase();

    test('note un QCM correct au maximum des points et un QCM incorrect à zéro', () {
      final questions = [
        const EvaluationQuestion(
          id: 'q1',
          type: QuestionType.qcm,
          statement: '...',
          points: 5,
          options: ['a', 'b', 'c', 'd'],
          correctOptionIndex: 2,
          studentAnswer: '2',
        ),
        const EvaluationQuestion(
          id: 'q2',
          type: QuestionType.qcm,
          statement: '...',
          points: 5,
          options: ['a', 'b', 'c', 'd'],
          correctOptionIndex: 1,
          studentAnswer: '0',
        ),
      ];

      expect(grade(questions), 5);
    });

    test('accorde un score proportionnel à un cas pratique partiellement correct', () {
      final questions = [
        const EvaluationQuestion(
          id: 'q3',
          type: QuestionType.casPratique,
          statement: '...',
          points: 8,
          expectedAnswerElements: ['force majeure', 'exonération'],
          studentAnswer: 'Il peut invoquer la force majeure pour se dégager.',
        ),
      ];

      expect(grade(questions), 4);
    });

    test('note zéro un cas pratique laissé sans réponse', () {
      final questions = [
        const EvaluationQuestion(
          id: 'q4',
          type: QuestionType.casPratique,
          statement: '...',
          points: 5,
          expectedAnswerElements: ['élément'],
        ),
      ];

      expect(grade(questions), 0);
    });
  });
}
