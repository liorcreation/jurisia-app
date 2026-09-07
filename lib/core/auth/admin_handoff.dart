import '../supabase/supabase_config.dart';

/// Demande à l'Edge Function `admin-handoff` un lien d'authentification à
/// usage unique pour rejoindre la console d'administration sans ressaisir
/// ses identifiants. La session Supabase ne se partage jamais entre deux
/// origines web différentes (jurisia-app.pages.dev / jurisia-admin
/// .pages.dev) — ce lien est le pont, valable une seule fois et de courte
/// durée. Renvoie `null` si la demande échoue (fonction pas encore
/// déployée, compte non membre du personnel, etc.) : l'appelant se rabat
/// alors sur le simple lien public vers la console, jamais un blocage
/// silencieux — voir `kAdminConsoleUrl` (staff_redirect_prompt.dart).
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
