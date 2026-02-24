import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/architecture/blackboard.dart';

/// Represents Operational Coordination in the Flow Space.
/// Tracks queue state and 6R phase transitions for a given session.
class BrainWeaveSession {
  final String id;
  final String clientId;
  final String projectId;
  final String ownerId;

  /// The current Pipeline Phase (6R)
  final BlackboardPhase currentPhase;

  /// The transcript of actions, friction logs, and observations
  final List<String> sessionLogs;
  
  /// Task queue IDs associated with this session
  final List<String> queueTaskIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  BrainWeaveSession({
    required this.id,
    required this.clientId,
    required this.projectId,
    required this.ownerId,
    required this.currentPhase,
    required this.sessionLogs,
    required this.queueTaskIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrainWeaveSession.fromJson(Map<String, dynamic> json, String id) {
    return BrainWeaveSession(
      id: id,
      clientId: json['clientId'] ?? '',
      projectId: json['projectId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      currentPhase: BlackboardPhase.values.firstWhere(
        (e) => e.name == json['currentPhase'],
        orElse: () => BlackboardPhase.idle,
      ),
      sessionLogs: List<String>.from(json['sessionLogs'] ?? []),
      queueTaskIds: List<String>.from(json['queueTaskIds'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'projectId': projectId,
      'ownerId': ownerId,
      'currentPhase': currentPhase.name,
      'sessionLogs': sessionLogs,
      'queueTaskIds': queueTaskIds,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
