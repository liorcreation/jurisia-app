import '../../../../models/chat/conversation_model.dart';
import '../../../../models/chat/message_model.dart';

/// Frontière du domaine vers la persistance d'une consultation — distincte
/// de [LitigationRepository], qui ne s'occupe que de parler à l'IA. Permet
/// à la conversation de survivre à un redémarrage sans coupler le domaine à
/// Supabase ou à tout autre fournisseur de stockage.
abstract class LitigationConversationStore {
  /// La consultation la plus récente de l'utilisateur pour ce module, ou
  /// `null` s'il n'en a encore aucune.
  Future<Conversation?> loadLatest();

  /// Résumés de toutes les consultations de l'utilisateur (titre, dates,
  /// branche du droit — `messages` vide), triés du plus récent au plus
  /// ancien, pour alimenter le panneau d'historique.
  Future<List<Conversation>> listConversations();

  /// Une consultation précise avec l'ensemble de ses messages, ou `null` si
  /// elle n'existe pas (ou plus).
  Future<Conversation?> loadConversation(String id);

  /// Supprime définitivement une consultation et son historique de
  /// messages.
  Future<void> deleteConversation(String id);

  /// Crée ou met à jour les métadonnées d'une consultation (titre, branche
  /// du droit, complexité, grille d'analyse).
  Future<void> upsertConversation(Conversation conversation);

  /// Ajoute un message à l'historique persisté d'une consultation.
  Future<void> appendMessage(ChatMessage message);
}
