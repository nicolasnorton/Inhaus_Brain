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
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? doneDate;
  final String? assigneeId;
  final String? sectionId; // References Project.sections[index] or name
  final List<String> tags;
  final int orderIndex;
  final Map<String, dynamic> customFields; // For multimodal data (files, URLs, voice, etc.)

  ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.startDate,
    this.endDate,
    this.doneDate,
    this.assigneeId,
    this.sectionId,
    this.tags = const [],
    this.orderIndex = 0,
    this.customFields = const {},
  });

  ProjectTask copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? doneDate,
    String? assigneeId,
    String? sectionId,
    List<String>? tags,
    int? orderIndex,
    Map<String, dynamic>? customFields,
  }) {
    return ProjectTask(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      doneDate: doneDate ?? this.doneDate,
      assigneeId: assigneeId ?? this.assigneeId,
      sectionId: sectionId ?? this.sectionId,
      tags: tags ?? this.tags,
      orderIndex: orderIndex ?? this.orderIndex,
      customFields: customFields ?? this.customFields,
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
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      doneDate: json['doneDate'] != null ? DateTime.parse(json['doneDate'] as String) : null,
      assigneeId: json['assigneeId'] as String?,
      sectionId: json['sectionId'] as String?,
      tags: (json['tags'] as List? ?? []).cast<String>(),
      orderIndex: json['orderIndex'] as int? ?? 0,
      customFields: Map<String, dynamic>.from(json['customFields'] ?? {}),
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
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'doneDate': doneDate?.toIso8601String(),
    'assigneeId': assigneeId,
    'sectionId': sectionId,
    'tags': tags,
    'orderIndex': orderIndex,
    'customFields': customFields,
  };
}
