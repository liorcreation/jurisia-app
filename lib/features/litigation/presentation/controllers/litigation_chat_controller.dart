import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../models/chat/conversation_model.dart';
import '../../../../models/chat/message_model.dart';
import '../../domain/entities/litigation_response_chunk.dart';
import '../../domain/repositories/litigation_conversation_store.dart';
import '../../domain/usecases/analyze_litigation_usecase.dart';
import '../../domain/usecases/generate_conversation_title_usecase.dart';

/// État d'envoi courant de la conversation.
enum LitigationSendStatus { idle, sending, error }

/// Contrôleur d'état de l'écran "Litiges et consultations" : conserve la
/// conversation en cours, pilote l'appel au use case d'analyse et expose
/// le texte en cours de streaming ainsi que les erreurs éventuelles à la
/// vue. Comme ChatGPT/Claude/Gemini, démarre toujours sur une consultation
/// neuve — les précédentes restent accessibles via [history], jamais
/// rouvertes automatiquement. Si [conversationStore] est fourni, chaque
/// message est sauvegardé en arrière-plan, au mieux effort.
class LitigationChatController extends ChangeNotifier {
  LitigationChatController({
    required this.useCase,
    required this.generateTitleUseCase,
    this.conversationStore,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid() {
    _conversation = _createConversation();
    refreshHistory();
  }

  final AnalyzeLitigationUseCase useCase;
  final GenerateConversationTitleUseCase generateTitleUseCase;
  final LitigationConversationStore? conversationStore;
  final Uuid _uuid;

  late Conversation _conversation;
  Conversation get conversation => _conversation;

  List<Conversation> _history = const [];
  List<Conversation> get history => _history;

  bool _isSwitchingConversation = false;
  bool get isSwitchingConversation => _isSwitchingConversation;

  LitigationSendStatus _status = LitigationSendStatus.idle;
  LitigationSendStatus get status => _status;
  bool get isSending => _status == LitigationSendStatus.sending;

  String _streamingText = '';
  String get streamingText => _streamingText;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _pendingRetryMessage;
  bool get canRetry => _pendingRetryMessage != null;

  static const String _defaultTitle = 'Nouvelle consultation';
  static const int _autoTitleMaxLength = 48;

  Conversation _createConversation() {
    final id = _uuid.v4();
    final now = DateTime.now();
    return Conversation(
      id: id,
      title: _defaultTitle,
      module: ConversationModule.litigeEtConsultation,
      createdAt: now,
      updatedAt: now,
      messages: [_welcomeMessage(id)],
    );
  }

  /// Dérive un titre lisible depuis le premier message de l'utilisateur —
  /// remplace le "Nouvelle consultation" générique dès le premier échange,
  /// pour que l'historique reste identifiable au coup d'œil.
  String _deriveTitle(String message) {
    final singleLine = message.replaceAll('\n', ' ').trim();
    if (singleLine.length <= _autoTitleMaxLength) return singleLine;
    return '${singleLine.substring(0, _autoTitleMaxLength).trimRight()}…';
  }

  /// Met à jour l'entrée de [conversation] dans [_history] en mémoire (sans
  /// nouvel aller-retour Supabase) : retirée si déjà présente, réinsérée en
  /// tête — l'historique reste trié du plus récent au plus ancien sans
  /// dépendre d'un tri côté serveur à chaque message.
  void _upsertHistoryEntry(Conversation conversation) {
    final summary = conversation.copyWith(messages: const []);
    _history = [
      summary,
      for (final entry in _history)
        if (entry.id != conversation.id) entry,
    ];
  }

  /// Charge la liste des consultations de l'utilisateur pour le panneau
  /// d'historique. Sans effet si la persistance n'est pas configurée.
  Future<void> refreshHistory() async {
    final store = conversationStore;
    if (store == null) return;
    _history = await store.listConversations();
    notifyListeners();
  }

  /// Bascule vers une consultation précédente. Sans effet si c'est déjà la
  /// consultation active ou qu'un envoi est en cours.
  Future<void> openConversation(String id) async {
    if (id == _conversation.id || isSending) return;
    final store = conversationStore;
    if (store == null) return;

    _isSwitchingConversation = true;
    notifyListeners();

    final loaded = await store.loadConversation(id);
    if (loaded != null) {
      _conversation = loaded;
      _streamingText = '';
      _status = LitigationSendStatus.idle;
      _errorMessage = null;
      _pendingRetryMessage = null;
    }
    _isSwitchingConversation = false;
    notifyListeners();
  }

  /// Supprime définitivement une consultation. Si c'était la consultation
  /// active, en démarre une nouvelle pour ne pas rester sur une référence
  /// supprimée.
  Future<void> deleteConversation(String id) async {
    final store = conversationStore;
    if (store == null) return;

    await store.deleteConversation(id);
    _history = _history.where((entry) => entry.id != id).toList();

    if (_conversation.id == id) {
      startNewConsultation();
    } else {
      notifyListeners();
    }
  }

  /// Épingle / désépingle une consultation. Les consultations épinglées
  /// remontent en tête de l'historique (section « Épinglées »), comme sur
  /// ChatGPT. Persisté au mieux effort via [conversationStore].
  Future<void> togglePin(String id) async {
    Conversation? target;
    if (_conversation.id == id) {
      target = _conversation;
    } else {
      for (final entry in _history) {
        if (entry.id == id) {
          target = entry;
          break;
        }
      }
    }
    if (target == null) return;

    final updated = target.copyWith(isFavorite: !target.isFavorite);
    if (_conversation.id == id) _conversation = updated;
    conversationStore?.upsertConversation(updated);
    _upsertHistoryEntry(updated);
    notifyListeners();
  }

  /// Renomme une consultation, active ou non — même logique que
  /// [deleteConversation] pour retrouver la bonne entrée.
  Future<void> renameConversation(String id, String newTitle) async {
    final title = newTitle.trim();
    if (title.isEmpty) return;

    if (_conversation.id == id) {
      _conversation = _conversation.copyWith(title: title);
      conversationStore?.upsertConversation(_conversation);
      _upsertHistoryEntry(_conversation);
      notifyListeners();
      return;
    }

    Conversation? existing;
    for (final entry in _history) {
      if (entry.id == id) {
        existing = entry;
        break;
      }
    }
    if (existing == null) return;

    final updated = existing.copyWith(title: title);
    conversationStore?.upsertConversation(updated);
    _upsertHistoryEntry(updated);
    notifyListeners();
  }

  /// Remplace le titre tronqué affiché immédiatement au premier message par
  /// un titre généré par l'IA, dès qu'il arrive — sans bloquer l'échange en
  /// cours. Si l'utilisateur a changé de conversation entretemps, met à
  /// jour l'entrée d'historique correspondante plutôt que la conversation
  /// active. Un échec de génération n'est jamais visible : le titre tronqué
  /// reste un repli tout à fait correct.
  Future<void> _refineTitleFromFirstMessage(String conversationId, String firstMessage) async {
    String smartTitle;
    try {
      smartTitle = await generateTitleUseCase(firstMessage);
    } catch (_) {
      return;
    }
    if (smartTitle.trim().isEmpty) return;

    await renameConversation(conversationId, smartTitle);
  }

  ChatMessage _welcomeMessage(String conversationId) {
    return ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      sender: MessageSender.assistant,
      content:
          "Bonjour, je suis votre assistant juridique JurisIA. Racontez-moi ce qui vous "
          "amène, avec vos propres mots : ce qui s'est passé, les personnes concernées "
          "et ce que vous cherchez à obtenir. Je vous poserai ensuite quelques questions "
          "pour bien cerner votre situation.",
      timestamp: DateTime.now(),
    );
  }

  /// Réinitialise la conversation pour démarrer une nouvelle consultation.
  void startNewConsultation() {
    _conversation = _createConversation();
    _streamingText = '';
    _status = LitigationSendStatus.idle;
    _errorMessage = null;
    _pendingRetryMessage = null;
    notifyListeners();
  }

  /// Efface l'erreur affichée sans relancer d'envoi.
  void dismissError() {
    _errorMessage = null;
    _status = LitigationSendStatus.idle;
    notifyListeners();
  }

  /// Relance le dernier message utilisateur après un échec réseau/API.
  Future<void> retry() async {
    final message = _pendingRetryMessage;
    if (message == null || isSending) return;

    if (_conversation.messages.isNotEmpty &&
        _conversation.messages.last.sender == MessageSender.user) {
      _conversation = _conversation.copyWith(
        messages: _conversation.messages.sublist(0, _conversation.messages.length - 1),
      );
    }
    _pendingRetryMessage = null;
    await _send(message);
  }

  Future<void> sendMessage(String text) async {
    if (isSending) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _send(trimmed);
  }

  Future<void> _send(String text) async {
    _errorMessage = null;
    _status = LitigationSendStatus.sending;
    _streamingText = '';
    notifyListeners();

    try {
      await for (final chunk in useCase.call(conversation: _conversation, userMessage: text)) {
        switch (chunk) {
          case LitigationUserMessageChunk(:final message):
            final isFirstUserMessage = _conversation.title == _defaultTitle;
            _conversation = _conversation.copyWith(
              title: isFirstUserMessage ? _deriveTitle(text) : null,
              messages: [..._conversation.messages, message],
              updatedAt: DateTime.now(),
            );
            _pendingRetryMessage = text;
            conversationStore?.upsertConversation(_conversation);
            conversationStore?.appendMessage(message);
            _upsertHistoryEntry(_conversation);
            if (isFirstUserMessage) {
              // Le titre tronqué ci-dessus s'affiche tout de suite ; celui-ci
              // le remplace dès qu'il arrive, sans bloquer l'échange en cours.
              // ignore: unawaited_futures
              _refineTitleFromFirstMessage(_conversation.id, text);
            }
            notifyListeners();
          case LitigationTextDeltaChunk(:final delta):
            _streamingText += delta;
            notifyListeners();
          case LitigationDoneChunk(:final assistantMessage, :final updatedGrid, :final domain, :final complexity):
            _conversation = _conversation.copyWith(
              messages: [..._conversation.messages, assistantMessage],
              analysisGrid: updatedGrid,
              domain: domain,
              complexity: complexity,
              updatedAt: DateTime.now(),
            );
            _streamingText = '';
            _status = LitigationSendStatus.idle;
            _pendingRetryMessage = null;
            conversationStore?.upsertConversation(_conversation);
            conversationStore?.appendMessage(assistantMessage);
            _upsertHistoryEntry(_conversation);
            notifyListeners();
        }
      }
    } catch (error) {
      _status = LitigationSendStatus.error;
      _streamingText = '';
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    useCase.dispose();
    super.dispose();
  }
}
