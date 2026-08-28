import '../supabase/supabase_config.dart';
import 'billing_repository.dart';

/// Construit le [BillingRepository] adapté à l'environnement : l'Edge
/// Function `billing-checkout` si Supabase est configuré, sinon un dépôt
/// inerte qui signale l'indisponibilité.
BillingRepository buildBillingRepository() {
  if (!SupabaseConfig.isReady) return const UnavailableBillingRepository();
  return SupabaseBillingRepository(client: SupabaseConfig.client);
}
