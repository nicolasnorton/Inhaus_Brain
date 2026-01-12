enum TaskStatus {
  todo,
  inProgress,
  review,
  done,
}

class ProjectTask {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime? dueDate;
  final String? assigneeId;

  ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    this.status = TaskStatus.todo,
    this.dueDate,
    this.assigneeId,
  });

  ProjectTask copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? dueDate,
    String? assigneeId,
  }) {
    return ProjectTask(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      assigneeId: assigneeId ?? this.assigneeId,
    );
  }

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TaskStatus.todo,
      ),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      assigneeId: json['assigneeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'title': title,
    'description': description,
    'status': status.toString(),
    'dueDate': dueDate?.toIso8601String(),
    'assigneeId': assigneeId,
  };
}
