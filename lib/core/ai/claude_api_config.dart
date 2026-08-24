/// Configuration de l'intégration avec l'API Anthropic Claude, partagée par
/// toutes les fonctionnalités de l'application qui s'appuient sur l'IA
/// (Litiges et consultations, Espace étudiant...).
class ClaudeApiConfig {
  const ClaudeApiConfig._();

  static const String baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String anthropicVersion = '2023-06-01';
  static const String model = 'claude-3-5-sonnet-20241022';
  static const int defaultMaxTokens = 1536;

  /// Clé API Anthropic, fournie au lancement via :
  /// `flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...`
  /// (et `flutter build ... --dart-define=ANTHROPIC_API_KEY=...` en build).
  ///
  /// ATTENTION SÉCURITÉ : cette intégration appelle l'API Anthropic
  /// directement depuis le client. La clé est donc embarquée dans le
  /// binaire et transite dans chaque requête réseau — elle est
  /// extractible, en particulier sur le Web où elle est visible dans les
  /// requêtes du navigateur. Cette approche convient au développement et à
  /// la démonstration ; avant toute mise en production, faites transiter
  /// ces appels par un backend qui détient la clé côté serveur (seule la
  /// classe [ClaudeApiConfig] et le datasource HTTP auraient alors à
  /// changer, le reste de l'architecture restant identique).
  static const String apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  static bool get hasApiKey => apiKey.isNotEmpty;
}
