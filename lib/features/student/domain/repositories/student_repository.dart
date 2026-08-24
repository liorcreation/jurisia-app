import '../../../../models/student/course_module.dart';
import '../../../../models/student/evaluation_model.dart';
import '../../../../models/student/student_level.dart';
import '../../../../models/student/student_progress_model.dart';
import '../entities/module_validation_result.dart';

/// Frontière du domaine vers le parcours universitaire de l'étudiant :
/// programme, progression et évaluations.
abstract class StudentRepository {
  /// Modules du niveau donné, triés par ordre séquentiel, reflétant l'état
  /// courant (déblocage, validation, dernière note) de l'étudiant.
  List<CourseModule> modulesForLevel(AcademicLevel level);

  /// Retrouve un module par identifiant, ou `null` s'il n'existe pas.
  CourseModule? findModule(String moduleId);

  /// Un niveau est débloqué si c'est le premier (L1), ou si tous les
  /// modules du niveau précédent ont été validés.
  bool isLevelUnlocked(AcademicLevel level);

  /// Suivi de progression composé de l'état courant des modules et de
  /// l'historique de leurs tentatives d'évaluation.
  StudentProgress progressForLevel(AcademicLevel level);

  /// Génère un nouveau jeu de questions pour une tentative d'évaluation du
  /// module (IA si configurée, banque locale sinon), en le conservant dans
  /// l'historique des tentatives.
  Future<ModuleEvaluation> generateEvaluation(String moduleId);

  /// Enregistre la note obtenue à une tentative d'évaluation déjà générée,
  /// pour alimenter l'historique et les moyennes.
  void recordEvaluationResult({
    required String moduleId,
    required String evaluationId,
    required double score,
  });

  /// Vérifie la note obtenue (seuil de réussite : 10/20), débloque le
  /// module suivant du niveau si la note est suffisante, et signale si le
  /// niveau supérieur vient d'être débloqué.
  ModuleValidationResult validateModule({required String moduleId, required double score});
}
