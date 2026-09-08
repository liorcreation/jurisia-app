import 'package:flutter/foundation.dart';

import '../../../../core/exam/exam_session_guard.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../models/student/course_module.dart';
import '../../../../models/student/evaluation_model.dart';
import '../../../../models/student/mock_exam_model.dart';
import '../../../../models/student/student_level.dart';
import '../../data/datasources/ai_answer_grader.dart';
import '../../domain/repositories/mock_exam_repository.dart';
import '../../domain/usecases/grade_evaluation_usecase.dart';

enum MockExamStatus {
  /// Verrou en cours de chargement, avant tout choix de mode.
  loadingLock,

  /// Verrouillé (délai de 7 jours et/ou cours à reconsulter) : aucune
  /// tentative possible.
  locked,

  /// Prêt : l'étudiant peut choisir un mode et démarrer.
  readyToStart,

  /// Génération du jeu de questions en cours.
  generating,

  /// Épreuve en cours, réponses en saisie.
  inProgress,

  /// Correction en cours (notation IA des cas pratiques).
  grading,

  /// Épreuve corrigée, résultat disponible.
  submitted,

  error,
}

/// Contrôleur d'état de l'examen blanc de fin de niveau : verrou, choix du
/// mode, génération, saisie des réponses, correction, et règle stricte
/// anti-changement d'application (régénération complète en cas de sortie de
/// l'app pendant une épreuve active). Distinct de [EvaluationController]
/// (quiz de fin de module, inchangé).
class MockExamController extends ChangeNotifier {
  MockExamController({
    required this.level,
    required this.levelModules,
    required this.repository,
    required this.answerGrader,
    GradeEvaluationUseCase? gradeUseCase,
  }) : gradeUseCase = gradeUseCase ?? const GradeEvaluationUseCase() {
    _guard = ExamSessionGuard(onInterrupted: _onInterrupted);
    _loadLockState();
  }

  final AcademicLevel level;
  final List<CourseModule> levelModules;
  final MockExamRepository repository;
  final AiAnswerGrader answerGrader;
  final GradeEvaluationUseCase gradeUseCase;

  String get levelId => level.name;

  late final ExamSessionGuard _guard;

  MockExamStatus _status = MockExamStatus.loadingLock;
  MockExamStatus get status => _status;

  MockExamLockState? _lockState;
  MockExamLockState? get lockState => _lockState;

  MockExamMode? _selectedMode;
  MockExamMode? get selectedMode => _selectedMode;

  MockExam? _exam;
  MockExam? get exam => _exam;

  final Map<String, String> _answers = {};
  String? answerFor(String questionId) => _answers[questionId];

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Message affiché une fois, juste après une régénération suite à une
  /// interruption (changement d'app/onglet pendant l'épreuve).
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

  Future<void> start(MockExamMode mode) async {
    _selectedMode = mode;
    _status = MockExamStatus.generating;
    _errorMessage = null;
    _answers.clear();
    notifyListeners();

    try {
      _exam = await repository.generateExam(levelId: levelId, levelModules: levelModules, mode: mode);
      _status = MockExamStatus.inProgress;
      _guard.start();
    } catch (error) {
      _status = MockExamStatus.error;
      _errorMessage = error.toString();
    }
    notifyListeners();
  }

  void answerQcm(String questionId, int optionIndex) {
    _answers[questionId] = optionIndex.toString();
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
    final mode = _selectedMode;
    if (mode == null || _status != MockExamStatus.inProgress) return;
    _guard.stop();
    _interruptionNotice =
        "Examen interrompu — vous avez quitté l'application. Un nouveau jeu de questions a été généré.";
    start(mode);
  }

  Future<void> submit() async {
    final currentExam = _exam;
    if (currentExam == null || !allQuestionsAnswered) return;

    _guard.stop();
    _status = MockExamStatus.grading;
    notifyListeners();

    final gradedQuestions = await Future.wait(
      currentExam.questions.map((question) async {
        final answered = question.copyWith(studentAnswer: _answers[question.id]);
        if (answered.type == QuestionType.qcm) {
          final idx = int.tryParse(answered.studentAnswer ?? '');
          final correct = idx != null && idx == answered.correctOptionIndex;
          return answered.copyWith(awardedPoints: correct ? answered.points : 0);
        }
        final graded = await answerGrader.grade(answered);
        return answered.copyWith(awardedPoints: answered.points * graded.fraction);
      }),
    );

    final score = gradedQuestions.fold<double>(0, (sum, q) => sum + (q.awardedPoints ?? 0));

    _exam = currentExam.copyWith(questions: gradedQuestions, score: score, completedAt: DateTime.now());
    await repository.recordResult(exam: _exam!);

    if (score < 10) {
      final lockedUntil = DateTime.now().add(const Duration(hours: 168));
      await NotificationService.scheduleMockExamRetryReminder(
        levelId: levelId,
        levelLabel: level.fullLabel,
        lockedUntil: lockedUntil,
      );
    }

    await _loadLockState();
    _status = MockExamStatus.submitted;
    notifyListeners();
  }

  /// Relance une nouvelle tentative avec un jeu de questions inédit — utilisé
  /// après un échec dès que le verrou est levé (délai écoulé et cours
  /// reconsulté).
  Future<void> retry() async {
    final mode = _selectedMode;
    if (mode == null) return;
    await start(mode);
  }

  @override
  void dispose() {
    _guard.stop();
    super.dispose();
  }
}
