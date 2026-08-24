import 'package:uuid/uuid.dart';

import '../../../../models/chat/message_model.dart';
import '../../../../models/student/course_module.dart';
import '../entities/module_tutor_chunk.dart';
import '../repositories/module_tutor_repository.dart';

/// Orchestre une question posée à l'assistant IA d'un module : conserve
/// l'historique de la conversation et délègue la réponse, restreinte au
/// contexte du cours, au [ModuleTutorRepository].
class AskModuleTutorUseCase {
  AskModuleTutorUseCase({required this.repository, Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final ModuleTutorRepository repository;
  final Uuid _uuid;

  Stream<ModuleTutorChunk> call({
    required CourseModule module,
    required List<ChatMessage> history,
    required String userMessage,
  }) async* {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Le message ne peut pas être vide.');
    }

    final userChatMessage = ChatMessage(
      id: _uuid.v4(),
      conversationId: module.id,
      sender: MessageSender.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    yield ModuleTutorUserMessageChunk(userChatMessage);

    final updatedHistory = [...history, userChatMessage];
    yield* repository.sendMessage(module: module, messages: updatedHistory);
  }

  void dispose() => repository.dispose();
}
