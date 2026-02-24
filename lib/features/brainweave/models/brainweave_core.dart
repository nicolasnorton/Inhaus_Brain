import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the Agent's Persistent Mind in the Core Space.
/// Holds Identity, Methodology, and Goals.
class BrainWeaveCore {
  final String id;
  final String clientId;
  final String projectId;
  final String ownerId;
  
  final String identity;
  final String methodology;
  final String goals;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  BrainWeaveCore({
    required this.id,
    required this.clientId,
    required this.projectId,
    required this.ownerId,
    required this.identity,
    required this.methodology,
    required this.goals,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrainWeaveCore.fromJson(Map<String, dynamic> json, String id) {
    return BrainWeaveCore(
      id: id,
      clientId: json['clientId'] ?? '',
      projectId: json['projectId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      identity: json['identity'] ?? '',
      methodology: json['methodology'] ?? '',
      goals: json['goals'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'projectId': projectId,
      'ownerId': ownerId,
      'identity': identity,
      'methodology': methodology,
      'goals': goals,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
