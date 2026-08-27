import '../../../core/ai/groq_api_datasource.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/repositories/litigation_repository_impl.dart';
import '../data/repositories/supabase_litigation_conversation_store.dart';
import '../domain/repositories/litigation_conversation_store.dart';
import '../domain/usecases/analyze_litigation_usecase.dart';
import '../domain/usecases/generate_conversation_title_usecase.dart';
import 'controllers/litigation_chat_controller.dart';

/// Assemble le [LitigationChatController] du module « Litiges et
/// consultations ». Extrait de `litigation_screen.dart` pour que la coquille
/// applicative ([AppShell]) puisse fournir ce contrôleur au-dessus de
/// l'`IndexedStack` — la sidebar unifiée pilote l'historique des
/// consultations, l'écran de chat n'en est plus qu'un consommateur.
LitigationChatController buildLitigationChatController() {
  final repository = LitigationRepositoryImpl(dataSource: GroqDataSource());
  return LitigationChatController(
    useCase: AnalyzeLitigationUseCase(repository: repository),
    generateTitleUseCase: GenerateConversationTitleUseCase(repository: repository),
    conversationStore: _buildConversationStore(),
  );
}

LitigationConversationStore? _buildConversationStore() {
  if (!SupabaseConfig.isReady) return null;
  final userId = SupabaseConfig.client.auth.currentUser?.id;
  if (userId == null) return null;
  return SupabaseLitigationConversationStore(client: SupabaseConfig.client, userId: userId);
}
