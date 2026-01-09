import 'package:flutter/material.dart';

/// Execution status for node runs
enum ExecutionStatus {
  pending,
  running,
  success,
  failed;

  String get displayName {
    switch (this) {
      case ExecutionStatus.pending:
        return 'Pending';
      case ExecutionStatus.running:
        return 'Running';
      case ExecutionStatus.success:
        return 'Success';
      case ExecutionStatus.failed:
        return 'Failed';
    }
  }

  Color get color {
    switch (this) {
      case ExecutionStatus.pending:
        return Colors.grey;
      case ExecutionStatus.running:
        return Colors.blue;
      case ExecutionStatus.success:
        return Colors.green;
      case ExecutionStatus.failed:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ExecutionStatus.pending:
        return Icons.schedule;
      case ExecutionStatus.running:
        return Icons.play_circle;
      case ExecutionStatus.success:
        return Icons.check_circle;
      case ExecutionStatus.failed:
        return Icons.error;
    }
  }
}

/// Node execution record
class NodeExecution {
  final String id;
  final String nodeId;
  final String nodeName;
  final String nodeType;
  final ExecutionStatus status;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final DateTime startTime;
  final DateTime? endTime;
  final String? error;
  final String? executor;
  final int? totalTokens;
  final int? promptTokens;
  final int? completionTokens;

  const NodeExecution({
    required this.id,
    required this.nodeId,
    required this.nodeName,
    required this.nodeType,
    required this.status,
    required this.inputs,
    required this.outputs,
    required this.startTime,
    this.endTime,
    this.error,
    this.executor,
    this.totalTokens,
    this.promptTokens,
    this.completionTokens,
  });

  Duration? get elapsedTime => endTime?.difference(startTime);

  String get elapsedTimeFormatted {
    final elapsed = elapsedTime;
    if (elapsed == null) return '-';
    
    if (elapsed.inSeconds < 1) {
      return '${elapsed.inMilliseconds}ms';
    }
    return '${elapsed.inSeconds}.${(elapsed.inMilliseconds % 1000).toString().padLeft(3, '0').substring(0, 3)}s';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'node_id': nodeId,
        'node_name': nodeName,
        'node_type': nodeType,
        'status': status.name,
        'inputs': inputs,
        'outputs': outputs,
        'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        if (error != null) 'error': error,
        if (executor != null) 'executor': executor,
        if (totalTokens != null) 'total_tokens': totalTokens,
        if (promptTokens != null) 'prompt_tokens': promptTokens,
        if (completionTokens != null) 'completion_tokens': completionTokens,
      };

  factory NodeExecution.fromJson(Map<String, dynamic> json) {
    return NodeExecution(
      id: json['id'] as String,
      nodeId: json['node_id'] as String,
      nodeName: json['node_name'] as String,
      nodeType: json['node_type'] as String,
      status: ExecutionStatus.values.byName(json['status'] as String),
      inputs: json['inputs'] as Map<String, dynamic>,
      outputs: json['outputs'] as Map<String, dynamic>,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      error: json['error'] as String?,
      executor: json['executor'] as String?,
      totalTokens: json['total_tokens'] as int?,
      promptTokens: json['prompt_tokens'] as int?,
      completionTokens: json['completion_tokens'] as int?,
    );
  }
}

/// Cached variable in Variable Inspector
class CachedVariable {
  final String name;
  final String nodeId;
  final String nodeName;
  final dynamic value;
  final dynamic originalValue;
  final String type;
  final bool isEdited;
  final bool isSystemVariable;

  const CachedVariable({
    required this.name,
    required this.nodeId,
    required this.nodeName,
    required this.value,
    required this.originalValue,
    required this.type,
    this.isEdited = false,
    this.isSystemVariable = false,
  });

  bool get canEdit => !isSystemVariable && type != 'function';

  CachedVariable copyWith({
    String? name,
    String? nodeId,
    String? nodeName,
    dynamic value,
    dynamic originalValue,
    String? type,
    bool? isEdited,
    bool? isSystemVariable,
  }) {
    return CachedVariable(
      name: name ?? this.name,
      nodeId: nodeId ?? this.nodeId,
      nodeName: nodeName ?? this.nodeName,
      value: value ?? this.value,
      originalValue: originalValue ?? this.originalValue,
      type: type ?? this.type,
      isEdited: isEdited ?? this.isEdited,
      isSystemVariable: isSystemVariable ?? this.isSystemVariable,
    );
  }

  /// Reset to original value
  CachedVariable reset() {
    return copyWith(
      value: originalValue,
      isEdited: false,
    );
  }

  /// Detect type from value
  static String detectType(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return 'string';
    if (value is int) return 'number';
    if (value is double) return 'number';
    if (value is bool) return 'boolean';
    if (value is List) {
      if (value.isEmpty) return 'array[any]';
      final firstType = detectType(value.first);
      return 'array[$firstType]';
    }
    if (value is Map) return 'object';
    if (value is Function) return 'function';
    return 'unknown';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'node_id': nodeId,
        'node_name': nodeName,
        'value': value,
        'original_value': originalValue,
        'type': type,
        'is_edited': isEdited,
        'is_system_variable': isSystemVariable,
      };

  factory CachedVariable.fromJson(Map<String, dynamic> json) {
    return CachedVariable(
      name: json['name'] as String,
      nodeId: json['node_id'] as String,
      nodeName: json['node_name'] as String,
      value: json['value'],
      originalValue: json['original_value'],
      type: json['type'] as String,
      isEdited: json['is_edited'] as bool? ?? false,
      isSystemVariable: json['is_system_variable'] as bool? ?? false,
    );
  }
}

/// Variable Inspector state
class VariableInspectorState {
  final Map<String, CachedVariable> variables;
  final String? selectedVariable;
  final bool showSystemVariables;
  final bool isExpanded;

  const VariableInspectorState({
    this.variables = const {},
    this.selectedVariable,
    this.showSystemVariables = true,
    this.isExpanded = true,
  });

  VariableInspectorState copyWith({
    Map<String, CachedVariable>? variables,
    String? selectedVariable,
    bool? showSystemVariables,
    bool? isExpanded,
  }) {
    return VariableInspectorState(
      variables: variables ?? this.variables,
      selectedVariable: selectedVariable ?? this.selectedVariable,
      showSystemVariables: showSystemVariables ?? this.showSystemVariables,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  /// Get variables grouped by node
  Map<String, List<CachedVariable>> get variablesByNode {
    final grouped = <String, List<CachedVariable>>{};
    
    for (final variable in variables.values) {
      if (!showSystemVariables && variable.isSystemVariable) continue;
      
      final key = variable.nodeName;
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(variable);
    }
    
    return grouped;
  }

  /// Reset all variables to original values
  VariableInspectorState resetAll() {
    final resetVariables = <String, CachedVariable>{};
    for (final entry in variables.entries) {
      resetVariables[entry.key] = entry.value.reset();
    }
    return copyWith(variables: resetVariables);
  }

  /// Clear all cached variables
  VariableInspectorState clearAll() {
    return copyWith(variables: {});
  }
}

/// Error category for debugging
enum ErrorCategory {
  network,
  validation,
  api,
  timeout,
  permission,
  configuration,
  runtime,
  unknown;

  String get displayName {
    switch (this) {
      case ErrorCategory.network:
        return 'Network Error';
      case ErrorCategory.validation:
        return 'Validation Error';
      case ErrorCategory.api:
        return 'API Error';
      case ErrorCategory.timeout:
        return 'Timeout Error';
      case ErrorCategory.permission:
        return 'Permission Error';
      case ErrorCategory.configuration:
        return 'Configuration Error';
      case ErrorCategory.runtime:
        return 'Runtime Error';
      case ErrorCategory.unknown:
        return 'Unknown Error';
    }
  }

  IconData get icon {
    switch (this) {
      case ErrorCategory.network:
        return Icons.wifi_off;
      case ErrorCategory.validation:
        return Icons.rule;
      case ErrorCategory.api:
        return Icons.api;
      case ErrorCategory.timeout:
        return Icons.timer_off;
      case ErrorCategory.permission:
        return Icons.lock;
      case ErrorCategory.configuration:
        return Icons.settings;
      case ErrorCategory.runtime:
        return Icons.bug_report;
      case ErrorCategory.unknown:
        return Icons.error_outline;
    }
  }
}

/// Execution error with debugging information
class ExecutionError {
  final ErrorCategory category;
  final String message;
  final String? stackTrace;
  final List<String> suggestions;

  const ExecutionError({
    required this.category,
    required this.message,
    this.stackTrace,
    this.suggestions = const [],
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'message': message,
        if (stackTrace != null) 'stack_trace': stackTrace,
        'suggestions': suggestions,
      };

  factory ExecutionError.fromJson(Map<String, dynamic> json) {
    return ExecutionError(
      category: ErrorCategory.values.byName(json['category'] as String),
      message: json['message'] as String,
      stackTrace: json['stack_trace'] as String?,
      suggestions: (json['suggestions'] as List?)?.cast<String>() ?? [],
    );
  }

  /// Categorize error from message
  static ErrorCategory categorizeError(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return ErrorCategory.network;
    }
    if (lowerError.contains('validation') || lowerError.contains('invalid')) {
      return ErrorCategory.validation;
    }
    if (lowerError.contains('api') || lowerError.contains('http')) {
      return ErrorCategory.api;
    }
    if (lowerError.contains('timeout') || lowerError.contains('timed out')) {
      return ErrorCategory.timeout;
    }
    if (lowerError.contains('permission') || lowerError.contains('unauthorized')) {
      return ErrorCategory.permission;
    }
    if (lowerError.contains('config') || lowerError.contains('missing')) {
      return ErrorCategory.configuration;
    }
    
    return ErrorCategory.runtime;
  }

  /// Generate debugging suggestions
  static List<String> generateSuggestions(ErrorCategory category, String error) {
    switch (category) {
      case ErrorCategory.network:
        return [
          'Check your internet connection',
          'Verify the API endpoint is accessible',
          'Check for firewall or proxy issues',
        ];
      case ErrorCategory.validation:
        return [
          'Verify input data format',
          'Check required fields are present',
          'Validate data types match expectations',
        ];
      case ErrorCategory.api:
        return [
          'Check API key is valid',
          'Verify API endpoint URL',
          'Review API documentation for changes',
        ];
      case ErrorCategory.timeout:
        return [
          'Increase timeout duration',
          'Check if service is responding slowly',
          'Consider breaking into smaller requests',
        ];
      case ErrorCategory.permission:
        return [
          'Verify API credentials',
          'Check user permissions',
          'Ensure required scopes are granted',
        ];
      case ErrorCategory.configuration:
        return [
          'Check configuration settings',
          'Verify all required fields are set',
          'Review environment variables',
        ];
      case ErrorCategory.runtime:
        return [
          'Check for null values',
          'Verify variable types',
          'Review recent code changes',
        ];
      case ErrorCategory.unknown:
        return [
          'Review error message carefully',
          'Check application logs',
          'Try running in debug mode',
        ];
    }
  }
}
