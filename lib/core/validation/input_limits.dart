/// Limites de longueur appliquées aux champs de saisie envoyés à l'IA.
///
/// Ce ne sont que des garde-fous côté client (meilleure expérience,
/// évitent un envoi accidentel démesuré) : la limite qui compte vraiment
/// pour la sécurité et la maîtrise des coûts est appliquée côté serveur,
/// dans `server/groq-proxy/`, puisqu'un client modifié ou un appel direct à
/// l'API pourrait toujours contourner celles-ci.
class AppInputLimits {
  const AppInputLimits._();

  /// Message de chat (Litiges et consultations, tuteur de module).
  static const int chatMessage = 4000;

  /// Champ court d'un formulaire de rédaction (nom, montant, poste...).
  static const int shortField = 200;

  /// Instructions complémentaires (rédaction, audit).
  static const int instructions = 1000;

  /// Texte d'un contrat soumis à l'audit.
  static const int contractText = 15000;

  /// Question de consultation approfondie.
  static const int consultationQuestion = 3000;

  /// Description du besoin dans une demande de mise en relation
  /// (Contacter un professionnel).
  static const int contactMessage = 1000;
}
