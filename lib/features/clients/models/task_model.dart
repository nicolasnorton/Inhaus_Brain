enum TaskStatus {
  todo,
  inProgress,
  review,
  done,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

class ProjectTask {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? assigneeId;
  final String? sectionId; // References Project.sections[index] or name
  final List<String> tags;

  ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.assigneeId,
    this.sectionId,
    this.tags = const [],
  });

  ProjectTask copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    String? assigneeId,
    String? sectionId,
    List<String>? tags,
  }) {
    return ProjectTask(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      assigneeId: assigneeId ?? this.assigneeId,
      sectionId: sectionId ?? this.sectionId,
      tags: tags ?? this.tags,
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
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      assigneeId: json['assigneeId'] as String?,
      sectionId: json['sectionId'] as String?,
      tags: (json['tags'] as List? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'title': title,
    'description': description,
    'status': status.toString(),
    'priority': priority.toString(),
    'dueDate': dueDate?.toIso8601String(),
    'assigneeId': assigneeId,
    'sectionId': sectionId,
    'tags': tags,
  };
}
