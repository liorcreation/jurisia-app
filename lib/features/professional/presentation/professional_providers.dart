import '../../../core/ai/groq_providers.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../library/data/datasources/legal_document_local_datasource.dart';
import '../../library/data/repositories/library_repository_impl.dart';
import '../data/datasources/professional_template_local_datasource.dart';
import '../data/repositories/professional_repository_impl.dart';
import 'controllers/professional_documents_controller.dart';

/// Assemble le [ProfessionalDocumentsController] fourni par la coquille
/// applicative ([AppShell]) — la section « Documents récents » de la
/// sidebar.
ProfessionalDocumentsController buildProfessionalDocumentsController() {
  final repository = ProfessionalRepositoryImpl(
    dataSource: buildGroqDataSource(),
    libraryRepository: LibraryRepositoryImpl(dataSource: const LocalLegalDocumentDataSource()),
    templateDataSource: const LocalProfessionalTemplateDataSource(),
    supabaseClient: SupabaseConfig.isReady ? SupabaseConfig.client : null,
    userId: SupabaseConfig.isReady ? SupabaseConfig.client.auth.currentUser?.id : null,
  );
  return ProfessionalDocumentsController(repository: repository);
}
