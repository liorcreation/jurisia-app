import 'dart:convert';

import 'package:http/http.dart' as http;

import 'groq_api_config.dart';
import 'llm_api_exception.dart';

/// Frontière data vers un fournisseur de complétion de texte en streaming,
/// partagée par toutes les fonctionnalités IA de l'application. Permet de
/// substituer, plus tard, un backend propriétaire — ou un autre fournisseur
/// de modèle — à l'appel direct de l'API Groq sans toucher au reste de
/// l'architecture.
abstract class LlmDataSource {
  /// Diffuse la réponse du modèle fragment de texte par fragment de texte,
  /// à partir d'un system prompt et d'un historique de messages au format
  /// `{'role': 'user'|'assistant', 'content': '...'}`.
  Stream<String> streamCompletion({
    required String system,
    required List<Map<String, String>> messages,
    int maxTokens = GroqApiConfig.defaultMaxTokens,
  });

  /// Libère les ressources réseau (connexion HTTP persistante).
  void dispose();
}

/// Implémentation appelant le relais JurisIA (voir `server/groq-proxy/`),
/// lui-même compatible OpenAI (`POST /v1/chat/completions`, `stream: true`)
/// et transformant le flux SSE brut en une simple séquence de fragments de
/// texte. Le relais détient la clé Groq côté serveur — ce datasource n'en
/// manipule aucune.
class GroqDataSource implements LlmDataSource {
  GroqDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Stream<String> streamCompletion({
    required String system,
    required List<Map<String, String>> messages,
    int maxTokens = GroqApiConfig.defaultMaxTokens,
  }) async* {
    if (!GroqApiConfig.hasEndpoint) {
      throw const LlmApiException(
        "Aucun relais IA n'est configuré. Déployez server/groq-proxy/ (voir son "
        'README) puis relancez avec --dart-define=GROQ_PROXY_URL=... pour '
        'activer l\'assistant.',
      );
    }

    final request = http.Request('POST', Uri.parse(GroqApiConfig.endpoint))
      ..headers.addAll({'content-type': 'application/json'})
      ..body = jsonEncode({
        'model': GroqApiConfig.model,
        'messages': [
          {'role': 'system', 'content': system},
          ...messages,
        ],
        'max_tokens': maxTokens,
        'stream': true,
      });

    http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (error) {
      throw LlmApiException(
        "Impossible de contacter le service JurisIA. Vérifiez votre connexion internet. "
        '($error)',
      );
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      // ignore: avoid_print
      print('Groq API error — statusCode: ${response.statusCode}, body: $body');
      throw LlmApiException(
        _extractErrorMessage(body) ?? 'Le service a répondu avec une erreur (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final lines = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;
      if (payload == '[DONE]') return;

      Map<String, dynamic> event;
      try {
        event = jsonDecode(payload) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }

      final error = event['error'] as Map<String, dynamic>?;
      if (error != null) {
        throw LlmApiException(error['message'] as String? ?? "Erreur inconnue de l'API Groq.");
      }

      final choices = event['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) continue;

      final delta = (choices.first as Map<String, dynamic>)['delta'] as Map<String, dynamic>?;
      final text = delta?['content'] as String?;
      if (text != null && text.isNotEmpty) yield text;
    }
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final error = decoded['error'] as Map<String, dynamic>?;
      return error?['message'] as String?;
    } on FormatException {
      return null;
    }
  }

  @override
  void dispose() => _client.close();
}
