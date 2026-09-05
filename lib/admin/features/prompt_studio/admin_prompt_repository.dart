import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ai/groq_api_datasource.dart';
import 'admin_ai_prompt.dart';

/// Frontière data vers le Studio de prompts. Toute écriture passe par une
/// fonction SECURITY DEFINER tracée au journal d'audit (voir
/// migration_013_ai_prompts.sql) — jamais une écriture directe sur
/// `ai_prompts`.
abstract class AdminPromptRepository {
  Future<List<AdminAiPrompt>> list();

  Future<String> saveDraft({required String? draftId, required String key, required String content});

  /// Appelle le modèle avec [draftContent] comme instruction système et
  /// [testMessage] comme unique message utilisateur — un aller simple, hors
  /// de toute conversation réelle — puis enregistre le résultat côté
  /// serveur. Retourne la réponse obtenue.
  Future<String> testDraft({
    required String draftId,
    required String draftContent,
    required String testMessage,
  });

  Future<void> publish(String draftId);
}

class SupabaseAdminPromptRepository implements AdminPromptRepository {
  SupabaseAdminPromptRepository({required this.client, required this.llm});

  final SupabaseClient client;
  final LlmDataSource llm;

  @override
  Future<List<AdminAiPrompt>> list() async {
    final rows = await client.rpc('jurisia_admin_list_prompts');
    return (rows as List)
        .map((row) => AdminAiPrompt.fromRow((row as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<String> saveDraft({
    required String? draftId,
    required String key,
    required String content,
  }) async {
    final id = await client.rpc('jurisia_admin_save_prompt_draft', params: {
      'p_draft_id': draftId,
      'p_key': key,
      'p_content': content,
    });
    return id as String;
  }

  @override
  Future<String> testDraft({
    required String draftId,
    required String draftContent,
    required String testMessage,
  }) async {
    final buffer = StringBuffer();
    await for (final delta in llm.streamCompletion(
      system: draftContent,
      messages: [
        {'role': 'user', 'content': testMessage},
      ],
      maxTokens: 700,
    )) {
      buffer.write(delta);
    }
    final response = buffer.toString();

    await client.rpc('jurisia_admin_record_prompt_test', params: {
      'p_draft_id': draftId,
      'p_test_message': testMessage,
      'p_test_response': response,
    });
    return response;
  }

  @override
  Future<void> publish(String draftId) async {
    await client.rpc('jurisia_admin_publish_prompt_draft', params: {'p_draft_id': draftId});
  }
}
