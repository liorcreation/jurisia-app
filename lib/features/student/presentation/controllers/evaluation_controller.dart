import 'package:flutter/foundation.dart';

import '../../../../models/student/evaluation_model.dart';
import '../../domain/entities/module_validation_result.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/usecases/generate_evaluation_usecase.dart';
import '../../domain/usecases/grade_evaluation_usecase.dart';
import '../../domain/usecases/validate_module_usecase.dart';

enum EvaluationLoadStatus { loading, ready, error }

/// Contrôleur d'état de l'écran d'évaluation : génération du jeu de
/// questions, saisie des réponses, correction et validation du module.
class EvaluationController extends ChangeNotifier {
  EvaluationController({
    required this.moduleId,
    required this.generateUseCase,
    required this.validateUseCase,
    required this.repository,
    GradeEvaluationUseCase? gradeUseCase,
  }) : gradeUseCase = gradeUseCase ?? const GradeEvaluationUseCase() {
    _generate();
  }

  final String moduleId;
  final GenerateEvaluationUseCase generateUseCase;
  final ValidateModuleUseCase validateUseCase;
  final StudentRepository repository;
  final GradeEvaluationUseCase gradeUseCase;

  EvaluationLoadStatus _status = EvaluationLoadStatus.loading;
  EvaluationLoadStatus get status => _status;

  ModuleEvaluation? _evaluation;
  ModuleEvaluation? get evaluation => _evaluation;

  final Map<String, String> _answers = {};
  String? answerFor(String questionId) => _answers[questionId];

  ModuleValidationResult? _result;
  ModuleValidationResult? get result => _result;
  bool get isSubmitted => _result != null;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get allQuestionsAnswered {
    final currentEvaluation = _evaluation;
    if (currentEvaluation == null || currentEvaluation.questions.isEmpty) return false;
    return currentEvaluation.questions.every(
      (question) => (_answers[question.id] ?? '').trim().isNotEmpty,
    );
  }

  void answerQcm(String questionId, int optionIndex) {
    _answers[questionId] = optionIndex.toString();
    notifyListeners();
  }

  void answerCasPratique(String questionId, String text) {
    _answers[questionId] = text;
    notifyListeners();
  }

  Future<void> retryWithNewQuestions() => _generate();

  Future<void> _generate() async {
    _status = EvaluationLoadStatus.loading;
    _errorMessage = null;
    _answers.clear();
    _result = null;
    notifyListeners();

    try {
      _evaluation = await generateUseCase(moduleId);
      _status = EvaluationLoadStatus.ready;
    } catch (error) {
      _status = EvaluationLoadStatus.error;
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  void submit() {
    final currentEvaluation = _evaluation;
    if (currentEvaluation == null || !allQuestionsAnswered) return;

    final answeredQuestions = currentEvaluation.questions
        .map((question) => question.copyWith(studentAnswer: _answers[question.id]))
        .toList();
    final score = gradeUseCase(answeredQuestions);

    repository.recordEvaluationResult(
      moduleId: moduleId,
      evaluationId: currentEvaluation.id,
      score: score,
    );

    _evaluation = currentEvaluation.copyWith(
      questions: answeredQuestions,
      score: score,
      completedAt: DateTime.now(),
    );
    _result = validateUseCase(moduleId: moduleId, score: score);
    notifyListeners();
  }
}
