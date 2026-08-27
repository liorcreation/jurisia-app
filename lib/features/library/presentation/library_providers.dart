import '../../../core/supabase/supabase_config.dart';
import '../data/datasources/legal_document_local_datasource.dart';
import '../data/repositories/library_repository_impl.dart';
import '../domain/repositories/library_repository.dart';
import '../domain/usecases/search_legal_documents_usecase.dart';
import '../domain/usecases/toggle_bookmark_usecase.dart';
import 'controllers/library_controller.dart';

/// Assemble le [LibraryController]. Fourni par la coquille applicative
/// ([AppShell]) pour que la sidebar (section « Favoris ») et l'écran
/// Bibliothèque partagent le même état.
LibraryController buildLibraryController() {
  final LibraryRepository repository = LibraryRepositoryImpl(
    dataSource: const LocalLegalDocumentDataSource(),
    supabaseClient: SupabaseConfig.isReady ? SupabaseConfig.client : null,
    userId: SupabaseConfig.isReady ? SupabaseConfig.client.auth.currentUser?.id : null,
  );
  return LibraryController(
    searchUseCase: SearchLegalDocumentsUseCase(repository: repository),
    toggleBookmarkUseCase: ToggleBookmarkUseCase(repository: repository),
    repository: repository,
  );
}
