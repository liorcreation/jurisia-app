import '../../../../models/chat/conversation_model.dart';
import '../../../../models/chat/message_model.dart';
import '../../../../models/legal_document/legal_domain.dart';

/// Événement émis pendant le traitement d'une consultation par l'IA. Le
/// flux d'une réponse se compose toujours, dans l'ordre : un
/// [LitigationUserMessageChunk] (le message utilisateur, conservé dans
/// l'historique), zéro ou plusieurs [LitigationTextDeltaChunk] (le texte de
/// la réponse au fil de l'eau), puis exactement un [LitigationDoneChunk].
sealed class LitigationResponseChunk {
  const LitigationResponseChunk();
}

/// Le message utilisateur tel qu'ajouté à l'historique de la conversation.
class LitigationUserMessageChunk extends LitigationResponseChunk {
  const LitigationUserMessageChunk(this.message);

  final ChatMessage message;
}

/// Un fragment de texte visible de la réponse de l'IA, à afficher au fil de
/// l'eau pendant le streaming.
class LitigationTextDeltaChunk extends LitigationResponseChunk {
  const LitigationTextDeltaChunk(this.delta);

  final String delta;
}

/// La réponse de l'IA est terminée : le message assistant final, la grille
/// d'analyse interne mise à jour, et, si l'IA a pu les identifier, la
/// branche du droit et le niveau de complexité du dossier.
class LitigationDoneChunk extends LitigationResponseChunk {
  const LitigationDoneChunk({
    required this.assistantMessage,
    required this.updatedGrid,
    this.domain,
    this.complexity,
  });

  final ChatMessage assistantMessage;
  final LegalAnalysisGrid updatedGrid;
  final LegalDomain? domain;
  final ComplexityLevel? complexity;
}
