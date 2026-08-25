import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/core/ai/groq_api_datasource.dart';
import 'package:jurisia_app/features/litigation/data/repositories/litigation_repository_impl.dart';
import 'package:jurisia_app/features/litigation/domain/entities/litigation_response_chunk.dart';
import 'package:jurisia_app/models/chat/conversation_model.dart';
import 'package:jurisia_app/models/chat/message_model.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

class _FakeDataSource implements LlmDataSource {
  _FakeDataSource(this.chunks);

  final List<String> chunks;
  bool disposed = false;

  @override
  Stream<String> streamCompletion({
    required String system,
    required List<Map<String, String>> messages,
    int maxTokens = 1536,
  }) async* {
    for (final chunk in chunks) {
      yield chunk;
    }
  }

  @override
  void dispose() => disposed = true;
}

void main() {
  group('LitigationRepositoryImpl', () {
    test('strips a grid marker fragmented across several stream chunks', () async {
      const gridJson = '{"domaine":"travail","complexite":"moyenne","grid":'
          '{"faits":"Licenciement sans preavis.",'
          '"qualificationJuridique":"Rupture abusive potentielle.",'
          '"droitsEtObligations":"",'
          '"textesApplicables":[],'
          '"jurisprudenceApplicable":[],'
          '"elementsDePreuve":[],'
          '"forces":[],'
          '"faiblesses":[],'
          '"chancesDeSucces":65,'
          '"planAction":["Reunir le contrat de travail","Envoyer une mise en demeure"],'
          '"professionnelRecommande":"avocat",'
          '"justificationRecommandation":"Un contentieux prudhommal est probable.",'
          '"isComplete":true}}';

      final chunks = [
        'Je comprends votre situation, ',
        'cela ressemble à une rupture qui pourrait être contestée. ',
        '<<<JURI', // le marqueur est volontairement coupé en deux fragments
        'SIA_GRID_JSON>>>\n$gridJson\n<<<END_JURISIA_GRID_JSON>>>',
      ];

      final fakeDataSource = _FakeDataSource(chunks);
      final repository = LitigationRepositoryImpl(dataSource: fakeDataSource);

      final userMessage = ChatMessage(
        id: 'u1',
        conversationId: 'c1',
        sender: MessageSender.user,
        content: "J'ai été licencié sans préavis.",
        timestamp: DateTime(2026, 1, 1),
      );

      final events = await repository
          .sendMessage(messages: [userMessage], currentGrid: const LegalAnalysisGrid())
          .toList();

      final textDeltas = events.whereType<LitigationTextDeltaChunk>().map((e) => e.delta).join();

      expect(
        textDeltas,
        'Je comprends votre situation, cela ressemble à une rupture qui pourrait être contestée. ',
      );
      expect(textDeltas.contains('GRID_JSON'), isFalse);
      expect(textDeltas.contains('<<<'), isFalse);

      final done = events.whereType<LitigationDoneChunk>().single;
      expect(done.assistantMessage.content, textDeltas.trim());
      expect(done.assistantMessage.sender, MessageSender.assistant);
      expect(done.updatedGrid.chancesDeSucces, 65);
      expect(done.updatedGrid.planAction, [
        'Reunir le contrat de travail',
        'Envoyer une mise en demeure',
      ]);
      expect(done.updatedGrid.professionnelRecommande, RecommendedProfessional.avocat);
      expect(done.assistantMessage.suggestedProfessional, 'Avocat');
      expect(done.domain, LegalDomain.travail);
      expect(done.complexity, ComplexityLevel.moyenne);

      repository.dispose();
      expect(fakeDataSource.disposed, isTrue);
    });

    test('throws when there is no user message to send', () async {
      final repository = LitigationRepositoryImpl(dataSource: _FakeDataSource(const []));

      await expectLater(
        repository.sendMessage(messages: const [], currentGrid: const LegalAnalysisGrid()).toList(),
        throwsA(isA<StateError>()),
      );
    });

    test('keeps the current grid when the hidden block is malformed', () async {
      final chunks = [
        'Merci pour ces précisions, pouvez-vous préciser la date des faits ? ',
        '<<<JURISIA_GRID_JSON>>>\nceci n\'est pas du JSON valide\n<<<END_JURISIA_GRID_JSON>>>',
      ];
      final repository = LitigationRepositoryImpl(dataSource: _FakeDataSource(chunks));

      const previousGrid = LegalAnalysisGrid(faits: 'Un litige locatif.');

      final userMessage = ChatMessage(
        id: 'u2',
        conversationId: 'c2',
        sender: MessageSender.user,
        content: 'Le 12 mars.',
        timestamp: DateTime(2026, 1, 1),
      );

      final events = await repository
          .sendMessage(messages: [userMessage], currentGrid: previousGrid)
          .toList();

      final done = events.whereType<LitigationDoneChunk>().single;
      expect(done.updatedGrid, previousGrid);
      expect(done.assistantMessage.content, contains('précisions'));
    });
  });
}
