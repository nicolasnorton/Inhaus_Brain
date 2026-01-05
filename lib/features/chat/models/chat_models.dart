import '../../campaigns/models/campaign.dart';

enum MessageSender {
  user,
  researchAgent,
  creativeAgent,
  humanAgent,
  system
}

enum MessageType {
  text,
  attachment,
  toolUsage,
  approvalWidget
}

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final MessageType type;
  final DateTime createdAt;
  final List<Attachment> attachments;
  final Map<String, dynamic>? metadata; // For tool usage or widget data

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    this.type = MessageType.text,
    required this.createdAt,
    this.attachments = const [],
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      sender: MessageSender.values.firstWhere((e) => e.name == json['sender']),
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => Attachment.fromJson(a as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'sender': sender.name,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'metadata': metadata,
  };
}

class ChatSession {
  final String id;
  final String campaignId;
  final List<ChatMessage> messages;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.campaignId,
    this.messages = const [],
    required this.updatedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      campaignId: json['campaignId'] as String,
      messages: (json['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'messages': messages.map((m) => m.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  ChatSession copyWith({
    List<ChatMessage>? messages,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id,
      campaignId: campaignId,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
