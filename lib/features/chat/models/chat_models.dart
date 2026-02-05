import '../../campaigns/models/campaign.dart';

enum MessageSender {
  user,
  researchAgent,
  creativeAgent,
  orchestratorAgent, // New Phase 5
  copywriterAgent,   // New Phase 5
  developerAgent,    // New Phase 5
  clientOnboardingAgent, // Phase 15
  extractorAgent,    // Phase 15
  parserAgent,       // Phase 15
  summarizerAgent,   // Phase 15
  securityAgent,     // Phase 15
  dataEngineerAgent, // Phase 15
  visionAgent,       // Phase 18
  routerAgent,       // Phase 23
  knowledgeLibrarianAgent,
  performanceAnalystAgent,
  dataScientistAgent,
  digitalStrategyAgent,
  dashboardAgent,
  
  // Phase 31: Agency Model Alignment
  trendScoutAgent,
  accountDirectorAgent,
  strategistAgent,
  editorialManagerAgent,
  storytellingAgent, // New Phase 89: Narrative
  mediaBuyerAgent,
  managementAgent, // Phase 4: Client Management
  reportsAgent,    // Phase 6: Reports Module

  // Upgraded Agency Roles
  designAgent,
  videoProductionAgent,
  customerServiceAgent,
  crmAgent,
  cSuiteAdvisorAgent,
  seoAgent,               // New SEO Agent
  aeoAgent,               // New AEO Agent
  proposalSpecialistAgent,// New Phase 10: Proposal Specialist

  humanAgent,
  system
}

enum MessageType {
  text,
  attachment,
  toolUsage,
  approvalWidget
}

enum ArtifactType {
  markdown,
  code,
  image,
  file,
  plan // For task.md or implementation plans
}

class Artifact {
  final String id;
  final String title;
  final ArtifactType type;
  final String content;       // Text content or file path
  final int version;
  final DateTime updatedAt;

  Artifact({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    this.version = 1,
    required this.updatedAt,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Untitled',
      type: ArtifactType.values.firstWhere(
        (e) => e.name == json['type'], 
        orElse: () => ArtifactType.markdown
      ),
      content: json['content']?.toString() ?? '',
      version: json['version'] ?? 1,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'content': content,
    'version': version,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final MessageType type;
  final DateTime createdAt;
  final List<Attachment> attachments;
  final Map<String, dynamic>? metadata; // For tool usage or widget data
  final List<String>? suggestedPrompts; // Phase 1195 - Audit Rec

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    this.type = MessageType.text,
    required this.createdAt,
    this.attachments = const [],
    this.metadata,
    this.suggestedPrompts,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content']?.toString() ?? '',
      sender: MessageSender.values.firstWhere(
        (e) => e.name == json['sender'],
        orElse: () => MessageSender.system,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => Attachment.fromJson(Map<String, dynamic>.from(a as Map? ?? {})))
          .toList(),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
      suggestedPrompts: (json['suggestedPrompts'] as List?)
          ?.where((e) => e != null)
          .map((e) => e.toString())
          .toList(),
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
    'suggestedPrompts': suggestedPrompts,
  };

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageSender? sender,
    MessageType? type,
    DateTime? createdAt,
    List<Attachment>? attachments,
    Map<String, dynamic>? metadata,
    List<String>? suggestedPrompts,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
    );
  }
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
      id: json['id']?.toString() ?? 'unknown-session',
      campaignId: json['campaignId']?.toString() ?? 'unknown-campaign',
      messages: (json['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m as Map? ?? {})))
          .toList(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
