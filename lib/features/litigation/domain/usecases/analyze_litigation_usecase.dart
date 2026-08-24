import 'package:uuid/uuid.dart';

import '../../../../models/chat/conversation_model.dart';
import '../../../../models/chat/message_model.dart';
import '../entities/litigation_response_chunk.dart';
import '../repositories/litigation_repository.dart';

/// Orchestre une consultation : construit et conserve l'historique de la
/// conversation en y ajoutant le nouveau message utilisateur, délègue
/// l'analyse au [LitigationRepository], et relaie la mise à jour de la
/// grille d'analyse interne portée par la réponse de l'IA.
class AnalyzeLitigationUseCase {
  AnalyzeLitigationUseCase({required this.repository, Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final LitigationRepository repository;
  final Uuid _uuid;

  Stream<LitigationResponseChunk> call({
    required Conversation conversation,
    required String userMessage,
  }) async* {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Le message ne peut pas être vide.');
    }

    final userChatMessage = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversation.id,
      sender: MessageSender.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    yield LitigationUserMessageChunk(userChatMessage);

    final history = [...conversation.messages, userChatMessage];

    yield* repository.sendMessage(messages: history, currentGrid: conversation.analysisGrid);
  }

  void dispose() => repository.dispose();
}
