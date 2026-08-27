import 'package:flutter/foundation.dart';
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

  /// Journalise un échec de persistance. En production les écritures restent
  /// au mieux effort — perdre une sauvegarde ne doit jamais interrompre
  /// l'échange avec l'IA. Mais en développement, un échec — surtout un schéma
  /// Supabase désynchronisé (colonne absente, migration non appliquée), qui
  /// casse *toute* la persistance en silence — doit sauter aux yeux plutôt
  /// que de se noyer dans les logs.
  void _reportFailure(String operation, Object error) {
    assert(() {
      debugPrint('⚠️  SupabaseLitigationConversationStore.$operation a échoué : $error');
      if (error is PostgrestException &&
          (error.code == '42703' || // colonne inexistante
              error.code == '42P01' || // table inexistante
              error.code == 'PGRST204' || // colonne absente du cache de schéma
              error.code == 'PGRST205')) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          library: 'litigation persistence',
          context: ErrorDescription(
            'Schéma Supabase désynchronisé pendant "$operation" — une migration '
            'manque probablement (voir server/supabase/migration_*.sql). '
            "Tant que ce n'est pas corrigé, aucune consultation n'est "
            'enregistrée et l\'historique reste vide au redémarrage.',
          ),
        ));
      }
      return true;
    }());
  }

  @override
  Future<List<Conversation>> listConversations() async {
    try {
      final rows = await client
          .from('litigation_conversations')
          .select('id, title, domain, complexity, is_favorite, created_at, updated_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(50);

      return rows.map(_summaryFromRow).toList();
    } catch (error) {
      _reportFailure('listConversations', error);
      return const [];
    }
  }

  @override
  Future<Conversation?> loadConversation(String id) async {
    try {
      final conversationRows =
          await client.from('litigation_conversations').select().eq('id', id).limit(1);

      if (conversationRows.isEmpty) return null;
      return _loadFullConversation(conversationRows.first);
    } catch (error) {
      _reportFailure('loadConversation($id)', error);
      return null;
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    try {
      // Les messages liés partent automatiquement (foreign key `on delete
      // cascade` sur litigation_messages.conversation_id, voir schema.sql) :
      // pas besoin d'une suppression séparée.
      await client.from('litigation_conversations').delete().eq('id', id);
    } catch (error) {
      _reportFailure('deleteConversation($id)', error);
    }
  }

  /// Charge les messages d'une consultation dont la ligne est déjà connue,
  /// et assemble le [Conversation] complet — factorisé entre [loadLatest]
  /// et [loadConversation], qui ne diffèrent que par la façon dont ils
  /// trouvent la ligne de départ.
  Future<Conversation> _loadFullConversation(Map<String, dynamic> row) async {
    final messageRows = await client
        .from('litigation_messages')
        .select()
        .eq('conversation_id', row['id'] as String)
        .order('created_at', ascending: true);

    final messages = messageRows.map((m) => _messageFromRow(m, row['id'] as String)).toList();
    return _summaryFromRow(row).copyWith(messages: messages);
  }

  /// Construit un [Conversation] résumé (sans messages) depuis une ligne de
  /// `litigation_conversations`.
  Conversation _summaryFromRow(Map<String, dynamic> row) {
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
      analysisGrid: row['analysis_grid'] != null
          ? LegalAnalysisGrid.fromJson(row['analysis_grid'] as Map<String, dynamic>)
          : const LegalAnalysisGrid(),
      isFavorite: row['is_favorite'] as bool? ?? false,
    );
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
        'is_favorite': conversation.isFavorite,
        'updated_at': conversation.updatedAt.toIso8601String(),
      });
    } catch (error) {
      _reportFailure('upsertConversation(${conversation.id})', error);
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
      _reportFailure('appendMessage(${message.id})', error);
    }
  }
}
