import 'package:cloud_firestore/cloud_firestore.dart';

enum BrainWeaveNodeType { atomic, moc, topic }

/// Represents the User's Knowledge Graph in the Weave Space.
class BrainWeaveNode {
  final String id;
  final String clientId;
  final String projectId;
  final String ownerId;

  final String title;
  final String description; // Progressive disclosure
  final String content;
  final BrainWeaveNodeType type;
  
  final List<String> topics; // Forward linkages to MOCs
  final List<double>? embedding; // Vector index

  final DateTime createdAt;
  final DateTime updatedAt;

  BrainWeaveNode({
    required this.id,
    required this.clientId,
    required this.projectId,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.content,
    required this.type,
    required this.topics,
    this.embedding,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrainWeaveNode.fromJson(Map<String, dynamic> json, String id) {
    return BrainWeaveNode(
      id: id,
      clientId: json['clientId'] ?? '',
      projectId: json['projectId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      type: BrainWeaveNodeType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => BrainWeaveNodeType.atomic),
      topics: List<String>.from(json['topics'] ?? []),
      embedding: json['embedding'] != null
          ? List<double>.from(json['embedding'])
          : null,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'projectId': projectId,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'content': content,
      'type': type.name,
      'topics': topics,
      if (embedding != null) 'embedding': embedding,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
