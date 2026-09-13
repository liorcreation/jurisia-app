import '../../../core/supabase/supabase_config.dart';
import '../data/repositories/professional_service_request_repository_impl.dart';
import '../domain/repositories/professional_service_request_repository.dart';
import '../domain/usecases/submit_professional_service_request_usecase.dart';
import 'controllers/professional_service_request_controller.dart';

ProfessionalServiceRequestController
buildProfessionalServiceRequestController() {
  final ProfessionalServiceRequestRepository repository =
      ProfessionalServiceRequestRepositoryImpl(
        supabaseClient: SupabaseConfig.isReady ? SupabaseConfig.client : null,
        userId: SupabaseConfig.isReady
            ? SupabaseConfig.client.auth.currentUser?.id
            : null,
      );
  return ProfessionalServiceRequestController(
    repository: repository,
    submitUseCase: SubmitProfessionalServiceRequestUseCase(
      repository: repository,
    ),
  );
}
