import 'package:uuid/uuid.dart';
import 'adk_artifact.dart';

/// Manages a collection of pipelines and their shared state over time.
/// Maps to a high-level user goal (e.g., "Create a complete marketing campaign").
class AdkSession {
  final String id;
  final String name;
  final List<AdkArtifact> artifacts;
  final Map<String, dynamic> persistentState;
  final DateTime createdAt;
  DateTime updatedAt;

  AdkSession({
    String? id,
    required this.name,
    this.artifacts = const [],
    this.persistentState = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AdkSession copyWith({
    String? name,
    List<AdkArtifact>? artifacts,
    Map<String, dynamic>? persistentState,
    DateTime? updatedAt,
  }) {
    return AdkSession(
      id: id,
      name: name ?? this.name,
      artifacts: artifacts ?? this.artifacts,
      persistentState: persistentState ?? this.persistentState,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'artifacts': artifacts.map((a) => a.toJson()).toList(),
        'persistentState': persistentState,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AdkSession.fromJson(Map<String, dynamic> json) => AdkSession(
        id: json['id'],
        name: json['name'],
        artifacts: (json['artifacts'] as List)
            .map((a) => AdkArtifact.fromJson(a))
            .toList(),
        persistentState: json['persistentState'] ?? {},
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}
