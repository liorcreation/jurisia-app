import '../entities/module_validation_result.dart';
import '../repositories/student_repository.dart';

/// Vérifie la note obtenue à une évaluation de module (seuil de réussite :
/// 10/20) et applique le déblocage séquentiel du module suivant, et le cas
/// échéant du niveau supérieur si le niveau est intégralement validé.
class ValidateModuleUseCase {
  ValidateModuleUseCase({required this.repository});

  final StudentRepository repository;

  ModuleValidationResult call({required String moduleId, required double score}) {
    return repository.validateModule(moduleId: moduleId, score: score);
  }
}
