/// Models for app management

/// App type
enum AppType {
  chatbot,
  workflow,
  agent,
  textGenerator;

  String get displayName {
    switch (this) {
      case AppType.chatbot:
        return 'Chatbot';
      case AppType.workflow:
        return 'Workflow';
      case AppType.agent:
        return 'Agent';
      case AppType.textGenerator:
        return 'Text Generator';
    }
  }

  String get icon {
    switch (this) {
      case AppType.chatbot:
        return '💬';
      case AppType.workflow:
        return '🔄';
      case AppType.agent:
        return '🤖';
      case AppType.textGenerator:
        return '✍️';
    }
  }
}

/// App status
enum AppStatus {
  draft,
  published,
  archived;

  String get displayName {
    switch (this) {
      case AppStatus.draft:
        return 'Draft';
      case AppStatus.published:
        return 'Published';
      case AppStatus.archived:
        return 'Archived';
    }
  }
}

/// App view mode
enum AppViewMode {
  grid,
  list;

  String get displayName {
    switch (this) {
      case AppViewMode.grid:
        return 'Grid';
      case AppViewMode.list:
        return 'List';
    }
  }
}

/// App model
class App {
  final String id;
  final String name;
  final AppType type;
  final String description;
  final String icon;
  final AppStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int runCount;
  final List<String> tags;
  final String? createdBy;
  final bool hasUnsavedChanges;

  const App({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.icon,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.runCount = 0,
    this.tags = const [],
    this.createdBy,
    this.hasUnsavedChanges = false,
  });

  App copyWith({
    String? id,
    String? name,
    AppType? type,
    String? description,
    String? icon,
    AppStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? runCount,
    List<String>? tags,
    String? createdBy,
    bool? hasUnsavedChanges,
  }) {
    return App(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      runCount: runCount ?? this.runCount,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'description': description,
        'icon': icon,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'run_count': runCount,
        'tags': tags,
        if (createdBy != null) 'created_by': createdBy,
        'has_unsaved_changes': hasUnsavedChanges,
      };

  factory App.fromJson(Map<String, dynamic> json) {
    return App(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AppType.values.byName(json['type'] as String),
      description: json['description'] as String,
      icon: json['icon'] as String,
      status: AppStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      runCount: json['run_count'] as int? ?? 0,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      createdBy: json['created_by'] as String?,
      hasUnsavedChanges: json['has_unsaved_changes'] as bool? ?? false,
    );
  }
}

/// App DSL for import/export
class AppDSL {
  final String version;
  final String kind;
  final App app;
  final Map<String, dynamic> workflow;
  final List<Map<String, dynamic>> knowledge;
  final List<Map<String, dynamic>> environment;
  final bool includeSecrets;

  const AppDSL({
    required this.version,
    required this.kind,
    required this.app,
    required this.workflow,
    this.knowledge = const [],
    this.environment = const [],
    this.includeSecrets = false,
  });

  String toYAML() {
    final buffer = StringBuffer();
    buffer.writeln('version: $version');
    buffer.writeln('kind: $kind');
    buffer.writeln('app:');
    buffer.writeln('  name: "${app.name}"');
    buffer.writeln('  type: ${app.type.name}');
    buffer.writeln('  description: "${app.description}"');
    buffer.writeln('  icon: "${app.icon}"');
    buffer.writeln('  tags: ${app.tags}');
    buffer.writeln();
    buffer.writeln('workflow:');
    buffer.writeln('  # Workflow configuration');
    buffer.writeln();
    buffer.writeln('knowledge:');
    buffer.writeln('  # Knowledge base references');
    buffer.writeln();
    buffer.writeln('environment:');
    if (!includeSecrets) {
      buffer.writeln('  # Secret values not included for security');
    }
    return buffer.toString();
  }

  static AppDSL? fromYAML(String yaml) {
    // Simplified YAML parsing - in production use yaml package
    try {
      return AppDSL(
        version: '0.6.0',
        kind: 'app',
        app: App(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Imported App',
          type: AppType.chatbot,
          description: 'Imported from DSL',
          icon: '📥',
          status: AppStatus.draft,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        workflow: {},
      );
    } catch (e) {
      return null;
    }
  }
}

/// App filter criteria
class AppFilter {
  final AppType? type;
  final AppStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? createdBy;

  const AppFilter({
    this.type,
    this.status,
    this.startDate,
    this.endDate,
    this.createdBy,
  });

  bool matches(App app) {
    if (type != null && app.type != type) return false;
    if (status != null && app.status != status) return false;
    if (startDate != null && app.createdAt.isBefore(startDate!)) return false;
    if (endDate != null && app.createdAt.isAfter(endDate!)) return false;
    if (createdBy != null && app.createdBy != createdBy) return false;
    return true;
  }
}

/// App sort criteria
enum AppSortBy {
  name,
  created,
  updated,
  runs;

  String get displayName {
    switch (this) {
      case AppSortBy.name:
        return 'Name';
      case AppSortBy.created:
        return 'Created Date';
      case AppSortBy.updated:
        return 'Last Updated';
      case AppSortBy.runs:
        return 'Run Count';
    }
  }
}
