import '../../../core/ai/groq_api_datasource.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/datasources/ai_evaluation_generator.dart';
import '../data/datasources/evaluation_question_bank.dart';
import '../data/datasources/student_curriculum_local_datasource.dart';
import '../data/repositories/student_repository_impl.dart';
import '../domain/repositories/student_repository.dart';
import '../domain/usecases/generate_evaluation_usecase.dart';
import '../domain/usecases/get_student_modules_usecase.dart';
import '../domain/usecases/validate_module_usecase.dart';
import 'controllers/student_controller.dart';

/// Assemble le [StudentController]. Fourni par la coquille applicative
/// ([AppShell]) pour que la sidebar (section « Votre progression ») et
/// l'écran Étudiant partagent le même état.
StudentController buildStudentController() {
  final StudentRepository repository = StudentRepositoryImpl(
    curriculumDataSource: const LocalStudentCurriculumDataSource(),
    questionBank: const LocalEvaluationQuestionBank(),
    aiGenerator: AiEvaluationGenerator(dataSource: GroqDataSource()),
    supabaseClient: SupabaseConfig.isReady ? SupabaseConfig.client : null,
    userId: SupabaseConfig.isReady ? SupabaseConfig.client.auth.currentUser?.id : null,
  );

  return StudentController(
    repository: repository,
    getModulesUseCase: GetStudentModulesUseCase(repository: repository),
    validateModuleUseCase: ValidateModuleUseCase(repository: repository),
    generateEvaluationUseCase: GenerateEvaluationUseCase(repository: repository),
  );
}
