import '../../../../models/chat/message_model.dart';

/// Événement émis pendant le traitement d'une question posée à l'assistant
/// IA d'un module : le message utilisateur conservé dans l'historique, le
/// texte de la réponse au fil de l'eau, puis la réponse complète.
sealed class ModuleTutorChunk {
  const ModuleTutorChunk();
}

class ModuleTutorUserMessageChunk extends ModuleTutorChunk {
  const ModuleTutorUserMessageChunk(this.message);

  final ChatMessage message;
}

class ModuleTutorTextDeltaChunk extends ModuleTutorChunk {
  const ModuleTutorTextDeltaChunk(this.delta);

  final String delta;
}

class ModuleTutorDoneChunk extends ModuleTutorChunk {
  const ModuleTutorDoneChunk(this.assistantMessage);

  final ChatMessage assistantMessage;
}
