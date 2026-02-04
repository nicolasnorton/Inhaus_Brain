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
  final String? sectionId;
  final List<String> tags;
  final int orderIndex;
  final Map<String, dynamic> customFields;
  final String? parentId; // For subtasks
  final List<String> collaboratorIds;
  final List<String> dependencyIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> likedBy; // User IDs

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
    this.parentId,
    this.tags = const [],
    this.collaboratorIds = const [],
    this.dependencyIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.likedBy = const [],
    this.orderIndex = 0,
    this.customFields = const {},
    this.linkedProjectIds = const [],
    this.projectSectionIds = const {},
  });

  // Multihome fields
  final List<String> linkedProjectIds; // Additional projects this task belongs to
  final Map<String, String> projectSectionIds; // Map projectId -> sectionId

  ProjectTask copyWith({
    String? projectId,
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
    String? parentId,
    List<String>? tags,
    List<String>? collaboratorIds,
    List<String>? dependencyIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likedBy,
    int? orderIndex,
    Map<String, dynamic>? customFields,
    List<String>? linkedProjectIds,
    Map<String, String>? projectSectionIds,
  }) {
    return ProjectTask(
      id: id,
      projectId: projectId ?? this.projectId,
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
      parentId: parentId ?? this.parentId,
      tags: tags ?? this.tags,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      dependencyIds: dependencyIds ?? this.dependencyIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likedBy: likedBy ?? this.likedBy,
      orderIndex: orderIndex ?? this.orderIndex,
      customFields: customFields ?? this.customFields,
      linkedProjectIds: linkedProjectIds ?? this.linkedProjectIds,
      projectSectionIds: projectSectionIds ?? this.projectSectionIds,
    );
  }

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id']?.toString() ?? 'unknown-task',
      projectId: json['projectId']?.toString() ?? 'unknown-project',
      title: json['title']?.toString() ?? 'Untitled Task',
      description: json['description']?.toString() ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      doneDate: json['doneDate'] != null ? DateTime.tryParse(json['doneDate'].toString()) : null,
      assigneeId: json['assigneeId']?.toString(),
      sectionId: json['sectionId']?.toString(),
      parentId: json['parentId']?.toString(),
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      collaboratorIds: (json['collaboratorIds'] as List? ?? []).map((e) => e.toString()).toList(),
      dependencyIds: (json['dependencyIds'] as List? ?? []).map((e) => e.toString()).toList(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'].toString()) : DateTime.now(),
      likedBy: (json['likedBy'] as List? ?? []).map((e) => e.toString()).toList(),
      orderIndex: json['orderIndex'] is int ? json['orderIndex'] : 0,
      customFields: json['customFields'] is Map ? Map<String, dynamic>.from(json['customFields']) : {},
      linkedProjectIds: (json['linkedProjectIds'] as List? ?? []).map((e) => e.toString()).toList(),
      projectSectionIds: json['projectSectionIds'] is Map ? Map<String, String>.from(json['projectSectionIds']) : {},
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
    'parentId': parentId,
    'tags': tags,
    'collaboratorIds': collaboratorIds,
    'dependencyIds': dependencyIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'likedBy': likedBy,
    'orderIndex': orderIndex,
    'customFields': customFields,
    'linkedProjectIds': linkedProjectIds,
    'projectSectionIds': projectSectionIds,
  };
}

class TaskComment {
  final String id;
  final String taskId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final List<String> attachments; // URLs

  TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.attachments = const [],
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'],
      taskId: json['taskId'],
      userId: json['userId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      attachments: (json['attachments'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'userId': userId,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'attachments': attachments,
  };
}

class TaskAttachment {
  final String id;
  final String taskId;
  final String name;
  final String url;
  final String type; // 'image', 'pdf', 'link'
  final DateTime addedAt;

  TaskAttachment({
    required this.id,
    required this.taskId,
    required this.name,
    required this.url,
    required this.type,
    required this.addedAt,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'],
      taskId: json['taskId'],
      name: json['name'],
      url: json['url'],
      type: json['type'],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'name': name,
    'url': url,
    'type': type,
    'addedAt': addedAt.toIso8601String(),
  };
}
