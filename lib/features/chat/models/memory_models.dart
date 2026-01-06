class MemoryItem {
  final String id;
  final String key;
  final String value;
  final String category; // e.g., 'preference', 'fact', 'entity', 'task'
  final DateTime createdAt;
  final String? campaignId;
  final Map<String, dynamic>? metadata;

  MemoryItem({
    required this.id,
    required this.key,
    required this.value,
    this.category = 'fact',
    required this.createdAt,
    this.campaignId,
    this.metadata,
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
  };
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
