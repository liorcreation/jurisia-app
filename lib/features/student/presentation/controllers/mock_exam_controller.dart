import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/exam/exam_camera_guard.dart';
import '../../../../core/exam/exam_noise_guard.dart';
import '../../../../core/exam/exam_session_guard.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../models/student/course_module.dart';
import '../../../../models/student/mock_exam_model.dart';
import '../../../../models/student/student_level.dart';
import '../../data/datasources/ai_answer_grader.dart';
import '../../domain/repositories/mock_exam_repository.dart';

enum MockExamStatus {
  /// Verrou en cours de chargement, avant le briefing de démarrage.
  loadingLock,

  /// Verrouillé (délai de 7 jours et/ou cours à reconsulter) : aucune
  /// tentative possible.
  locked,

  /// Prêt : l'étudiant peut démarrer l'épreuve.
  readyToStart,

  /// Génération du jeu de questions en cours.
  generating,

  /// Épreuve en cours, conversation vocale active.
  inProgress,

  /// Correction en cours (notation IA des réponses).
  grading,

  /// Épreuve corrigée (ou disqualifiée), résultat disponible.
  submitted,

  error,
}

/// Contrôleur d'état de l'examen blanc de fin de niveau : verrou, génération,
/// conversation vocale unique (plus de choix de format), correction, et
/// proctoring. Trois signaux distincts pendant [MockExamStatus.inProgress] :
/// - [ExamSessionGuard] (quitter l'app/le plein écran) → régénère un jeu de
///   questions neuf, la tentative continue ;
/// - [ExamNoiseGuard]/[ExamCameraGuard] (bruit/mouvement suspects) →
///   disqualifie immédiatement et définitivement la tentative (score forcé
///   à 0, comme un échec par la note).
/// Distinct de [EvaluationController] (quiz de fin de module, inchangé).
class MockExamController extends ChangeNotifier {
  /// [sessionGuard]/[noiseGuard]/[cameraGuard] sont injectables (tests
  /// uniquement — sous-classes bouchon qui évitent de solliciter de vrais
  /// canaux de plateforme, indisponibles/instables sous `flutter test`) ;
  /// en production, laisser ces paramètres à `null` construit toujours les
  /// vraies implémentations.
  MockExamController({
    required this.level,
    required this.levelModules,
    required this.repository,
    required this.answerGrader,
    this.onPassed,
    ExamSessionGuard? sessionGuard,
    ExamNoiseGuard? noiseGuard,
    ExamCameraGuard? cameraGuard,
  }) {
    _guard = sessionGuard ?? ExamSessionGuard(onInterrupted: _onInterrupted);
    _noiseGuard = noiseGuard ??
        ExamNoiseGuard(onDisqualified: () => _disqualify(MockExamDisqualificationReason.suspiciousNoise));
    _cameraGuard = cameraGuard ??
        ExamCameraGuard(onDisqualified: () => _disqualify(MockExamDisqualificationReason.suspiciousMotion));
    _loadLockState();
  }

  final AcademicLevel level;
  final List<CourseModule> levelModules;
  final MockExamRepository repository;
  final AiAnswerGrader answerGrader;

  /// Appelé une fois, dès qu'une tentative est corrigée avec un score ≥ 10 —
  /// permet à l'écran appelant de reporter la réussite sur le
  /// [StudentRepository] partagé (déblocage du niveau supérieur).
  final VoidCallback? onPassed;

  String get levelId => level.name;

  late final ExamSessionGuard _guard;
  late final ExamNoiseGuard _noiseGuard;
  late final ExamCameraGuard _cameraGuard;

  /// Aperçu caméra à afficher (transparence envers l'étudiant) une fois le
  /// proctoring armé, ou `null` tant qu'il n'est pas prêt/non supporté.
  ExamCameraGuard get cameraGuard => _cameraGuard;

  /// Arme ou désarme la détection de bruit — à appeler par l'écran autour
  /// des courtes fenêtres de silence dédiées (jamais pendant que l'IA parle
  /// elle-même, jamais pendant que l'étudiant répond).
  void armNoiseGuard(bool armed) => _noiseGuard.armed = armed;

  /// Alimente la détection de bruit avec un échantillon de niveau sonore
  /// (déjà capté par `speech_to_text` pour faire réagir l'orbe).
  void feedNoiseSample(double level) => _noiseGuard.onSample(level);

  MockExamStatus _status = MockExamStatus.loadingLock;
  MockExamStatus get status => _status;

  MockExamLockState? _lockState;
  MockExamLockState? get lockState => _lockState;

  MockExam? _exam;
  MockExam? get exam => _exam;

  final Map<String, String> _answers = {};
  String? answerFor(String questionId) => _answers[questionId];

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Message affiché une fois, juste après une régénération suite à une
  /// interruption (changement d'app/onglet/plein écran pendant l'épreuve).
  String? _interruptionNotice;
  String? get interruptionNotice => _interruptionNotice;

  void dismissInterruptionNotice() {
    _interruptionNotice = null;
    notifyListeners();
  }

  bool get allQuestionsAnswered {
    final currentExam = _exam;
    if (currentExam == null || currentExam.questions.isEmpty) return false;
    return currentExam.questions.every((q) => (_answers[q.id] ?? '').trim().isNotEmpty);
  }

  Future<void> _loadLockState() async {
    _status = MockExamStatus.loadingLock;
    notifyListeners();

    _lockState = await repository.lockStateFor(levelId);
    _status = (_lockState?.isLocked ?? false) || (_lockState?.requiresCourseReview ?? false)
        ? MockExamStatus.locked
        : MockExamStatus.readyToStart;
    notifyListeners();
  }

  /// À appeler après un échec puis une reconsultation du cours, pour
  /// rafraîchir l'état du verrou sans repartir de zéro.
  Future<void> refreshLockState() => _loadLockState();

  Future<void> start() async {
    // Doit rester la toute première instruction, avant tout `await` : sur
    // web, `_guard.start()` demande le plein écran du navigateur, ce qui
    // n'est honoré que dans la pile d'appel synchrone du geste de
    // l'utilisateur (même contrainte que window.open(), déjà rencontrée
    // pour le SSO admin) — un appel après l'aller-retour réseau de
    // génération des questions serait silencieusement refusé.
    _guard.start();

    _status = MockExamStatus.generating;
    _errorMessage = null;
    _answers.clear();
    notifyListeners();

    try {
      _exam = await repository.generateExam(levelId: levelId, levelModules: levelModules);
      _status = MockExamStatus.inProgress;
      // Best effort : indisponible/refusée, l'épreuve continue sans ce
      // signal plutôt que de bloquer l'étudiant (voir ExamCameraGuard).
      // L'aperçu ne devient disponible qu'une fois la caméra initialisée,
      // d'où le notifyListeners() différé pour que l'écran le découvre.
      unawaited(_cameraGuard.start().then((_) {
        if (!_disposed) notifyListeners();
      }));
    } catch (error) {
      _guard.stop();
      _status = MockExamStatus.error;
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  void answerCasPratique(String questionId, String text) {
    _answers[questionId] = text;
    notifyListeners();
  }

  void _onInterrupted() {
    // Session invalidée immédiatement : au retour, l'étudiant retrouve un
    // jeu de questions entièrement neuf plutôt qu'une reprise, pour
    // invalider toute recherche externe tentée pendant l'absence.
    if (_status != MockExamStatus.inProgress) return;
    _guard.stop();
    _noiseGuard.reset();
    unawaited(_cameraGuard.stop());
    _interruptionNotice =
        "Examen interrompu — vous avez quitté l'application. Un nouveau jeu de questions a été généré.";
    start();
  }

  Future<void> _disqualify(MockExamDisqualificationReason reason) async {
    final currentExam = _exam;
    if (currentExam == null || _status != MockExamStatus.inProgress) return;

    _guard.stop();
    _noiseGuard.reset();
    await _cameraGuard.stop();

    _status = MockExamStatus.grading;
    notifyListeners();

    _exam = currentExam.copyWith(score: 0, completedAt: DateTime.now(), disqualificationReason: reason);
    await repository.recordResult(exam: _exam!);
    await _scheduleRetryReminder();
    await _loadLockState();
    _status = MockExamStatus.submitted;
    notifyListeners();
  }

  Future<void> submit() async {
    final currentExam = _exam;
    if (currentExam == null || !allQuestionsAnswered) return;

    _guard.stop();
    _noiseGuard.reset();
    await _cameraGuard.stop();
    _status = MockExamStatus.grading;
    notifyListeners();

    final gradedQuestions = await Future.wait(
      currentExam.questions.map((question) async {
        final answered = question.copyWith(studentAnswer: _answers[question.id]);
        final graded = await answerGrader.grade(answered);
        return answered.copyWith(awardedPoints: answered.points * graded.fraction);
      }),
    );

    final score = gradedQuestions.fold<double>(0, (sum, q) => sum + (q.awardedPoints ?? 0));

    _exam = currentExam.copyWith(questions: gradedQuestions, score: score, completedAt: DateTime.now());
    await repository.recordResult(exam: _exam!);

    if (score >= 10) {
      onPassed?.call();
    } else {
      await _scheduleRetryReminder();
    }

    await _loadLockState();
    _status = MockExamStatus.submitted;
    notifyListeners();
  }

  Future<void> _scheduleRetryReminder() {
    final lockedUntil = DateTime.now().add(const Duration(hours: 168));
    return NotificationService.scheduleMockExamRetryReminder(
      levelId: levelId,
      levelLabel: level.fullLabel,
      lockedUntil: lockedUntil,
    );
  }

  /// Relance une nouvelle tentative avec un jeu de questions inédit — utilisé
  /// après un échec dès que le verrou est levé (délai écoulé et cours
  /// reconsulté).
  Future<void> retry() => start();

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _guard.stop();
    _noiseGuard.reset();
    unawaited(_cameraGuard.stop());
    super.dispose();
  }
}
