import 'package:uuid/uuid.dart';

enum AdkArtifactType {
  text,
  image,
  data, // JSON/Structured
  code,
  audio,
  video,
  binary,
}

/// Represents a structured output from an Agent or Pipeline.
/// Includes lineage (source agent) and metadata.
class AdkArtifact {
  final String id;
  final String? label;
  final AdkArtifactType type;
  final dynamic content; // String, Map, or List
  final String sourceAgent;
  final String? pipelineId;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  AdkArtifact({
    String? id,
    this.label,
    required this.type,
    required this.content,
    required this.sourceAgent,
    this.pipelineId,
    DateTime? createdAt,
    this.metadata = const {},
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        'content': content,
        'sourceAgent': sourceAgent,
        'pipelineId': pipelineId,
        'createdAt': createdAt.toIso8601String(),
        'metadata': metadata,
      };

  factory AdkArtifact.fromJson(Map<String, dynamic> json) => AdkArtifact(
        id: json['id'],
        label: json['label'],
        type: AdkArtifactType.values.byName(json['type']),
        content: json['content'],
        sourceAgent: json['sourceAgent'],
        pipelineId: json['pipelineId'],
        createdAt: DateTime.parse(json['createdAt']),
        metadata: json['metadata'] ?? {},
      );

  @override
  String toString() {
    if (type == AdkArtifactType.text) return content.toString();
    if (type == AdkArtifactType.data) return "Data Artifact ($label)";
    return "Artifact: $type ($label)";
  }
}
