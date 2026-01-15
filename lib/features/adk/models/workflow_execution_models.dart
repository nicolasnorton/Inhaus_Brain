/// Models for workflow execution and variable management
library;

/// Variable category for organization
enum VariableCategory {
  system,
  input,
  output,
  conversation,
  environment;

  String get displayName {
    switch (this) {
      case VariableCategory.system:
        return 'System Variables';
      case VariableCategory.input:
        return 'Input Variables';
      case VariableCategory.output:
        return 'Node Outputs';
      case VariableCategory.conversation:
        return 'Conversation Variables';
      case VariableCategory.environment:
        return 'Environment Variables';
    }
  }
}

/// Variable reference for use in workflow
class VariableReference {
  final String nodeId;
  final String nodeName;
  final String variableName;
  final String dataType;
  final VariableCategory category;
  final String? description;

  const VariableReference({
    required this.nodeId,
    required this.nodeName,
    required this.variableName,
    required this.dataType,
    required this.category,
    this.description,
  });

  /// Get formatted reference string for insertion
  String get reference => '{$nodeName/$variableName}';

  /// Get display name
  String get displayName => '$nodeName/$variableName';

  Map<String, dynamic> toJson() => {
        'node_id': nodeId,
        'node_name': nodeName,
        'variable_name': variableName,
        'data_type': dataType,
        'category': category.name,
        if (description != null) 'description': description,
      };
}

/// Execution status for nodes
enum ExecutionStatus {
  idle,
  running,
  success,
  error,
  skipped;

  String get displayName {
    switch (this) {
      case ExecutionStatus.idle:
        return 'Idle';
      case ExecutionStatus.running:
        return 'Running';
      case ExecutionStatus.success:
        return 'Success';
      case ExecutionStatus.error:
        return 'Error';
      case ExecutionStatus.skipped:
        return 'Skipped';
    }
  }
}

/// Run log for a node execution
class RunLog {
  final String nodeId;
  final String nodeName;
  final DateTime timestamp;
  final ExecutionStatus status;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic>? outputs;
  final String? errorMessage;
  final int? executionTimeMs;
  final int? tokenUsage;

  const RunLog({
    required this.nodeId,
    required this.nodeName,
    required this.timestamp,
    required this.status,
    required this.inputs,
    this.outputs,
    this.errorMessage,
    this.executionTimeMs,
    this.tokenUsage,
  });

  Map<String, dynamic> toJson() => {
        'node_id': nodeId,
        'node_name': nodeName,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'inputs': inputs,
        if (outputs != null) 'outputs': outputs,
        if (errorMessage != null) 'error_message': errorMessage,
        if (executionTimeMs != null) 'execution_time_ms': executionTimeMs,
        if (tokenUsage != null) 'token_usage': tokenUsage,
      };

  factory RunLog.fromJson(Map<String, dynamic> json) {
    return RunLog(
      nodeId: json['node_id'] as String,
      nodeName: json['node_name'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: ExecutionStatus.values.byName(json['status'] as String),
      inputs: json['inputs'] as Map<String, dynamic>,
      outputs: json['outputs'] as Map<String, dynamic>?,
      errorMessage: json['error_message'] as String?,
      executionTimeMs: json['execution_time_ms'] as int?,
      tokenUsage: json['token_usage'] as int?,
    );
  }
}

/// Workflow execution state
class WorkflowExecutionState {
  final bool isRunning;
  final Map<String, ExecutionStatus> nodeStatuses;
  final Map<String, dynamic> cachedVariables;
  final Map<String, RunLog> lastRunLogs;
  final DateTime? startTime;
  final DateTime? endTime;

  const WorkflowExecutionState({
    this.isRunning = false,
    this.nodeStatuses = const {},
    this.cachedVariables = const {},
    this.lastRunLogs = const {},
    this.startTime,
    this.endTime,
  });

  WorkflowExecutionState copyWith({
    bool? isRunning,
    Map<String, ExecutionStatus>? nodeStatuses,
    Map<String, dynamic>? cachedVariables,
    Map<String, RunLog>? lastRunLogs,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return WorkflowExecutionState(
      isRunning: isRunning ?? this.isRunning,
      nodeStatuses: nodeStatuses ?? this.nodeStatuses,
      cachedVariables: cachedVariables ?? this.cachedVariables,
      lastRunLogs: lastRunLogs ?? this.lastRunLogs,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

/// Validation issue
class ValidationIssue {
  final String nodeId;
  final String nodeName;
  final String message;
  final ValidationSeverity severity;

  const ValidationIssue({
    required this.nodeId,
    required this.nodeName,
    required this.message,
    required this.severity,
  });
}

/// Validation severity
enum ValidationSeverity {
  error,
  warning,
  info;

  String get icon {
    switch (this) {
      case ValidationSeverity.error:
        return '✗';
      case ValidationSeverity.warning:
        return '⚠️';
      case ValidationSeverity.info:
        return 'ℹ️';
    }
  }
}

/// Workflow validation result
class ValidationResult {
  final bool isValid;
  final List<ValidationIssue> issues;

  const ValidationResult({
    required this.isValid,
    this.issues = const [],
  });

  bool get hasErrors => issues.any((i) => i.severity == ValidationSeverity.error);
  bool get hasWarnings => issues.any((i) => i.severity == ValidationSeverity.warning);
}
