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
      id: json['id']?.toString() ?? 'unknown-project',
      clientId: json['clientId']?.toString() ?? 'unknown-client',
      name: json['name']?.toString() ?? 'Unnamed Project',
      description: json['description']?.toString() ?? '',
      status: ProjectStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ProjectStatus.planning,
      ),
      priority: ProjectPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => ProjectPriority.medium,
      ),
      startDate: json['startDate'] != null 
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      sections: (json['sections'] as List? ?? ['To Do', 'In Progress', 'Done']).map((e) => e.toString()).toList(),
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
