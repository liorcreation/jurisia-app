import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jurisia_app/core/ai/groq_api_datasource.dart';

/// Réponse SSE minimale : un fragment de contenu puis la fin de flux.
http.StreamedResponse _sse(String body) {
  return http.StreamedResponse(Stream.value(utf8.encode(body)), 200);
}

Future<List<String>> _collect(GroqDataSource dataSource) async {
  final chunks = <String>[];
  await for (final chunk in dataSource.streamCompletion(
    system: 'system',
    messages: const [
      {'role': 'user', 'content': 'bonjour'},
    ],
  )) {
    chunks.add(chunk);
  }
  return chunks;
}

void main() {
  const doneBody = 'data: [DONE]\n\n';
  const okBody =
      'data: {"choices":[{"delta":{"content":"ok"}}]}\n\ndata: [DONE]\n\n';

  test('joint le jeton en Authorization: Bearer quand un fournisseur en donne un', () async {
    String? seenAuth = 'ABSENT';
    final client = MockClient.streaming((request, _) async {
      seenAuth = request.headers['authorization'];
      return _sse(okBody);
    });

    final dataSource = GroqDataSource(client: client, accessToken: () async => 'tok-123');
    final chunks = await _collect(dataSource);

    expect(chunks, ['ok']);
    expect(seenAuth, 'Bearer tok-123');
  });

  test("n'ajoute aucun en-tête Authorization sans fournisseur de jeton", () async {
    String? seenAuth = 'ABSENT';
    final client = MockClient.streaming((request, _) async {
      seenAuth = request.headers['authorization'];
      return _sse(doneBody);
    });

    await _collect(GroqDataSource(client: client));

    expect(seenAuth, isNull);
  });

  test("n'ajoute aucun en-tête Authorization si le fournisseur renvoie null", () async {
    String? seenAuth = 'ABSENT';
    final client = MockClient.streaming((request, _) async {
      seenAuth = request.headers['authorization'];
      return _sse(doneBody);
    });

    await _collect(GroqDataSource(client: client, accessToken: () async => null));

    expect(seenAuth, isNull);
  });
}
