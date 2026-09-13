import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/exam/exam_camera_guard.dart';
import '../../../../core/exam/exam_microphone_guard.dart';
import '../../../../core/exam/exam_noise_guard.dart';
import '../../../../core/exam/exam_session_guard.dart';
import '../../../../models/student/evaluation_model.dart';
import '../../data/datasources/ai_answer_grader.dart';
import '../../domain/entities/evaluation_mode.dart';
import '../../domain/entities/module_validation_result.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/usecases/generate_evaluation_usecase.dart';
import '../../domain/usecases/grade_evaluation_usecase.dart';
import '../../domain/usecases/validate_module_usecase.dart';

enum EvaluationLoadStatus { loading, ready, grading, error }

/// Contrôleur d'état de l'écran d'évaluation : génération du jeu de
/// questions, saisie des réponses, correction et validation du module.
class EvaluationController extends ChangeNotifier {
  static const Duration maximumDuration = Duration(hours: 3);

  EvaluationController({
    required this.moduleId,
    required this.generateUseCase,
    required this.validateUseCase,
    required this.repository,
    GradeEvaluationUseCase? gradeUseCase,
    this.answerGrader,
    EvaluationModeSelector? modeSelector,
    ExamSessionGuard? sessionGuard,
    ExamNoiseGuard? noiseGuard,
    ExamCameraGuard? cameraGuard,
    ExamMicrophoneGuard? microphoneGuard,
  }) : gradeUseCase = gradeUseCase ?? const GradeEvaluationUseCase() {
    _modeSelector = modeSelector ?? EvaluationModeSelector();
    _sessionGuard =
        sessionGuard ?? ExamSessionGuard(onInterrupted: _onInterrupted);
    _noiseGuard =
        noiseGuard ??
        ExamNoiseGuard(
          onDisqualified: () =>
              unawaited(_disqualify('Bruit ou voix tierce détecté.')),
        );
    _cameraGuard =
        cameraGuard ??
        ExamCameraGuard(
          onDisqualified: () => unawaited(
            _disqualify('Mouvement ou absence du candidat détecté.'),
          ),
        );
    _microphoneGuard = microphoneGuard ?? ExamMicrophoneGuard();
    _generate();
  }

  final String moduleId;
  final GenerateEvaluationUseCase generateUseCase;
  final ValidateModuleUseCase validateUseCase;
  final StudentRepository repository;
  final GradeEvaluationUseCase gradeUseCase;
  final AiAnswerGrader? answerGrader;

  late final EvaluationModeSelector _modeSelector;
  late final ExamSessionGuard _sessionGuard;
  late final ExamNoiseGuard _noiseGuard;
  late final ExamCameraGuard _cameraGuard;
  late final ExamMicrophoneGuard _microphoneGuard;

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

  EvaluationMode? _mode;
  EvaluationMode? get mode => _mode;

  bool _isStarted = false;
  bool get isStarted => _isStarted;

  Timer? _durationTimer;
  DateTime? _deadline;

  /// Temps restant de l'épreuve globale, distinct du chrono de 5 secondes
  /// propre aux diapositives QCM.
  Duration? get remainingDuration {
    if (!_isStarted || _deadline == null) return null;
    final remaining = _deadline!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool _isGrading = false;
  bool get isGrading => _isGrading;

  int _interruptionCount = 0;
  String? _proctoringWarning;
  String? get proctoringWarning => _proctoringWarning;

  String? _disqualificationReason;
  String? get disqualificationReason => _disqualificationReason;

  bool get cameraMonitoringSupported => _cameraGuard.isSupported;
  bool get cameraMonitoringActive => _cameraGuard.isMonitoring;
  CameraController? get cameraPreviewController =>
      _cameraGuard.previewController;
  bool get microphoneMonitoringActive => _microphoneGuard.isActive;

  bool get allQuestionsAnswered {
    final currentEvaluation = _evaluation;
    if (currentEvaluation == null || currentEvaluation.questions.isEmpty) {
      return false;
    }
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

  /// Arme la fenêtre acoustique dédiée au proctoring. Le mode oral la ferme
  /// pendant la réponse du candidat pour ne pas confondre sa voix avec une
  /// voix tierce ; les modes écrit et QCM la laissent active.
  void armNoiseGuard(bool armed) {
    _noiseGuard.armed = armed;
  }

  void feedNoiseSample(double level) => _noiseGuard.onSample(level);

  void dismissProctoringWarning() {
    _proctoringWarning = null;
    notifyListeners();
  }

  /// Lance l'épreuve depuis le geste utilisateur : l'appel au garde web reste
  /// synchrone afin que le navigateur accepte la demande de plein écran.
  void start() {
    if (_evaluation == null ||
        _status != EvaluationLoadStatus.ready ||
        _isStarted) {
      return;
    }
    _isStarted = true;
    _proctoringWarning = null;
    _startDurationClock();
    unawaited(_sessionGuard.start());
    _noiseGuard.armed = _mode != EvaluationMode.voice;
    unawaited(_startSensors());
    notifyListeners();
  }

  Future<void> retryWithNewQuestions() => _generate();

  Future<void> _generate() async {
    await _stopProctoring();
    _stopDurationClock();
    _status = EvaluationLoadStatus.loading;
    _errorMessage = null;
    _answers.clear();
    _result = null;
    _isStarted = false;
    _isGrading = false;
    _interruptionCount = 0;
    _proctoringWarning = null;
    _disqualificationReason = null;
    _mode = _modeSelector.select(moduleId: moduleId);
    notifyListeners();

    try {
      _evaluation = await generateUseCase(moduleId, mode: _mode!);
      _status = EvaluationLoadStatus.ready;
    } catch (error) {
      _status = EvaluationLoadStatus.error;
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  void submit() {
    unawaited(_submit(allowUnanswered: false));
  }

  void submitTimedQcm() {
    unawaited(_submit(allowUnanswered: true));
  }

  Future<void> _submit({required bool allowUnanswered}) async {
    final currentEvaluation = _evaluation;
    if (currentEvaluation == null || _result != null || _isGrading) return;
    if (!allowUnanswered && !allQuestionsAnswered) return;

    _isGrading = true;
    _status = EvaluationLoadStatus.grading;
    notifyListeners();

    final answeredQuestions = currentEvaluation.questions
        .map(
          (question) => question.copyWith(studentAnswer: _answers[question.id]),
        )
        .toList();

    final gradedQuestions = <EvaluationQuestion>[];
    for (final question in answeredQuestions) {
      if (question.type == QuestionType.casPratique && answerGrader != null) {
        final graded = await answerGrader!.grade(question);
        gradedQuestions.add(
          question.copyWith(awardedPoints: question.points * graded.fraction),
        );
      } else {
        final awarded = gradeUseCase([question]);
        gradedQuestions.add(question.copyWith(awardedPoints: awarded));
      }
    }
    final score = _disqualificationReason == null
        ? gradedQuestions
              .fold<double>(
                0,
                (sum, question) => sum + (question.awardedPoints ?? 0),
              )
              .clamp(0, currentEvaluation.maxScore)
              .toDouble()
        : 0.0;

    await _completeSubmission(currentEvaluation, gradedQuestions, score);
  }

  Future<void> _completeSubmission(
    ModuleEvaluation currentEvaluation,
    List<EvaluationQuestion> answeredQuestions,
    double score,
  ) async {
    _stopDurationClock();
    await _stopProctoring();

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
    _isGrading = false;
    _status = EvaluationLoadStatus.ready;
    notifyListeners();
  }

  Future<void> _disqualify(String reason) async {
    if (!_isStarted || _result != null || _isGrading || _evaluation == null) {
      return;
    }
    _disqualificationReason = reason;
    final currentEvaluation = _evaluation!;
    final answeredQuestions = currentEvaluation.questions
        .map(
          (question) => question.copyWith(
            studentAnswer: _answers[question.id],
            awardedPoints: 0,
          ),
        )
        .toList();
    _isGrading = true;
    _status = EvaluationLoadStatus.grading;
    notifyListeners();
    await _completeSubmission(currentEvaluation, answeredQuestions, 0);
  }

  void _onInterrupted() {
    if (!_isStarted || _result != null) return;
    _interruptionCount++;
    if (_interruptionCount >= 2) {
      unawaited(_disqualify('Session interrompue à plusieurs reprises.'));
      return;
    }
    _proctoringWarning =
        'Interruption détectée. Revenez immédiatement dans JurisIA et restez en plein écran.';
    unawaited(_sessionGuard.start());
    notifyListeners();
  }

  Future<void> _startSensors() async {
    final cameraStarted = await _cameraGuard.start();
    if (_isStarted && _result == null) notifyListeners();
    if (!_isStarted || _result != null) return;
    // Le mode oral possède une session STT interactive pour transcrire la
    // réponse ; elle alimente directement [feedNoiseSample]. Les autres
    // modes utilisent le garde microphone continu, sans conflit entre deux
    // instances de SpeechToText.
    if (_mode != EvaluationMode.voice) {
      await _microphoneGuard.start(onSample: feedNoiseSample);
    }
    if (cameraStarted && _isStarted && _result == null) notifyListeners();
  }

  Future<void> _stopProctoring() async {
    _noiseGuard.reset();
    await _sessionGuard.stop();
    await Future.wait([_cameraGuard.stop(), _microphoneGuard.stop()]);
  }

  @override
  void dispose() {
    _stopDurationClock();
    unawaited(_stopProctoring());
    super.dispose();
  }

  void _startDurationClock() {
    _durationTimer?.cancel();
    _deadline = DateTime.now().add(maximumDuration);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final deadline = _deadline;
      if (!_isStarted || _result != null || deadline == null) return;
      if (!deadline.isAfter(DateTime.now())) {
        _stopDurationClock();
        unawaited(_submit(allowUnanswered: true));
        return;
      }
      notifyListeners();
    });
  }

  void _stopDurationClock() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _deadline = null;
  }
}
