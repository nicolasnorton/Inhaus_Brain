import 'package:cloud_firestore/cloud_firestore.dart';

enum BrainWeaveNodeType { atomic, moc, topic, campaign, client, insight, asset, trend, skill }

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

  // ── BrainWeave 2.0 fields ──────────────────────────
  final String? markdownUri;   // gs:// pointer to Cloud Storage Markdown
  final String? sourceAgent;   // Which agent created this node
  final double confidence;     // Extraction confidence score
  final int version;           // Version counter
  final String scope;          // PRIVATE | CLIENT | AGENCY
  final Map<String, dynamic>? metadata;

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
    this.markdownUri,
    this.sourceAgent,
    this.confidence = 1.0,
    this.version = 1,
    this.scope = 'PRIVATE',
    this.metadata,
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
      markdownUri: json['markdownUri'],
      sourceAgent: json['sourceAgent'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      version: json['version'] as int? ?? 1,
      scope: json['scope'] ?? 'PRIVATE',
      metadata: json['metadata'] as Map<String, dynamic>?,
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
      if (markdownUri != null) 'markdownUri': markdownUri,
      if (sourceAgent != null) 'sourceAgent': sourceAgent,
      'confidence': confidence,
      'version': version,
      'scope': scope,
      if (metadata != null) 'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

