import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/staff_role.dart';
import 'admin_staff_member.dart';

/// Frontière data vers la gestion du personnel, côté console. Toute
/// mutation passe par une fonction SECURITY DEFINER tracée au journal
/// d'audit (voir migration_011_staff_management.sql) — jamais une écriture
/// directe sur `staff_roles`, qui n'a aucune politique insert/update/delete.
abstract class AdminStaffRepository {
  Future<List<AdminStaffMember>> list();

  /// Lève une exception (message serveur en français) si l'appelant n'est
  /// pas super_admin, si le rôle est invalide, ou si aucun compte JurisIA
  /// ne correspond à [email].
  Future<void> grantRole({required String email, required StaffRole role});

  /// Lève une exception si l'appelant n'est pas super_admin, ou si ce
  /// serait retirer le tout dernier super_admin.
  Future<void> revokeRole({required String userId, required StaffRole role});
}

class SupabaseAdminStaffRepository implements AdminStaffRepository {
  SupabaseAdminStaffRepository({required this.client});

  final SupabaseClient client;

  @override
  Future<List<AdminStaffMember>> list() async {
    final rows = await client.rpc('jurisia_admin_list_staff');
    return (rows as List)
        .map((row) => AdminStaffMember.fromRow((row as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<void> grantRole({required String email, required StaffRole role}) async {
    await client.rpc('jurisia_admin_grant_staff_role', params: {
      'p_email': email,
      'p_role': role.wireName,
    });
  }

  @override
  Future<void> revokeRole({required String userId, required StaffRole role}) async {
    await client.rpc('jurisia_admin_revoke_staff_role', params: {
      'p_user_id': userId,
      'p_role': role.wireName,
    });
  }
}
