import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents explicit edges between Nodes in the Weave Space.
class BrainWeaveLink {
  final String id;
  final String clientId;
  final String projectId;
  final String ownerId;

  final String sourceNodeId;
  final String targetNodeId;
  
  /// Semantic reason for the link (e.g. "extends", "contradicts")
  final String relationshipType; 
  final List<double>? embedding; // Vector index for semantic link retrieval

  final DateTime createdAt;
  final DateTime updatedAt;

  BrainWeaveLink({
    required this.id,
    required this.clientId,
    required this.projectId,
    required this.ownerId,
    required this.sourceNodeId,
    required this.targetNodeId,
    required this.relationshipType,
    this.embedding,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrainWeaveLink.fromJson(Map<String, dynamic> json, String id) {
    return BrainWeaveLink(
      id: id,
      clientId: json['clientId'] ?? '',
      projectId: json['projectId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      sourceNodeId: json['sourceNodeId'] ?? '',
      targetNodeId: json['targetNodeId'] ?? '',
      relationshipType: json['relationshipType'] ?? '',
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
      'sourceNodeId': sourceNodeId,
      'targetNodeId': targetNodeId,
      'relationshipType': relationshipType,
      if (embedding != null) 'embedding': embedding,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
