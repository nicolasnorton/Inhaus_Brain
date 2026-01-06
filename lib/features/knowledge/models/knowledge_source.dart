enum KnowledgeSourceType {
  url,
  text,
  file,
  pdf,
  googleDrive,
  image
}

class KnowledgeSource {
  final String id;
  final String title;
  final String content; // The actual text content or the URL
  final KnowledgeSourceType type;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  KnowledgeSource({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.metadata,
  });

  factory KnowledgeSource.fromJson(Map<String, dynamic> json) {
    return KnowledgeSource(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: KnowledgeSourceType.values.firstWhere((e) => e.name == json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'type': type.name,
    'createdAt': createdAt.toIso8601String(),
    'metadata': metadata,
  };

  KnowledgeSource copyWith({
    String? title,
    String? content,
    Map<String, dynamic>? metadata,
  }) {
    return KnowledgeSource(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type,
      createdAt: createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
