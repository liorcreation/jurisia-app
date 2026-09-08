import '../supabase/supabase_config.dart';

/// URL publique de la console d'administration — un déploiement Cloudflare
/// Pages séparé (voir `lib/admin_main.dart`), jamais atteignable depuis
/// cette app grand public autrement que par ce lien externe. Utilisée en
/// repli quand [requestAdminHandoffLink] échoue.
const String kAdminConsoleUrl = 'https://jurisia-admin.pages.dev/';

/// Demande à l'Edge Function `admin-handoff` un lien d'authentification à
/// usage unique pour rejoindre la console d'administration sans ressaisir
/// ses identifiants. La session Supabase ne se partage jamais entre deux
/// origines web différentes (jurisia-app.pages.dev / jurisia-admin
/// .pages.dev) — ce lien est le pont, valable une seule fois et de courte
/// durée. Renvoie `null` si la demande échoue (fonction pas encore
/// déployée, compte non membre du personnel, etc.) : l'appelant se rabat
/// alors sur [kAdminConsoleUrl], jamais un blocage silencieux.
Future<String?> requestAdminHandoffLink() async {
  if (!SupabaseConfig.isReady) return null;
  try {
    final response = await SupabaseConfig.client.functions.invoke('admin-handoff');
    final data = response.data;
    if (data is Map) return data['actionLink'] as String?;
    return null;
  } catch (_) {
    return null;
  }
}
