import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_document_draft.dart';

/// Frontière data vers le circuit de relecture du CMS Bibliothèque. Toute
/// écriture passe par une fonction SECURITY DEFINER tracée au journal
/// d'audit (voir migration_012_legal_document_review.sql) — jamais une
/// écriture directe sur `legal_document_drafts`.
abstract class AdminDocumentDraftRepository {
  Future<List<AdminDocumentDraft>> list();

  /// `draftId` null → crée un nouveau brouillon. Retourne l'id (nouveau ou
  /// existant). Lève une exception (message serveur en français) si le
  /// brouillon n'est plus modifiable (déjà en relecture ou publié).
  Future<String> saveDraft({
    required String? draftId,
    required String documentId,
    required Map<String, dynamic> payload,
  });

  Future<void> submit(String draftId);

  Future<void> review({
    required String draftId,
    required bool approve,
    String? reason,
  });

  Future<void> archiveDocument({required String documentId, String? reason});
}

class SupabaseAdminDocumentDraftRepository implements AdminDocumentDraftRepository {
  SupabaseAdminDocumentDraftRepository({required this.client});

  final SupabaseClient client;

  @override
  Future<List<AdminDocumentDraft>> list() async {
    final rows = await client.rpc('jurisia_admin_list_document_drafts');
    return (rows as List)
        .map((row) => AdminDocumentDraft.fromRow((row as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<String> saveDraft({
    required String? draftId,
    required String documentId,
    required Map<String, dynamic> payload,
  }) async {
    final id = await client.rpc('jurisia_admin_save_document_draft', params: {
      'p_draft_id': draftId,
      'p_document_id': documentId,
      'p_payload': payload,
    });
    return id as String;
  }

  @override
  Future<void> submit(String draftId) async {
    await client.rpc('jurisia_admin_submit_document_draft', params: {'p_draft_id': draftId});
  }

  @override
  Future<void> review({
    required String draftId,
    required bool approve,
    String? reason,
  }) async {
    await client.rpc('jurisia_admin_review_document_draft', params: {
      'p_draft_id': draftId,
      'p_decision': approve ? 'approve' : 'request_changes',
      if (reason != null && reason.isNotEmpty) 'p_reason': reason,
    });
  }

  @override
  Future<void> archiveDocument({required String documentId, String? reason}) async {
    await client.rpc('jurisia_admin_archive_document', params: {
      'p_document_id': documentId,
      if (reason != null && reason.isNotEmpty) 'p_reason': reason,
    });
  }
}
