import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String actorId;
  final String actorEmail;
  final String action; // e.g., 'UPDATE_ROLE', 'DELETE_CLIENT'
  final String resourceId;
  final String resourceType; // e.g., 'USER', 'CLIENT', 'CAMPAIGN'
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AuditLog({
    required this.id,
    required this.actorId,
    required this.actorEmail,
    required this.action,
    required this.resourceId,
    required this.resourceType,
    required this.timestamp,
    this.metadata,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      actorId: json['actorId'] as String,
      actorEmail: json['actorEmail'] as String,
      action: json['action'] as String,
      resourceId: json['resourceId'] as String,
      resourceType: json['resourceType'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'actorId': actorId,
    'actorEmail': actorEmail,
    'action': action,
    'resourceId': resourceId,
    'resourceType': resourceType,
    'timestamp': FieldValue.serverTimestamp(),
    'metadata': metadata,
  };
}
