enum ProjectStatus {
  planning,
  inProgress,
  completed,
  archived,
}

class Project {
  final String id;
  final String clientId;
  final String name;
  final String description;
  final ProjectStatus status;
  final DateTime startDate;
  final DateTime? endDate;

  Project({
    required this.id,
    required this.clientId,
    required this.name,
    required this.description,
    this.status = ProjectStatus.planning,
    required this.startDate,
    this.endDate,
  });

  Project copyWith({
    String? name,
    String? description,
    ProjectStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Project(
      id: id,
      clientId: clientId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'name': name,
    'description': description,
    'status': status.toString(),
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
  };
}
