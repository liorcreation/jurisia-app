import '../../auth/staff_role.dart';

/// Une ligne de `staff_roles`, avec l'e-mail résolu côté serveur (voir
/// `jurisia_admin_list_staff` — `auth.users` n'est pas exposé au client).
class AdminStaffMember {
  const AdminStaffMember({
    required this.userId,
    required this.email,
    required this.role,
    required this.grantedByEmail,
    required this.grantedAt,
  });

  factory AdminStaffMember.fromRow(Map<String, dynamic> row) {
    return AdminStaffMember(
      userId: row['user_id'] as String,
      email: row['email'] as String? ?? '—',
      role: StaffRole.fromWireName(row['role'] as String?) ?? StaffRole.supportAgent,
      grantedByEmail: row['granted_by_email'] as String?,
      grantedAt: DateTime.tryParse(row['granted_at'] as String? ?? ''),
    );
  }

  final String userId;
  final String email;
  final StaffRole role;
  final String? grantedByEmail;
  final DateTime? grantedAt;
}
