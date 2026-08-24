import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../../core/ai/claude_api_datasource.dart';
import '../../../../core/ai/hidden_block_stream_splitter.dart';
import '../../../../models/chat/conversation_model.dart';
import '../../../../models/chat/message_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../domain/entities/litigation_response_chunk.dart';
import '../../domain/repositories/litigation_repository.dart';
import '../datasources/litigation_system_prompt.dart';

/// Implémentation du [LitigationRepository] s'appuyant sur un
/// [ClaudeApiDataSource]. Sépare, dans le flux brut renvoyé par le modèle,
/// le texte visible destiné à l'utilisateur du bloc caché contenant la mise
/// à jour de la grille d'analyse interne, en gérant le cas où le marqueur
/// de séparation est lui-même fragmenté entre deux paquets du flux.
class LitigationRepositoryImpl implements LitigationRepository {
  LitigationRepositoryImpl({required this.dataSource, Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final ClaudeApiDataSource dataSource;
  final Uuid _uuid;

  static const _markerStart = LitigationSystemPrompt.gridMarkerStart;
  static const _markerEnd = LitigationSystemPrompt.gridMarkerEnd;

  @override
  Stream<LitigationResponseChunk> sendMessage({
    required List<ChatMessage> messages,
    required LegalAnalysisGrid currentGrid,
  }) async* {
    final apiMessages = _buildApiMessages(messages);
    if (apiMessages.isEmpty) {
      throw StateError('Aucun message utilisateur à transmettre.');
    }

    final conversationId = messages.last.conversationId;
    final system = LitigationSystemPrompt.withContext(currentGrid);

    final splitter = HiddenBlockStreamSplitter(markerStart: _markerStart);

    await for (final delta in dataSource.streamCompletion(system: system, messages: apiMessages)) {
      final visiblePart = splitter.feed(delta);
      if (visiblePart.isNotEmpty) yield LitigationTextDeltaChunk(visiblePart);
    }
    final tail = splitter.flush();
    if (tail.isNotEmpty) yield LitigationTextDeltaChunk(tail);

    final parsed = _parseHiddenBlock(splitter.hidden.toString());
    final updatedGrid = parsed?.grid ?? currentGrid;

    final assistantMessage = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      sender: MessageSender.assistant,
      content: splitter.visibleAccumulated.toString().trim(),
      timestamp: DateTime.now(),
      suggestedProfessional: updatedGrid.professionnelRecommande == RecommendedProfessional.aucun
          ? null
          : updatedGrid.professionnelRecommande.label,
    );

    yield LitigationDoneChunk(
      assistantMessage: assistantMessage,
      updatedGrid: updatedGrid,
      domain: parsed?.domain,
      complexity: parsed?.complexity,
    );
  }

  List<Map<String, String>> _buildApiMessages(List<ChatMessage> messages) {
    final startIndex = messages.indexWhere((m) => m.sender == MessageSender.user);
    if (startIndex == -1) return const [];

    return messages
        .sublist(startIndex)
        .where((m) => m.sender == MessageSender.user || m.sender == MessageSender.assistant)
        .map(
          (m) => {
            'role': m.sender == MessageSender.user ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();
  }

  _ParsedHiddenBlock? _parseHiddenBlock(String raw) {
    if (raw.isEmpty) return null;

    var content = raw.trim();
    if (content.startsWith(_markerStart)) {
      content = content.substring(_markerStart.length);
    }
    final endIndex = content.indexOf(_markerEnd);
    if (endIndex != -1) {
      content = content.substring(0, endIndex);
    }
    content = content.trim();
    if (content.isEmpty) return null;

    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      final gridJson = json['grid'] as Map<String, dynamic>?;
      final grid = gridJson != null ? LegalAnalysisGrid.fromJson(gridJson) : null;
      final domainName = json['domaine'] as String?;
      final complexityName = json['complexite'] as String?;

      return _ParsedHiddenBlock(
        grid: grid,
        domain: domainName != null ? LegalDomain.fromName(domainName) : null,
        complexity: complexityName != null
            ? ComplexityLevel.values.firstWhere(
                (c) => c.name == complexityName,
                orElse: () => ComplexityLevel.simple,
              )
            : null,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  void dispose() => dataSource.dispose();
}

class _ParsedHiddenBlock {
  const _ParsedHiddenBlock({this.grid, this.domain, this.complexity});

  final LegalAnalysisGrid? grid;
  final LegalDomain? domain;
  final ComplexityLevel? complexity;
}
