import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/core/ai/groq_api_datasource.dart';
import 'package:jurisia_app/features/litigation/data/datasources/litigation_system_prompt.dart';
import 'package:jurisia_app/features/litigation/data/repositories/litigation_repository_impl.dart';
import 'package:jurisia_app/features/litigation/domain/repositories/litigation_conversation_store.dart';
import 'package:jurisia_app/features/litigation/domain/usecases/analyze_litigation_usecase.dart';
import 'package:jurisia_app/features/litigation/domain/usecases/generate_conversation_title_usecase.dart';
import 'package:jurisia_app/features/litigation/presentation/controllers/litigation_chat_controller.dart';
import 'package:jurisia_app/models/chat/conversation_model.dart';
import 'package:jurisia_app/models/chat/message_model.dart';

/// Distingue l'appel de chat (system = grille d'analyse) de l'appel de
/// génération de titre (system = [LitigationSystemPrompt.titleGeneration])
/// pour leur servir des réponses différentes, comme le ferait le vrai
/// relais Groq selon le prompt reçu.
class _FakeDataSource implements LlmDataSource {
  _FakeDataSource({
    required this.chatChunks,
    this.titleChunks = const ['Titre généré'],
    this.throwOnTitleRequest = false,
  });

  final List<String> chatChunks;
  final List<String> titleChunks;
  final bool throwOnTitleRequest;

  @override
  Stream<String> streamCompletion({
    required String system,
    required List<Map<String, String>> messages,
    int maxTokens = 1536,
  }) async* {
    final isTitleRequest = system == LitigationSystemPrompt.titleGeneration;
    if (isTitleRequest && throwOnTitleRequest) {
      throw Exception('panne simulée du service de titres');
    }
    for (final chunk in isTitleRequest ? titleChunks : chatChunks) {
      yield chunk;
    }
  }

  @override
  void dispose() {}
}

/// Store en mémoire, sur le modèle de [SupabaseLitigationConversationStore]
/// mais sans réseau — suffisant pour tester le contrôleur contre la vraie
/// interface [LitigationConversationStore].
class _FakeConversationStore implements LitigationConversationStore {
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messages = {};

  List<Conversation> _sorted() {
    final values = _conversations.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  @override
  Future<List<Conversation>> listConversations() async {
    return _sorted().map((c) => c.copyWith(messages: const [])).toList();
  }

  @override
  Future<Conversation?> loadConversation(String id) async {
    final conversation = _conversations[id];
    if (conversation == null) return null;
    return conversation.copyWith(messages: List.of(_messages[id] ?? const []));
  }

  @override
  Future<void> deleteConversation(String id) async {
    _conversations.remove(id);
    _messages.remove(id);
  }

  @override
  Future<void> upsertConversation(Conversation conversation) async {
    _conversations[conversation.id] = conversation.copyWith(messages: const []);
  }

  @override
  Future<void> appendMessage(ChatMessage message) async {
    _messages.putIfAbsent(message.conversationId, () => []).add(message);
  }
}

LitigationChatController _buildController(
  _FakeConversationStore store, {
  List<String>? chatChunks,
  List<String>? titleChunks,
  bool throwOnTitleRequest = false,
}) {
  final dataSource = _FakeDataSource(
    chatChunks: chatChunks ?? const ["Merci, je regarde votre situation."],
    titleChunks: titleChunks ?? const ['Titre généré'],
    throwOnTitleRequest: throwOnTitleRequest,
  );
  final repository = LitigationRepositoryImpl(dataSource: dataSource);
  return LitigationChatController(
    useCase: AnalyzeLitigationUseCase(repository: repository),
    generateTitleUseCase: GenerateConversationTitleUseCase(repository: repository),
    conversationStore: store,
  );
}

/// Laisse les `Future`s en arrière-plan du contrôleur (refreshHistory,
/// génération de titre non attendue depuis `_send`) se résoudre avant
/// d'inspecter son état.
Future<void> _settle() => Future.delayed(Duration.zero);

void main() {
  group('LitigationChatController — historique', () {
    test('affiche un titre tronqué dès le premier message, avant la réponse IA', () async {
      final store = _FakeConversationStore();
      final controller = _buildController(store);
      await _settle();

      await controller.sendMessage(
        "J'ai été licencié sans préavis après quinze ans d'ancienneté, que puis-je faire ?",
      );

      // Le titre généré par l'IA n'a pas forcément eu le temps de revenir
      // dès la fin de l'échange : soit le repli tronqué est encore là, soit
      // le titre généré (voir test suivant) a déjà pris le relais — dans
      // tous les cas, ce n'est jamais resté "Nouvelle consultation".
      expect(controller.conversation.title, isNot('Nouvelle consultation'));
    });

    test('le titre généré par l\'IA remplace le titre tronqué une fois reçu', () async {
      final store = _FakeConversationStore();
      final controller = _buildController(store, titleChunks: const ['Licenciement sans préavis']);
      await _settle();

      await controller.sendMessage("J'ai été licencié sans préavis, que puis-je faire ?");
      await _settle();

      expect(controller.conversation.title, 'Licenciement sans préavis');
      expect(controller.history.first.title, 'Licenciement sans préavis');
    });

    test('conserve le titre tronqué si la génération IA échoue', () async {
      final store = _FakeConversationStore();
      final controller = _buildController(store, throwOnTitleRequest: true);
      await _settle();

      await controller.sendMessage("J'ai été licencié sans préavis, que puis-je faire ?");
      await _settle();

      expect(controller.conversation.title, startsWith("J'ai été licencié"));
    });

    test('ne change plus le titre après le premier message', () async {
      final store = _FakeConversationStore();
      final controller = _buildController(store);
      await _settle();

      await controller.sendMessage('Première question sur mon bail.');
      await _settle();
      final titleAfterFirst = controller.conversation.title;

      await controller.sendMessage('Une deuxième question, sans rapport.');
      await _settle();

      expect(controller.conversation.title, titleAfterFirst);
    });

    test("apparaît dans l'historique après un échange, la plus récente en tête", () async {
      final store = _FakeConversationStore();
      final controller = _buildController(store);
      await _settle();

      await controller.sendMessage('Question sur un litige de voisinage.');
      await _settle();

      expect(controller.history, hasLength(1));
      expect(controller.history.first.id, controller.conversation.id);
    });

    test('openConversation bascule vers une consultation précédente avec ses messages', () async {
      final store = _FakeConversationStore();
      final controller = _buildController(store);
      await _settle();

      await controller.sendMessage('Premier dossier : conflit de voisinage.');
      await _settle();
      final firstConversationId = controller.conversation.id;

      controller.startNewConsultation();
      await controller.sendMessage('Second dossier : rupture de contrat.');
      await _settle();
      final secondConversationId = controller.conversation.id;

      expect(controller.conversation.id, isNot(firstConversationId));

      await controller.openConversation(firstConversationId);

      expect(controller.conversation.id, firstConversationId);
      expect(
        controller.conversation.messages.any((m) => m.content.contains('conflit de voisinage')),
        isTrue,
      );
      expect(controller.conversation.id, isNot(secondConversationId));
    });

    test(
      'deleteConversation retire de l\'historique et redémarre si c\'était l\'active',
      () async {
        final store = _FakeConversationStore();
        final controller = _buildController(store);
        await _settle();

        await controller.sendMessage('Dossier à supprimer.');
        await _settle();
        final deletedId = controller.conversation.id;

        await controller.deleteConversation(deletedId);

        expect(controller.history.any((c) => c.id == deletedId), isFalse);
        expect(controller.conversation.id, isNot(deletedId));
        expect(controller.conversation.title, 'Nouvelle consultation');
      },
    );

    test('deleteConversation sur une entrée inactive ne touche pas la conversation active', () async {
      final store = _FakeConversationStore();
      final controller = _buildController(store);
      await _settle();

      await controller.sendMessage('Premier dossier.');
      await _settle();
      final firstId = controller.conversation.id;

      controller.startNewConsultation();
      await controller.sendMessage('Deuxième dossier, actif.');
      await _settle();
      final activeId = controller.conversation.id;

      await controller.deleteConversation(firstId);

      expect(controller.conversation.id, activeId);
      expect(controller.history.any((c) => c.id == firstId), isFalse);
      expect(controller.history.any((c) => c.id == activeId), isTrue);
    });

    test('renameConversation met à jour le titre de la consultation active', () async {
      final store = _FakeConversationStore();
      final controller = _buildController(store);
      await _settle();

      await controller.sendMessage('Dossier à renommer.');
      await _settle();

      await controller.renameConversation(controller.conversation.id, 'Nouveau titre choisi');

      expect(controller.conversation.title, 'Nouveau titre choisi');
      expect(controller.history.first.title, 'Nouveau titre choisi');
    });

    test(
      'renameConversation met à jour une entrée inactive sans toucher à la consultation active',
      () async {
        final store = _FakeConversationStore();
        final controller = _buildController(store);
        await _settle();

        await controller.sendMessage('Premier dossier.');
        await _settle();
        final firstId = controller.conversation.id;

        controller.startNewConsultation();
        await controller.sendMessage('Deuxième dossier, actif.');
        await _settle();
        final activeTitleBefore = controller.conversation.title;

        await controller.renameConversation(firstId, 'Titre renommé manuellement');

        expect(controller.conversation.title, activeTitleBefore);
        expect(
          controller.history.firstWhere((c) => c.id == firstId).title,
          'Titre renommé manuellement',
        );
      },
    );
  });
}
