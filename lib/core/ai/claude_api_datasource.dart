import 'dart:convert';

import 'package:http/http.dart' as http;

import 'claude_api_config.dart';
import 'claude_api_exception.dart';

/// Frontière data vers un fournisseur de complétion de texte en streaming,
/// partagée par toutes les fonctionnalités IA de l'application. Permet de
/// substituer, plus tard, un backend propriétaire à l'appel direct de
/// l'API Anthropic sans toucher au reste de l'architecture.
abstract class ClaudeApiDataSource {
  /// Diffuse la réponse du modèle fragment de texte par fragment de texte,
  /// à partir d'un system prompt et d'un historique de messages au format
  /// `{'role': 'user'|'assistant', 'content': '...'}`.
  Stream<String> streamCompletion({
    required String system,
    required List<Map<String, String>> messages,
    int maxTokens = ClaudeApiConfig.defaultMaxTokens,
  });

  /// Libère les ressources réseau (connexion HTTP persistante).
  void dispose();
}

/// Implémentation appelant directement l'API Messages d'Anthropic
/// (`POST /v1/messages`, `stream: true`) et transformant le flux SSE brut
/// en une simple séquence de fragments de texte.
class AnthropicClaudeDataSource implements ClaudeApiDataSource {
  AnthropicClaudeDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Stream<String> streamCompletion({
    required String system,
    required List<Map<String, String>> messages,
    int maxTokens = ClaudeApiConfig.defaultMaxTokens,
  }) async* {
    if (!ClaudeApiConfig.hasApiKey) {
      throw const ClaudeApiException(
        "Aucune clé API Anthropic n'est configurée. Relancez l'application avec "
        "--dart-define=ANTHROPIC_API_KEY=votre_cle pour activer l'assistant.",
      );
    }

    final request = http.Request('POST', Uri.parse(ClaudeApiConfig.baseUrl))
      ..headers.addAll({
        'content-type': 'application/json',
        'x-api-key': ClaudeApiConfig.apiKey,
        'anthropic-version': ClaudeApiConfig.anthropicVersion,
        'anthropic-dangerous-direct-browser-access': 'true',
      })
      ..body = jsonEncode({
        'model': ClaudeApiConfig.model,
        'max_tokens': maxTokens,
        'system': system,
        'messages': messages,
        'stream': true,
      });

    http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (error) {
      throw ClaudeApiException(
        "Impossible de contacter le service JurisIA. Vérifiez votre connexion internet. "
        '($error)',
      );
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw ClaudeApiException(
        _extractErrorMessage(body) ?? 'Le service a répondu avec une erreur (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final lines = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;

      Map<String, dynamic> event;
      try {
        event = jsonDecode(payload) as Map<String, dynamic>;
      } on FormatException {
        continue;
      }

      final type = event['type'] as String?;

      if (type == 'content_block_delta') {
        final delta = event['delta'] as Map<String, dynamic>?;
        if (delta != null && delta['type'] == 'text_delta') {
          final text = delta['text'] as String?;
          if (text != null && text.isNotEmpty) yield text;
        }
      } else if (type == 'error') {
        final error = event['error'] as Map<String, dynamic>?;
        throw ClaudeApiException(error?['message'] as String? ?? "Erreur inconnue de l'API Claude.");
      } else if (type == 'message_stop') {
        return;
      }
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
