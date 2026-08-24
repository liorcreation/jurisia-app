import '../../../../models/chat/conversation_model.dart';
import '../../../../models/chat/message_model.dart';
import '../entities/litigation_response_chunk.dart';

/// Frontière du domaine vers le service d'intelligence artificielle chargé
/// d'analyser les consultations. L'implémentation concrète (API Claude,
/// backend propriétaire, etc.) vit dans la couche data et reste invisible
/// depuis le domaine et la présentation.
abstract class LitigationRepository {
  /// Envoie l'historique complet des messages (le dernier étant le message
  /// utilisateur à traiter) et la grille d'analyse courante, puis retourne
  /// un flux d'événements représentant la réponse de l'IA au fil de l'eau.
  Stream<LitigationResponseChunk> sendMessage({
    required List<ChatMessage> messages,
    required LegalAnalysisGrid currentGrid,
  });

  /// Libère les ressources réseau sous-jacentes (connexion HTTP persistante).
  void dispose();
}
