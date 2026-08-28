import 'package:supabase_flutter/supabase_flutter.dart';

import 'staff_role.dart';

/// Frontière data vers les rôles de personnel (table `staff_roles`).
abstract class StaffRepository {
  /// Rôles de l'utilisateur actuellement connecté. Renvoie
  /// [StaffIdentity.none] si non connecté, si l'utilisateur n'est pas
  /// membre du personnel, ou en cas d'échec — la console refuse alors
  /// l'accès, ce qui est le comportement sûr.
  Future<StaffIdentity> currentIdentity();
}

class SupabaseStaffRepository implements StaffRepository {
  SupabaseStaffRepository({required this.client});

  final SupabaseClient client;

  @override
  Future<StaffIdentity> currentIdentity() async {
    final user = client.auth.currentUser;
    if (user == null) return const StaffIdentity.none();

    try {
      final rows = await client.from('staff_roles').select('role').eq('user_id', user.id);
      final roles = <StaffRole>{};
      for (final row in rows as List) {
        final role = StaffRole.fromWireName((row as Map)['role'] as String?);
        if (role != null) roles.add(role);
      }
      return StaffIdentity(roles);
    } catch (error) {
      // Table absente (migration 006 non appliquée) ou erreur réseau :
      // accès refusé, jamais ouvert par défaut.
      // ignore: avoid_print
      print('Lecture des rôles de personnel impossible : $error');
      return const StaffIdentity.none();
    }
  }
}
