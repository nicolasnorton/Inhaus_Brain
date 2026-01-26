import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// The Blackboard Pattern implementation for parallel agent orchestration.
/// 
/// Instead of sequential A -> B chains, agents observe the state and 
/// "post" facts or "request" help.

enum BlackboardPhase {
  idle,
  analyzingIntent,
  strategy,
  copywriting,
  creative,
  approval,
  production,
  reviewPending, // Human-in-the-Loop
  userArbitration, // The Gavel
}

enum AgentStatus {
  idle,
  working,
  blocked,
  failed,
}

class BlackboardState {
  final Map<String, dynamic> facts;
  final List<WorkflowTask> tasks;
  final List<WorkflowEvent> events;
  final BlackboardPhase phase;
  final Map<String, AgentStatus> activeAgents;
  final int retryCount; // For The Gavel protocol

  BlackboardState({
    this.facts = const {},
    this.tasks = const [],
    this.events = const [],
    this.phase = BlackboardPhase.idle,
    this.activeAgents = const {},
    this.retryCount = 0,
  });

  BlackboardState copyWith({
    Map<String, dynamic>? facts,
    List<WorkflowTask>? tasks,
    List<WorkflowEvent>? events,
    BlackboardPhase? phase,
    Map<String, AgentStatus>? activeAgents,
    int? retryCount,
  }) {
    return BlackboardState(
      facts: facts ?? this.facts,
      tasks: tasks ?? this.tasks,
      events: events ?? this.events,
      phase: phase ?? this.phase,
      activeAgents: activeAgents ?? this.activeAgents,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

enum TaskStatus { pending, inProgress, completed, failed }

class WorkflowTask {
  final String id;
  final String title;
  final String requiredCapability; // e.g., 'research', 'copywriting'
  final TaskStatus status;
  final Map<String, dynamic> result;
  final List<String> dependencies; // IDs of tasks that must finish first

  WorkflowTask({
    required this.id,
    required this.title,
    required this.requiredCapability,
    this.status = TaskStatus.pending,
    this.result = const {},
    this.dependencies = const [],
  });
}

enum WorkflowEventType { 
  userRequested, 
  taskFinished, 
  errorOccurred, 
  humanFeedbackNeeded,
  phaseTransition,
  agentStatusChange
}

class WorkflowEvent {
  final String id;
  final WorkflowEventType type;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WorkflowEvent({
    required this.id,
    required this.type,
    required this.message,
    this.data = const {},
    required this.timestamp,
  });
}

class BlackboardNotifier extends StateNotifier<BlackboardState> {
  BlackboardNotifier() : super(BlackboardState());

  void postFact(String key, dynamic value) {
    state = state.copyWith(
      facts: {...state.facts, key: value},
    );
  }

  void addEvent(WorkflowEventType type, String message, {Map<String, dynamic> data = const {}}) {
    final event = WorkflowEvent(
      id: const Uuid().v4(),
      type: type,
      message: message,
      data: data,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(events: [...state.events, event]);
  }

  void transitionTo(BlackboardPhase nextPhase) {
    if (state.phase == nextPhase) return;
    
    // Simple state transition validation could go here
    // For now, we allow flexible transitions but log them
    
    state = state.copyWith(phase: nextPhase);
    addEvent(
      WorkflowEventType.phaseTransition, 
      "Phase transitioned to ${nextPhase.name}",
      data: {'from': state.phase.name, 'to': nextPhase.name}
    );
  }

  void updateAgentStatus(String agentName, AgentStatus status) {
    final updatedAgents = Map<String, AgentStatus>.from(state.activeAgents);
    updatedAgents[agentName] = status;
    
    state = state.copyWith(activeAgents: updatedAgents);
    addEvent(
      WorkflowEventType.agentStatusChange, 
      "$agentName is now ${status.name}",
      data: {'agent': agentName, 'status': status.name}
    );
  }

  void finishTask(String id, Map<String, dynamic> result) {
    state = state.copyWith(
      tasks: state.tasks.map((t) => t.id == id 
        ? WorkflowTask(
            id: t.id, 
            title: t.title, 
            requiredCapability: t.requiredCapability, 
            status: TaskStatus.completed, 
            result: result, 
            dependencies: t.dependencies
          ) 
        : t
      ).toList()
    );
    addEvent(WorkflowEventType.taskFinished, "Completed: $id", data: {'taskId': id});
  }

  void incrementRetry() {
    state = state.copyWith(retryCount: state.retryCount + 1);
  }

  void resetRetry() {
    state = state.copyWith(retryCount: 0);
  }

  void clear() {
    state = BlackboardState();
  }
}

final blackboardProvider = StateNotifierProvider<BlackboardNotifier, BlackboardState>((ref) {
  return BlackboardNotifier();
});
