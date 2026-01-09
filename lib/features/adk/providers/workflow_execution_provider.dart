import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workflow_execution_models.dart';

/// Provider for workflow execution state
final workflowExecutionProvider =
    StateNotifierProvider<WorkflowExecutionNotifier, WorkflowExecutionState>((ref) {
  return WorkflowExecutionNotifier();
});

/// Provider for available variables in the workflow
final availableVariablesProvider = StateProvider<List<VariableReference>>((ref) => []);

/// Provider for cached variables
final cachedVariablesProvider = StateProvider<Map<String, dynamic>>((ref) => {});

/// Provider for last run logs
final lastRunLogsProvider = StateProvider<Map<String, RunLog>>((ref) => {});

/// Provider for node execution statuses
final nodeExecutionStatusProvider = StateProvider<Map<String, ExecutionStatus>>((ref) => {});

/// Provider for validation result
final validationResultProvider = StateProvider<ValidationResult?>((ref) => null);

/// State notifier for workflow execution
class WorkflowExecutionNotifier extends StateNotifier<WorkflowExecutionState> {
  WorkflowExecutionNotifier() : super(const WorkflowExecutionState());

  /// Start workflow execution
  void startExecution() {
    state = state.copyWith(
      isRunning: true,
      startTime: DateTime.now(),
      endTime: null,
    );
  }

  /// End workflow execution
  void endExecution() {
    state = state.copyWith(
      isRunning: false,
      endTime: DateTime.now(),
    );
  }

  /// Update node status
  void updateNodeStatus(String nodeId, ExecutionStatus status) {
    final updatedStatuses = Map<String, ExecutionStatus>.from(state.nodeStatuses);
    updatedStatuses[nodeId] = status;
    state = state.copyWith(nodeStatuses: updatedStatuses);
  }

  /// Update cached variable
  void updateCachedVariable(String key, dynamic value) {
    final updatedCache = Map<String, dynamic>.from(state.cachedVariables);
    updatedCache[key] = value;
    state = state.copyWith(cachedVariables: updatedCache);
  }

  /// Add run log
  void addRunLog(RunLog log) {
    final updatedLogs = Map<String, RunLog>.from(state.lastRunLogs);
    updatedLogs[log.nodeId] = log;
    state = state.copyWith(lastRunLogs: updatedLogs);
  }

  /// Clear execution state
  void clear() {
    state = const WorkflowExecutionState();
  }

  /// Reset node statuses
  void resetNodeStatuses() {
    state = state.copyWith(nodeStatuses: {});
  }
}
