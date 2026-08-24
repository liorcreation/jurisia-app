/// Erreur survenue lors de l'appel à l'API Claude : configuration
/// manquante, échec réseau, ou réponse d'erreur renvoyée par l'API.
class ClaudeApiException implements Exception {
  const ClaudeApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
