import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/contact_professional/domain/entities/contact_request.dart';
import 'admin_contact_request.dart';

/// Frontière data vers les demandes de mise en relation, côté console.
abstract class AdminContactRequestRepository {
  Future<List<AdminContactRequest>> list();

  /// Change le statut d'une demande via la fonction tracée
  /// `jurisia_admin_set_contact_status` (écrit aussi au journal d'audit).
  Future<AdminContactRequest> setStatus(
    String id,
    ContactRequestStatus status, {
    String? reason,
  });
}

class SupabaseAdminContactRequestRepository implements AdminContactRequestRepository {
  SupabaseAdminContactRequestRepository({required this.client});

  final SupabaseClient client;

  @override
  Future<List<AdminContactRequest>> list() async {
    final rows = await client
        .from('professional_contact_requests')
        .select()
        .order('created_at', ascending: false)
        .limit(200);
    return (rows as List)
        .map((row) => AdminContactRequest.fromRow((row as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<AdminContactRequest> setStatus(
    String id,
    ContactRequestStatus status, {
    String? reason,
  }) async {
    final row = await client.rpc('jurisia_admin_set_contact_status', params: {
      'p_request_id': id,
      'p_status': status.name,
      if (reason != null && reason.isNotEmpty) 'p_reason': reason,
    });
    return AdminContactRequest.fromRow((row as Map).cast<String, dynamic>());
  }
}
