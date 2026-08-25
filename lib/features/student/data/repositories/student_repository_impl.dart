import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/ai/groq_api_config.dart';
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
/// à partir du programme fourni par [curriculumDataSource], synchronisé en
/// arrière-plan avec Supabase quand [supabaseClient] et [userId] sont
/// fournis. Le détail des questions d'une tentative reste local à la
/// session ; seuls le déblocage, la validation, la meilleure note et le
/// nombre de tentatives survivent au redémarrage.
class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl({
    required this.curriculumDataSource,
    required this.questionBank,
    this.aiGenerator,
    this.questionsPerAttempt = 4,
    this.supabaseClient,
    this.userId,
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
  final SupabaseClient? supabaseClient;
  final String? userId;
  final Random _random;
  final Uuid _uuid;

  final Map<String, CourseModule> _modulesById = {};
  final Map<String, List<ModuleEvaluation>> _attemptsByModule = {};

  /// Nombre de tentatives déjà persistées par module, utilisé pour numéroter
  /// correctement une nouvelle tentative même après un redémarrage.
  final Map<String, int> _attemptsCountByModule = {};

  /// Meilleure note déjà persistée par module, distincte des tentatives de
  /// la session courante (dont le détail n'est pas rechargé).
  final Map<String, double> _persistedBestScore = {};

  bool get _persistenceEnabled => supabaseClient != null && userId != null;

  @override
  Future<void> hydrate() async {
    if (!_persistenceEnabled) return;

    try {
      final rows = await supabaseClient!
          .from('student_module_progress')
          .select('module_id, is_unlocked, is_completed, best_score, attempts_count')
          .eq('user_id', userId!);

      for (final row in rows as List) {
        final moduleId = row['module_id'] as String;
        final module = _modulesById[moduleId];
        if (module == null) continue;

        final bestScore = (row['best_score'] as num?)?.toDouble();
        _modulesById[moduleId] = module.copyWith(
          isUnlocked: row['is_unlocked'] as bool? ?? module.isUnlocked,
          isCompleted: row['is_completed'] as bool? ?? module.isCompleted,
          lastScore: bestScore ?? module.lastScore,
        );
        _attemptsCountByModule[moduleId] = row['attempts_count'] as int? ?? 0;
        if (bestScore != null) _persistedBestScore[moduleId] = bestScore;
      }
    } catch (error) {
      // ignore: avoid_print
      print('Échec du chargement de la progression étudiante Supabase : $error');
    }
  }

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

    return StudentProgress(studentId: userId ?? 'local-student', level: level, moduleProgress: moduleProgress);
  }

  double? _bestScoreFor(String moduleId) {
    final scored = (_attemptsByModule[moduleId] ?? const [])
        .where((attempt) => attempt.score != null)
        .map((attempt) => attempt.score!)
        .toList();
    final persisted = _persistedBestScore[moduleId];
    if (persisted != null) scored.add(persisted);
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
    if (aiGenerator != null && GroqApiConfig.hasEndpoint) {
      try {
        questions = await aiGenerator!.generate(module: module, questionCount: questionsPerAttempt);
      } catch (_) {
        questions = _pickLocalQuestions(moduleId);
      }
    } else {
      questions = _pickLocalQuestions(moduleId);
    }

    final attemptNumber = (_attemptsCountByModule[moduleId] ?? _attemptsByModule[moduleId]?.length ?? 0) + 1;
    final evaluation = ModuleEvaluation(
      id: _uuid.v4(),
      moduleId: moduleId,
      attemptNumber: attemptNumber,
      questions: questions,
      generatedAt: DateTime.now(),
    );

    _attemptsByModule.putIfAbsent(moduleId, () => []).add(evaluation);
    _attemptsCountByModule[moduleId] = attemptNumber;
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
    final attempt = attempts[index].copyWith(score: score, completedAt: DateTime.now());
    attempts[index] = attempt;

    final bestScore = _bestScoreFor(moduleId);
    if (bestScore != null) _persistedBestScore[moduleId] = bestScore;

    _persistAttempt(moduleId: moduleId, attemptNumber: attempt.attemptNumber, score: score, bestScore: bestScore);
  }

  void _persistAttempt({
    required String moduleId,
    required int attemptNumber,
    required double score,
    double? bestScore,
  }) {
    if (!_persistenceEnabled) return;
    final client = supabaseClient!;

    client.from('student_evaluation_attempts').insert({
      'user_id': userId,
      'module_id': moduleId,
      'attempt_number': attemptNumber,
      'score': score,
    }).catchError((Object error) {
      // ignore: avoid_print
      print("Échec de l'enregistrement de la tentative ($moduleId) : $error");
    });

    client.from('student_module_progress').upsert({
      'user_id': userId,
      'module_id': moduleId,
      'attempts_count': attemptNumber,
      'best_score': ?bestScore,
      'updated_at': DateTime.now().toIso8601String(),
    }).catchError((Object error) {
      // ignore: avoid_print
      print('Échec de synchronisation de la progression ($moduleId) : $error');
    });
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
    _persistModuleState(moduleId, isCompleted: _modulesById[moduleId]!.isCompleted);

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
        _persistModuleState(next.id, isUnlocked: true);
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

  void _persistModuleState(String moduleId, {bool? isUnlocked, bool? isCompleted}) {
    if (!_persistenceEnabled) return;

    supabaseClient!.from('student_module_progress').upsert({
      'user_id': userId,
      'module_id': moduleId,
      'is_unlocked': ?isUnlocked,
      'is_completed': ?isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    }).catchError((Object error) {
      // ignore: avoid_print
      print('Échec de synchronisation du déblocage ($moduleId) : $error');
    });
  }
}
