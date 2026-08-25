import 'package:flutter/services.dart' show rootBundle;

/// Configuration de l'intégration avec l'API Groq (point d'entrée compatible
/// OpenAI), partagée par toutes les fonctionnalités de l'application qui
/// s'appuient sur l'IA (Litiges et consultations, Espace étudiant, Espace
/// professionnel...).
class GroqApiConfig {
  const GroqApiConfig._();

  static const String endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Modèle Groq utilisé, surchargeable sans recompiler la logique via
  /// `--dart-define=GROQ_MODEL=...`.
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

  /// Clé fournie au lancement via `--dart-define=GROQ_API_KEY=...` : a
  /// toujours la priorité sur le fichier `.env` local lorsqu'elle est
  /// renseignée.
  static const String _dartDefineApiKey = String.fromEnvironment('GROQ_API_KEY');

  /// Clé lue depuis le fichier `.env` local par [loadLocalEnv], utilisée en
  /// repli lorsqu'aucune valeur n'a été fournie via `--dart-define`.
  static String _localEnvApiKey = '';

  /// Clé API Groq effective : priorité à `--dart-define=GROQ_API_KEY=...`,
  /// puis au fichier `.env` local (non suivi par Git — voir
  /// [loadLocalEnv]), sinon vide. Clé gratuite disponible sur
  /// https://console.groq.com/keys.
  ///
  /// ATTENTION SÉCURITÉ : cette intégration appelle l'API Groq directement
  /// depuis le client. La clé est donc embarquée dans le binaire et
  /// transite dans chaque requête réseau — elle est extractible, en
  /// particulier sur le Web où elle est visible dans les requêtes du
  /// navigateur. Cette approche convient au développement et à la
  /// démonstration ; avant toute mise en production, faites transiter ces
  /// appels par un backend qui détient la clé côté serveur (seule la
  /// classe [GroqApiConfig] et le datasource HTTP auraient alors à
  /// changer, le reste de l'architecture restant identique).
  static String get apiKey => _dartDefineApiKey.isNotEmpty ? _dartDefineApiKey : _localEnvApiKey;

  static bool get hasApiKey => apiKey.isNotEmpty;

  /// Charge `GROQ_API_KEY` depuis le fichier `.env` local (format
  /// `CLE=valeur`, une entrée par ligne, lignes vides et commentaires `#`
  /// ignorés). À appeler une fois au démarrage, avant `runApp`.
  ///
  /// N'a aucun effet si `--dart-define=GROQ_API_KEY=...` a déjà été fourni,
  /// et échoue silencieusement si `.env` est absent (cas normal en dehors
  /// du poste du développeur qui l'a configuré : voir `.env.example`).
  static Future<void> loadLocalEnv() async {
    if (_dartDefineApiKey.isNotEmpty) return;

    try {
      final content = await rootBundle.loadString('.env');
      for (final rawLine in content.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;

        final separator = line.indexOf('=');
        if (separator == -1) continue;

        final key = line.substring(0, separator).trim();
        final value = line.substring(separator + 1).trim();
        if (key == 'GROQ_API_KEY' && value.isNotEmpty) {
          _localEnvApiKey = value;
        }
      }
    } catch (_) {
      // Pas de fichier .env local : l'application démarre normalement,
      // hasApiKey restera false tant qu'aucune clé n'est configurée.
    }
  }
}
