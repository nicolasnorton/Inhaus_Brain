
/// A single commit/snapshot in the workflow history
class WorkflowCommit {
  final String id;
  final String appId;
  final String message;
  final String author;
  final DateTime timestamp;
  final Map<String, dynamic> dslSnapshot;
  final String? parentId;

  const WorkflowCommit({
    required this.id,
    required this.appId,
    required this.message,
    required this.author,
    required this.timestamp,
    required this.dslSnapshot,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'appId': appId,
        'message': message,
        'author': author,
        'timestamp': timestamp.toIso8601String(),
        'dslSnapshot': dslSnapshot,
        'parentId': parentId,
      };

  factory WorkflowCommit.fromJson(Map<String, dynamic> json) {
    return WorkflowCommit(
      id: json['id'] as String,
      appId: json['appId'] as String,
      message: json['message'] as String,
      author: json['author'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      dslSnapshot: json['dslSnapshot'] as Map<String, dynamic>,
      parentId: json['parentId'] as String?,
    );
  }
}
