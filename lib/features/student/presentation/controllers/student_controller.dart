import 'package:flutter/foundation.dart';

import '../../../../models/student/course_module.dart';
import '../../../../models/student/student_level.dart';
import '../../../../models/student/student_progress_model.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/usecases/generate_evaluation_usecase.dart';
import '../../domain/usecases/get_student_modules_usecase.dart';
import '../../domain/usecases/validate_module_usecase.dart';

/// Contrôleur d'état de l'Espace étudiant : niveau sélectionné, parcours de
/// modules et progression associée. Expose également le repository et les
/// use cases partagés afin que les écrans descendants (module, évaluation)
/// puissent construire leurs propres contrôleurs sur le même état.
class StudentController extends ChangeNotifier {
  StudentController({
    required this.repository,
    required this.getModulesUseCase,
    required this.validateModuleUseCase,
    required this.generateEvaluationUseCase,
  }) {
    repository.hydrate().then((_) => notifyListeners());
  }

  final StudentRepository repository;
  final GetStudentModulesUseCase getModulesUseCase;
  final ValidateModuleUseCase validateModuleUseCase;
  final GenerateEvaluationUseCase generateEvaluationUseCase;

  AcademicLevel? _selectedLevel;
  AcademicLevel? get selectedLevel => _selectedLevel;

  List<CourseModule> get modulesForSelectedLevel =>
      _selectedLevel == null ? const [] : getModulesUseCase(_selectedLevel!);

  StudentProgress? get progressForSelectedLevel =>
      _selectedLevel == null ? null : repository.progressForLevel(_selectedLevel!);

  bool isLevelUnlocked(AcademicLevel level) => repository.isLevelUnlocked(level);

  /// Modules d'un niveau donné (avec leur état de progression courant),
  /// quel que soit le niveau actuellement sélectionné.
  List<CourseModule> modulesForLevel(AcademicLevel level) => getModulesUseCase(level);

  /// `true` si tous les modules du niveau ont été validés (moyenne ≥ 10/20).
  /// Ne préjuge pas de l'examen blanc — voir [isLevelFullyCleared].
  bool isLevelCompleted(AcademicLevel level) {
    final modules = getModulesUseCase(level);
    return modules.isNotEmpty && modules.every((module) => module.isCompleted);
  }

  /// `true` si l'étudiant a déjà réussi l'examen blanc de ce niveau.
  bool hasPassedMockExamForLevel(AcademicLevel level) => repository.hasPassedMockExamForLevel(level);

  /// `true` si le niveau est vraiment terminé : tous les modules validés
  /// ET l'examen blanc réussi — c'est cette condition, pas seulement
  /// [isLevelCompleted], qui débloque le niveau supérieur (voir
  /// [StudentRepository.isLevelUnlocked]) et doit gouverner l'affichage
  /// "niveau validé" dans l'UI.
  bool isLevelFullyCleared(AcademicLevel level) => isLevelCompleted(level) && hasPassedMockExamForLevel(level);

  /// À appeler dès qu'une tentative d'examen blanc est réussie (voir
  /// `MockExamController.onPassed`), pour que le déblocage du niveau
  /// supérieur soit reflété immédiatement sans attendre une réhydratation.
  void recordMockExamPassed(AcademicLevel level) {
    repository.recordMockExamPassed(level);
    notifyListeners();
  }

  void selectLevel(AcademicLevel level) {
    _selectedLevel = level;
    notifyListeners();
  }

  void backToLevelSelection() {
    _selectedLevel = null;
    notifyListeners();
  }

  /// À appeler au retour d'un écran ayant pu modifier la progression
  /// (évaluation validée) pour que le parcours affiché reflète les
  /// nouveaux déblocages.
  void refresh() => notifyListeners();
}
