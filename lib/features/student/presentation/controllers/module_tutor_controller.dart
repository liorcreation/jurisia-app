import 'package:flutter/foundation.dart';

import '../../../../models/chat/message_model.dart';
import '../../../../models/student/course_module.dart';
import '../../domain/entities/module_tutor_chunk.dart';
import '../../domain/usecases/ask_module_tutor_usecase.dart';

enum ModuleTutorSendStatus { idle, sending, error }

/// Contrôleur d'état de l'assistant IA d'un module (onglet « Assistant
/// IA ») : historique de la conversation restreinte au module, texte en
/// cours de streaming, et gestion des erreurs.
class ModuleTutorController extends ChangeNotifier {
  ModuleTutorController({required this.module, required this.useCase});

  final CourseModule module;
  final AskModuleTutorUseCase useCase;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  ModuleTutorSendStatus _status = ModuleTutorSendStatus.idle;
  bool get isSending => _status == ModuleTutorSendStatus.sending;

  String _streamingText = '';
  String get streamingText => _streamingText;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _pendingRetryMessage;
  bool get canRetry => _pendingRetryMessage != null;

  Future<void> sendMessage(String text) async {
    if (isSending) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _send(trimmed);
  }

  Future<void> retry() async {
    final message = _pendingRetryMessage;
    if (message == null || isSending) return;

    if (_messages.isNotEmpty && _messages.last.sender == MessageSender.user) {
      _messages.removeLast();
    }
    _pendingRetryMessage = null;
    await _send(message);
  }

  void dismissError() {
    _errorMessage = null;
    _status = ModuleTutorSendStatus.idle;
    notifyListeners();
  }

  Future<void> _send(String text) async {
    _errorMessage = null;
    _status = ModuleTutorSendStatus.sending;
    _streamingText = '';
    notifyListeners();

    try {
      await for (final chunk in useCase.call(module: module, history: _messages, userMessage: text)) {
        switch (chunk) {
          case ModuleTutorUserMessageChunk(:final message):
            _messages.add(message);
            _pendingRetryMessage = text;
            notifyListeners();
          case ModuleTutorTextDeltaChunk(:final delta):
            _streamingText += delta;
            notifyListeners();
          case ModuleTutorDoneChunk(:final assistantMessage):
            _messages.add(assistantMessage);
            _streamingText = '';
            _status = ModuleTutorSendStatus.idle;
            _pendingRetryMessage = null;
            notifyListeners();
        }
      }
    } catch (error) {
      _status = ModuleTutorSendStatus.error;
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
