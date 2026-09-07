import '../supabase/supabase_config.dart';

/// Un compte a-t-il un rôle de personnel (table `staff_roles`) ? Vérifié
/// sans dépendre du module admin — frontière volontaire : aucun code de
/// `lib/admin/` n'entre dans le bundle grand public. La RLS de
/// `staff_roles` limite déjà la lecture au personnel authentifié ; un
/// compte sans rôle reçoit une liste vide, jamais une erreur. Partagé par
/// [StaffRedirectPrompt] (fenêtre à la connexion) et [AdminPortalBadge]
/// (accès permanent) pour ne définir la requête qu'une fois.
Future<bool> isStaffAccount() async {
  final client = SupabaseConfig.client;
  final user = client.auth.currentUser;
  if (user == null) return false;
  try {
    final rows = await client.from('staff_roles').select('role').eq('user_id', user.id).limit(1);
    return (rows as List).isNotEmpty;
  } catch (_) {
    return false;
  }
}
