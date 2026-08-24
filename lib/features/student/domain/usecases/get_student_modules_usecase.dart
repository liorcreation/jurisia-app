import '../../../../models/student/course_module.dart';
import '../../../../models/student/student_level.dart';
import '../repositories/student_repository.dart';

/// Récupère le programme d'un niveau, module par module, avec l'état de
/// progression courant de l'étudiant (déblocage, validation, dernière note).
class GetStudentModulesUseCase {
  GetStudentModulesUseCase({required this.repository});

  final StudentRepository repository;

  List<CourseModule> call(AcademicLevel level) => repository.modulesForLevel(level);
}
