import '../../../core/supabase/supabase_config.dart';
import '../data/repositories/contact_professional_repository_impl.dart';
import '../domain/repositories/contact_professional_repository.dart';
import '../domain/usecases/submit_contact_request_usecase.dart';
import 'controllers/contact_professional_controller.dart';

/// Assemble le [ContactProfessionalController]. Fourni par la coquille
/// applicative ([AppShell]) pour que la sidebar (section « Mes demandes »)
/// et l'écran Contacter partagent le même état.
ContactProfessionalController buildContactProfessionalController() {
  final ContactProfessionalRepository repository = ContactProfessionalRepositoryImpl(
    supabaseClient: SupabaseConfig.isReady ? SupabaseConfig.client : null,
    userId: SupabaseConfig.isReady ? SupabaseConfig.client.auth.currentUser?.id : null,
  );
  return ContactProfessionalController(
    repository: repository,
    submitUseCase: SubmitContactRequestUseCase(repository: repository),
  );
}
