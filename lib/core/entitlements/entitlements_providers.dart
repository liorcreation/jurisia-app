import '../supabase/supabase_config.dart';
import 'entitlements_controller.dart';
import 'entitlements_repository.dart';

/// Assemble le [EntitlementsController] fourni par la coquille applicative
/// ([AppShell]) au-dessus de l'`IndexedStack`, pour que la porte d'accès des
/// modules (Litiges…) et l'écran « Mon abonnement » partagent le même état.
///
/// Dégrade proprement quand Supabase n'est pas configuré : offre Découverte,
/// consommation suivie en local uniquement.
EntitlementsController buildEntitlementsController() {
  final userId = SupabaseConfig.isReady ? SupabaseConfig.client.auth.currentUser?.id : null;

  final EntitlementsRepository repository = userId == null
      ? const FreePlanEntitlementsRepository()
      : SupabaseEntitlementsRepository(client: SupabaseConfig.client);

  return EntitlementsController(
    repository: repository,
    usageScope: userId,
  );
}
