/// Erreur survenue lors de l'appel au service d'IA générative : configuration
/// manquante, échec réseau, ou réponse d'erreur renvoyée par l'API.
class LlmApiException implements Exception {
  const LlmApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
