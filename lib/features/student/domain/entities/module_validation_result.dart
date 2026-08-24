import '../../../../models/student/course_module.dart';
import '../../../../models/student/student_level.dart';

/// Résultat de la validation d'une évaluation de module : issue de la
/// tentative et effets en cascade éventuels (déblocage du module suivant,
/// voire du niveau supérieur si tous les modules du niveau sont validés).
class ModuleValidationResult {
  const ModuleValidationResult({
    required this.moduleId,
    required this.score,
    required this.passed,
    required this.updatedModule,
    this.unlockedNextModuleId,
    this.levelCompleted = false,
    this.unlockedNextLevel,
  });

  final String moduleId;
  final double score;

  /// `true` si la note est supérieure ou égale à 10/20.
  final bool passed;

  final CourseModule updatedModule;

  /// Identifiant du module suivant si cette réussite vient de le débloquer.
  final String? unlockedNextModuleId;

  /// `true` si tous les modules du niveau sont désormais validés.
  final bool levelCompleted;

  /// Niveau supérieur débloqué si [levelCompleted] est vrai et qu'un niveau
  /// suivant existe.
  final AcademicLevel? unlockedNextLevel;
}
