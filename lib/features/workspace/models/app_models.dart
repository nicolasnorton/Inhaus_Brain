import 'dart:convert';
import 'package:flutter/material.dart';

/// Models for app management

/// App type
enum AppType {
  workflow,
  chatflow,
  chatbot,
  agent,
  textGenerator;

  String get displayName {
    switch (this) {
      case AppType.workflow:
        return 'Workflow';
      case AppType.chatflow:
        return 'Chatflow';
      case AppType.chatbot:
        return 'Chatbot';
      case AppType.agent:
        return 'Agent';
      case AppType.textGenerator:
        return 'Text Generator';
    }
  }

  String get icon {
    switch (this) {
      case AppType.workflow:
        return '🔄';
      case AppType.chatflow:
        return '💬';
      case AppType.chatbot:
        return '🤖';
      case AppType.agent:
        return '🧠';
      case AppType.textGenerator:
        return '✍️';
    }
  }

  Color get color {
    switch (this) {
      case AppType.workflow:
        return const Color(0xFF6366F1);
      case AppType.chatflow:
        return const Color(0xFF3B82F6);
      case AppType.chatbot:
        return const Color(0xFF8B5CF6);
      case AppType.agent:
        return const Color(0xFFA855F7);
      case AppType.textGenerator:
        return const Color(0xFF10B981);
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
  final Map<String, dynamic> config;

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
    this.config = const {},
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
    Map<String, dynamic>? config,
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
      config: config ?? this.config,
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
        'config': config,
      };

  factory App.fromJson(Map<String, dynamic> json) {
    return App(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? 'Untitled App') as String,
      type: _parseAppType(json['type']),
      description: (json['description'] ?? '') as String,
      icon: (json['icon'] ?? '⚡') as String,
      status: _parseAppStatus(json['status']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      runCount: json['run_count'] as int? ?? 0,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      createdBy: json['created_by'] as String?,
      hasUnsavedChanges: json['has_unsaved_changes'] as bool? ?? false,
      config: Map<String, dynamic>.from(json['config'] ?? {}),
    );
  }

  static AppType _parseAppType(dynamic value) {
    if (value is! String) return AppType.workflow;
    try {
      return AppType.values.byName(value);
    } catch (_) {
      return AppType.workflow;
    }
  }

  static AppStatus _parseAppStatus(dynamic value) {
    if (value is! String) return AppStatus.draft;
    try {
      return AppStatus.values.byName(value);
    } catch (_) {
      return AppStatus.draft;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is! String) return DateTime.now();
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
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

  String _toYamlValue(dynamic value, int indent) {
    if (value is Map) {
      final buffer = StringBuffer();
      value.forEach((k, v) {
        buffer.writeln();
        buffer.write('  ' * indent);
        buffer.write('$k: ${_toYamlValue(v, indent + 1)}');
      });
      return buffer.toString();
    } else if (value is List) {
      if (value.isEmpty) return '[]';
      final buffer = StringBuffer();
      for (var item in value) {
        buffer.writeln();
        buffer.write('  ' * indent);
        buffer.write('- ${_toYamlValue(item, indent + 1)}');
      }
      return buffer.toString();
    } else {
      return value.toString();
    }
  }

  String toYAML() {
    final buffer = StringBuffer();
    buffer.writeln('version: $version');
    buffer.writeln('kind: $kind');
    buffer.write('app:');
    app.toJson().forEach((k, v) {
      buffer.writeln();
      buffer.write('  $k: $v');
    });
    buffer.write('\nworkflow:');
    workflow.forEach((k, v) {
      buffer.writeln();
      buffer.write('  $k: ${_toYamlValue(v, 2)}');
    });
    return buffer.toString();
  }

  String toJsonString() {
    final map = {
      'version': version,
      'kind': kind,
      'app': app.toJson(),
      'workflow': workflow,
      'knowledge': knowledge,
      'environment': includeSecrets ? environment : [],
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static AppDSL? fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      if (json is! Map<String, dynamic>) return null;

      final appJson = json['app'];
      if (appJson == null || appJson is! Map<String, dynamic>) return null;

      return AppDSL(
        version: (json['version'] ?? '0.0.1') as String,
        kind: (json['kind'] ?? 'app') as String,
        app: App.fromJson(appJson),
        workflow: (json['workflow'] ?? {}) as Map<String, dynamic>,
        knowledge: (json['knowledge'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
        environment: (json['environment'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
      );
    } catch (e) {
      debugPrint('Error parsing AppDSL: $e');
      return null;
    }
  }

  static AppDSL? fromYAML(String yaml) {
    // Redirect to JSON parser for now as we are strictly using JSON
    return fromJsonString(yaml);
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
