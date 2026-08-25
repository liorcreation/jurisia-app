/// Configuration de l'intégration avec le relais JurisIA vers Groq (voir
/// `server/groq-proxy/`), partagée par toutes les fonctionnalités de
/// l'application qui s'appuient sur l'IA (Litiges et consultations, Espace
/// étudiant, Espace professionnel...).
///
/// Le client Flutter ne détient plus aucune clé API Groq : le relais
/// Cloudflare Worker détient la clé côté serveur et n'expose au client que
/// son URL publique — voir `server/groq-proxy/README.md` pour le déployer.
class GroqApiConfig {
  const GroqApiConfig._();

  /// URL du relais Cloudflare Worker déployé (`server/groq-proxy/`),
  /// surchargeable via `--dart-define=GROQ_PROXY_URL=...` si vous déployez
  /// votre propre instance. Ce n'est PAS un secret : c'est une URL publique,
  /// commitée sans risque, contrairement à une clé API.
  static const String endpoint = String.fromEnvironment(
    'GROQ_PROXY_URL',
    defaultValue: 'https://jurisia-groq-proxy.jurisia-api.workers.dev/v1/chat/completions',
  );

  static bool get hasEndpoint => endpoint.isNotEmpty;

  /// Modèle Groq utilisé par le relais, surchargeable sans recompiler la
  /// logique via `--dart-define=GROQ_MODEL=...`.
  ///
  /// Note : la famille Llama 3.x (`llama-3.3-70b-versatile`,
  /// `llama-3.1-8b-instant`) a été retirée du catalogue Groq — les deux
  /// renvoient une erreur 404 `model_not_found`, vérifié empiriquement le
  /// 25/08/2026 via `GET /openai/v1/models`. `openai/gpt-oss-120b` a été
  /// vérifié disponible et fonctionnel (réponse et streaming testés) et le
  /// remplace comme modèle par défaut.
  static const String model = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'openai/gpt-oss-120b',
  );

  static const int defaultMaxTokens = 1536;
}
