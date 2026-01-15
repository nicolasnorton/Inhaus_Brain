enum ProjectStatus {
  planning,
  inProgress,
  completed,
  archived,
}

enum ProjectPriority {
  low,
  medium,
  high,
  urgent,
}

class Project {
  final String id;
  final String clientId;
  final String name;
  final String description;
  final ProjectStatus status;
  final ProjectPriority priority;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> sections; // For Kanban/Board columns (e.g. "To Do", "Doing")

  Project({
    required this.id,
    required this.clientId,
    required this.name,
    required this.description,
    this.status = ProjectStatus.planning,
    this.priority = ProjectPriority.medium,
    required this.startDate,
    this.endDate,
    this.sections = const ['To Do', 'In Progress', 'Done'],
  });

  Project copyWith({
    String? name,
    String? description,
    ProjectStatus? status,
    ProjectPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? sections,
  }) {
    return Project(
      id: id,
      clientId: clientId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sections: sections ?? this.sections,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      status: ProjectStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ProjectStatus.planning,
      ),
      priority: ProjectPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => ProjectPriority.medium,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      sections: (json['sections'] as List? ?? ['To Do', 'In Progress', 'Done']).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'name': name,
    'description': description,
    'status': status.toString(),
    'priority': priority.toString(),
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'sections': sections,
  };
}
