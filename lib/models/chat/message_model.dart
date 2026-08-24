import 'package:equatable/equatable.dart';

/// Émetteur d'un message dans une conversation.
enum MessageSender { user, assistant, system }

/// Statut d'envoi/traitement d'un message.
enum MessageStatus { sending, sent, analyzing, error }

/// Un message unique échangé au sein d'une [Conversation].
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.suggestedProfessional,
    this.attachmentUrls = const [],
  });

  final String id;
  final String conversationId;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;

  /// Renseigné uniquement lorsque l'IA oriente l'utilisateur vers un
  /// professionnel (avocat, notaire, huissier, médiateur, expert) à la fin
  /// de son analyse.
  final String? suggestedProfessional;

  final List<String> attachmentUrls;

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    MessageSender? sender,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    String? suggestedProfessional,
    List<String>? attachmentUrls,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      suggestedProfessional: suggestedProfessional ?? this.suggestedProfessional,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'sender': sender.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'suggestedProfessional': suggestedProfessional,
      'attachmentUrls': attachmentUrls,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      sender: MessageSender.values.firstWhere(
        (value) => value.name == json['sender'],
        orElse: () => MessageSender.user,
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      suggestedProfessional: json['suggestedProfessional'] as String?,
      attachmentUrls: (json['attachmentUrls'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        sender,
        content,
        timestamp,
        status,
        suggestedProfessional,
        attachmentUrls,
      ];
}
