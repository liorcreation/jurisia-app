import '../../../../models/student/evaluation_model.dart';
import '../repositories/student_repository.dart';

/// Génère dynamiquement un nouveau jeu de questions pour une tentative
/// d'évaluation de module : IA (tuteur académique) si configurée et
/// disponible, banque de questions locale sinon. Chaque appel renouvelle
/// le jeu de questions par rapport à la tentative précédente.
class GenerateEvaluationUseCase {
  GenerateEvaluationUseCase({required this.repository});

  final StudentRepository repository;

  Future<ModuleEvaluation> call(String moduleId) => repository.generateEvaluation(moduleId);
}
