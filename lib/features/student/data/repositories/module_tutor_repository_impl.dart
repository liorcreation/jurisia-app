import 'package:uuid/uuid.dart';

import '../../../../core/ai/groq_api_datasource.dart';
import '../../../../core/ai/prompt_keys.dart';
import '../../../../core/ai/prompt_overrides.dart';
import '../../../../models/chat/message_model.dart';
import '../../../../models/student/course_module.dart';
import '../../domain/entities/module_tutor_chunk.dart';
import '../../domain/repositories/module_tutor_repository.dart';
import '../datasources/student_ai_prompts.dart';

/// Implémentation du [ModuleTutorRepository] s'appuyant sur le client IA
/// partagé (Groq), avec un system prompt restreignant l'assistant au
/// contenu du module.
class ModuleTutorRepositoryImpl implements ModuleTutorRepository {
  ModuleTutorRepositoryImpl({required this.dataSource, Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final LlmDataSource dataSource;
  final Uuid _uuid;

  @override
  Stream<ModuleTutorChunk> sendMessage({
    required CourseModule module,
    required List<ChatMessage> messages,
  }) async* {
    final apiMessages = _buildApiMessages(messages);
    if (apiMessages.isEmpty) {
      throw StateError('Aucun message utilisateur à transmettre.');
    }

    final conversationId = messages.last.conversationId;
    final system = await PromptOverrides.compose(
      PromptKeys.tuteur,
      StudentAiPrompts.moduleTutorSystemPrompt(module),
    );

    final buffer = StringBuffer();
    await for (final delta in dataSource.streamCompletion(system: system, messages: apiMessages)) {
      buffer.write(delta);
      yield ModuleTutorTextDeltaChunk(delta);
    }

    yield ModuleTutorDoneChunk(
      ChatMessage(
        id: _uuid.v4(),
        conversationId: conversationId,
        sender: MessageSender.assistant,
        content: buffer.toString().trim(),
        timestamp: DateTime.now(),
      ),
    );
  }

  List<Map<String, String>> _buildApiMessages(List<ChatMessage> messages) {
    final startIndex = messages.indexWhere((m) => m.sender == MessageSender.user);
    if (startIndex == -1) return const [];

    return messages
        .sublist(startIndex)
        .where((m) => m.sender == MessageSender.user || m.sender == MessageSender.assistant)
        .map((m) => {'role': m.sender == MessageSender.user ? 'user' : 'assistant', 'content': m.content})
        .toList();
  }

  @override
  void dispose() => dataSource.dispose();
}
