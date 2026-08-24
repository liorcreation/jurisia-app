import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../models/chat/conversation_model.dart';
import '../../../../models/chat/message_model.dart';
import '../../domain/entities/litigation_response_chunk.dart';
import '../../domain/usecases/analyze_litigation_usecase.dart';

/// État d'envoi courant de la conversation.
enum LitigationSendStatus { idle, sending, error }

/// Contrôleur d'état de l'écran "Litiges et consultations" : conserve la
/// conversation en cours, pilote l'appel au use case d'analyse et expose
/// le texte en cours de streaming ainsi que les erreurs éventuelles à la
/// vue.
class LitigationChatController extends ChangeNotifier {
  LitigationChatController({required this.useCase, Uuid? uuid}) : _uuid = uuid ?? const Uuid() {
    _conversation = _createConversation();
  }

  final AnalyzeLitigationUseCase useCase;
  final Uuid _uuid;

  late Conversation _conversation;
  Conversation get conversation => _conversation;

  LitigationSendStatus _status = LitigationSendStatus.idle;
  LitigationSendStatus get status => _status;
  bool get isSending => _status == LitigationSendStatus.sending;

  String _streamingText = '';
  String get streamingText => _streamingText;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _pendingRetryMessage;
  bool get canRetry => _pendingRetryMessage != null;

  Conversation _createConversation() {
    final id = _uuid.v4();
    final now = DateTime.now();
    return Conversation(
      id: id,
      title: 'Nouvelle consultation',
      module: ConversationModule.litigeEtConsultation,
      createdAt: now,
      updatedAt: now,
      messages: [_welcomeMessage(id)],
    );
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
            _conversation = _conversation.copyWith(
              messages: [..._conversation.messages, message],
              updatedAt: DateTime.now(),
            );
            _pendingRetryMessage = text;
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
