import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../../../core/ai/claude_api_config.dart';
import '../../../../models/student/course_module.dart';
import '../../../../models/student/evaluation_model.dart';
import '../../../../models/student/student_level.dart';
import '../../../../models/student/student_progress_model.dart';
import '../../domain/entities/module_validation_result.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/ai_evaluation_generator.dart';
import '../datasources/evaluation_question_bank.dart';
import '../datasources/student_curriculum_local_datasource.dart';

/// Implémentation du [StudentRepository] : conserve en mémoire l'état du
/// parcours de l'étudiant (déblocage, validation, tentatives d'évaluation)
/// à partir du programme fourni par [curriculumDataSource].
class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl({
    required this.curriculumDataSource,
    required this.questionBank,
    this.aiGenerator,
    this.questionsPerAttempt = 4,
    Random? random,
    Uuid? uuid,
  })  : _random = random ?? Random(),
        _uuid = uuid ?? const Uuid() {
    for (final module in curriculumDataSource.getAll()) {
      _modulesById[module.id] = module;
    }
  }

  final StudentCurriculumDataSource curriculumDataSource;
  final EvaluationQuestionBank questionBank;
  final AiEvaluationGenerator? aiGenerator;
  final int questionsPerAttempt;
  final Random _random;
  final Uuid _uuid;

  final Map<String, CourseModule> _modulesById = {};
  final Map<String, List<ModuleEvaluation>> _attemptsByModule = {};

  @override
  List<CourseModule> modulesForLevel(AcademicLevel level) {
    final modules = _modulesById.values.where((module) => module.level == level).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return modules;
  }

  @override
  CourseModule? findModule(String moduleId) => _modulesById[moduleId];

  @override
  bool isLevelUnlocked(AcademicLevel level) {
    final levels = AcademicLevel.values;
    final index = levels.indexOf(level);
    if (index == 0) return true;

    final previousModules = modulesForLevel(levels[index - 1]);
    return previousModules.isNotEmpty && previousModules.every((module) => module.isCompleted);
  }

  @override
  StudentProgress progressForLevel(AcademicLevel level) {
    final modules = modulesForLevel(level);
    final moduleProgress = <String, ModuleProgress>{
      for (final module in modules)
        module.id: ModuleProgress(
          moduleId: module.id,
          isUnlocked: module.isUnlocked,
          isCompleted: module.isCompleted,
          bestScore: _bestScoreFor(module.id),
          attempts: List.unmodifiable(_attemptsByModule[module.id] ?? const []),
        ),
    };

    return StudentProgress(studentId: 'local-student', level: level, moduleProgress: moduleProgress);
  }

  double? _bestScoreFor(String moduleId) {
    final scored = (_attemptsByModule[moduleId] ?? const [])
        .where((attempt) => attempt.score != null)
        .map((attempt) => attempt.score!);
    if (scored.isEmpty) return null;
    return scored.reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<ModuleEvaluation> generateEvaluation(String moduleId) async {
    final module = findModule(moduleId);
    if (module == null) {
      throw ArgumentError('Module introuvable : $moduleId');
    }

    List<EvaluationQuestion> questions;
    if (aiGenerator != null && ClaudeApiConfig.hasApiKey) {
      try {
        questions = await aiGenerator!.generate(module: module, questionCount: questionsPerAttempt);
      } catch (_) {
        questions = _pickLocalQuestions(moduleId);
      }
    } else {
      questions = _pickLocalQuestions(moduleId);
    }

    final attemptNumber = (_attemptsByModule[moduleId]?.length ?? 0) + 1;
    final evaluation = ModuleEvaluation(
      id: _uuid.v4(),
      moduleId: moduleId,
      attemptNumber: attemptNumber,
      questions: questions,
      generatedAt: DateTime.now(),
    );

    _attemptsByModule.putIfAbsent(moduleId, () => []).add(evaluation);
    return evaluation;
  }

  List<EvaluationQuestion> _pickLocalQuestions(String moduleId) {
    final candidates = List<EvaluationQuestion>.of(questionBank.candidatesFor(moduleId));
    if (candidates.isEmpty) {
      throw StateError('Aucune question disponible pour le module $moduleId.');
    }
    candidates.shuffle(_random);
    final count = questionsPerAttempt.clamp(1, candidates.length);
    return candidates.take(count).toList();
  }

  @override
  void recordEvaluationResult({
    required String moduleId,
    required String evaluationId,
    required double score,
  }) {
    final attempts = _attemptsByModule[moduleId];
    if (attempts == null) return;
    final index = attempts.indexWhere((attempt) => attempt.id == evaluationId);
    if (index == -1) return;
    attempts[index] = attempts[index].copyWith(score: score, completedAt: DateTime.now());
  }

  @override
  ModuleValidationResult validateModule({required String moduleId, required double score}) {
    final module = findModule(moduleId);
    if (module == null) {
      throw ArgumentError('Module introuvable : $moduleId');
    }

    final passed = score >= 10;
    _modulesById[moduleId] = module.copyWith(
      isCompleted: passed || module.isCompleted,
      lastScore: score,
    );

    String? unlockedNextModuleId;
    var levelCompleted = false;
    AcademicLevel? unlockedNextLevel;

    if (passed) {
      final levelModules = modulesForLevel(module.level);

      CourseModule? next;
      for (final candidate in levelModules) {
        if (candidate.order == module.order + 1) {
          next = candidate;
          break;
        }
      }
      if (next != null && !next.isUnlocked) {
        _modulesById[next.id] = next.copyWith(isUnlocked: true);
        unlockedNextModuleId = next.id;
      }

      final refreshed = modulesForLevel(module.level);
      levelCompleted = refreshed.every((candidate) => candidate.isCompleted);
      if (levelCompleted) {
        final levels = AcademicLevel.values;
        final currentIndex = levels.indexOf(module.level);
        if (currentIndex < levels.length - 1) {
          unlockedNextLevel = levels[currentIndex + 1];
        }
      }
    }

    return ModuleValidationResult(
      moduleId: moduleId,
      score: score,
      passed: passed,
      updatedModule: _modulesById[moduleId]!,
      unlockedNextModuleId: unlockedNextModuleId,
      levelCompleted: levelCompleted,
      unlockedNextLevel: unlockedNextLevel,
    );
  }
}
