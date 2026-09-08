import '../../../../models/student/course_module.dart';
import '../../../../models/student/mock_exam_model.dart';

/// Frontière du domaine vers l'examen blanc de fin de niveau : génération
/// des questions, verrou de réécriture et enregistrement du résultat.
/// Distincte de [StudentRepository] (quiz de fin de module, inchangé).
abstract class MockExamRepository {
  /// État du verrou de réécriture du niveau (nul si jamais tenté).
  Future<MockExamLockState> lockStateFor(String levelId);

  /// Génère un nouveau jeu de questions pour une tentative, à partir de
  /// l'ensemble des [levelModules] du niveau.
  Future<MockExam> generateExam({
    required String levelId,
    required List<CourseModule> levelModules,
    required MockExamMode mode,
  });

  /// Enregistre le résultat final d'une tentative corrigée : applique, côté
  /// serveur, le verrou de 7 jours en cas d'échec.
  Future<void> recordResult({required MockExam exam});

  /// À appeler dès que l'étudiant reconsulte le cours d'un module du niveau
  /// après un échec, pour lever l'obligation de révision du verrou.
  Future<void> markCourseReviewed(String levelId);
}
