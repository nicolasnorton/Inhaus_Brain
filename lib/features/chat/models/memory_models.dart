enum MemoryScope {
  private, // Agent-specific only
  shared, // Accessible by other agents for this user
  superAdmin // Accessible by the Super Copilot
}

class MemoryItem {
  final String id;
  final String key;
  final String value;
  final String category; // e.g., 'preference', 'fact', 'entity', 'task'
  final DateTime createdAt;
  final String? campaignId;
  final Map<String, dynamic>? metadata;
  final String? agentId; // Which agent created this
  final String? userId; // Which user owns this
  final MemoryScope scope;

  MemoryItem({
    required this.id,
    required this.key,
    required this.value,
    this.category = 'fact',
    required this.createdAt,
    this.campaignId,
    this.metadata,
    this.agentId,
    this.userId,
    this.scope = MemoryScope.private,
  });

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] as String,
      key: json['key'] as String,
      value: json['value'] as String,
      category: json['category'] as String? ?? 'fact',
      createdAt: DateTime.parse(json['createdAt'] as String),
      campaignId: json['campaignId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      agentId: json['agentId'] as String?,
      userId: json['userId'] as String?,
      scope: json['scope'] != null
          ? MemoryScope.values.firstWhere((e) => e.name == json['scope'])
          : MemoryScope.private,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'value': value,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'campaignId': campaignId,
    'metadata': metadata,
    'agentId': agentId,
    'userId': userId,
    'scope': scope.name,
  };

  MemoryItem copyWith({
    String? id,
    String? key,
    String? value,
    String? category,
    DateTime? createdAt,
    String? campaignId,
    Map<String, dynamic>? metadata,
    String? agentId,
    String? userId,
    MemoryScope? scope,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      campaignId: campaignId ?? this.campaignId,
      metadata: metadata ?? this.metadata,
      agentId: agentId ?? this.agentId,
      userId: userId ?? this.userId,
      scope: scope ?? this.scope,
    );
  }
}

class MemorySession {
  final String id;
  final String title;
  final List<MemoryItem> items;
  final DateTime updatedAt;

  MemorySession({
    required this.id,
    required this.title,
    this.items = const [],
    required this.updatedAt,
  });

  factory MemorySession.fromJson(Map<String, dynamic> json) {
    return MemorySession(
      id: json['id'] as String,
      title: json['title'] as String,
      items: (json['items'] as List? ?? [])
          .map((i) => MemoryItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'items': items.map((i) => i.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
