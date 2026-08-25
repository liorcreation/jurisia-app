import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../models/chat/conversation_model.dart';
import '../../../../models/chat/message_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../domain/repositories/litigation_conversation_store.dart';

/// Implémentation de [LitigationConversationStore] adossée aux tables
/// `litigation_conversations` / `litigation_messages` de Supabase. Les
/// écritures sont au mieux effort : un échec réseau est journalisé, jamais
/// remonté comme une erreur de conversation — perdre une sauvegarde ne doit
/// jamais interrompre l'échange avec l'IA.
class SupabaseLitigationConversationStore implements LitigationConversationStore {
  SupabaseLitigationConversationStore({required this.client, required this.userId});

  final SupabaseClient client;
  final String userId;

  @override
  Future<Conversation?> loadLatest() async {
    try {
      final conversationRows = await client
          .from('litigation_conversations')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1);

      if (conversationRows.isEmpty) return null;
      final row = conversationRows.first;

      final messageRows = await client
          .from('litigation_messages')
          .select()
          .eq('conversation_id', row['id'] as String)
          .order('created_at', ascending: true);

      final messages = messageRows.map((m) => _messageFromRow(m, row['id'] as String)).toList();

      return Conversation(
        id: row['id'] as String,
        title: row['title'] as String? ?? 'Nouvelle consultation',
        module: ConversationModule.litigeEtConsultation,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        domain: row['domain'] != null ? LegalDomain.fromName(row['domain'] as String) : null,
        complexity: row['complexity'] != null
            ? ComplexityLevel.values.firstWhere(
                (c) => c.name == row['complexity'],
                orElse: () => ComplexityLevel.simple,
              )
            : null,
        messages: messages,
        analysisGrid: row['analysis_grid'] != null
            ? LegalAnalysisGrid.fromJson(row['analysis_grid'] as Map<String, dynamic>)
            : const LegalAnalysisGrid(),
      );
    } catch (error) {
      // ignore: avoid_print
      print('Échec du chargement de la dernière consultation Supabase : $error');
      return null;
    }
  }

  ChatMessage _messageFromRow(Map<String, dynamic> row, String conversationId) {
    return ChatMessage(
      id: row['id'] as String,
      conversationId: conversationId,
      sender: MessageSender.values.firstWhere(
        (value) => value.name == row['sender'],
        orElse: () => MessageSender.user,
      ),
      content: row['content'] as String,
      timestamp: DateTime.parse(row['created_at'] as String),
      suggestedProfessional: row['suggested_professional'] as String?,
    );
  }

  @override
  Future<void> upsertConversation(Conversation conversation) async {
    try {
      await client.from('litigation_conversations').upsert({
        'id': conversation.id,
        'user_id': userId,
        'title': conversation.title,
        'domain': conversation.domain?.name,
        'complexity': conversation.complexity?.name,
        'analysis_grid': conversation.analysisGrid.toJson(),
        'updated_at': conversation.updatedAt.toIso8601String(),
      });
    } catch (error) {
      // ignore: avoid_print
      print('Échec de synchronisation de la consultation ${conversation.id} : $error');
    }
  }

  @override
  Future<void> appendMessage(ChatMessage message) async {
    try {
      await client.from('litigation_messages').insert({
        'id': message.id,
        'conversation_id': message.conversationId,
        'sender': message.sender.name,
        'content': message.content,
        'suggested_professional': message.suggestedProfessional,
        'created_at': message.timestamp.toIso8601String(),
      });
    } catch (error) {
      // ignore: avoid_print
      print('Échec de synchronisation du message ${message.id} : $error');
    }
  }
}
