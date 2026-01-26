import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// The Blackboard Pattern implementation for parallel agent orchestration.
/// 
/// Instead of sequential A -> B chains, agents observe the state and 
/// "post" facts or "request" help.
class BlackboardState {
  final Map<String, dynamic> facts;
  final List<WorkflowTask> tasks;
  final List<WorkflowEvent> events;

  BlackboardState({
    this.facts = const {},
    this.tasks = const [],
    this.events = const [],
  });

  BlackboardState copyWith({
    Map<String, dynamic>? facts,
    List<WorkflowTask>? tasks,
    List<WorkflowEvent>? events,
  }) {
    return BlackboardState(
      facts: facts ?? this.facts,
      tasks: tasks ?? this.tasks,
      events: events ?? this.events,
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
  humanFeedbackNeeded 
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

  void clear() {
    state = BlackboardState();
  }
}

final blackboardProvider = StateNotifierProvider<BlackboardNotifier, BlackboardState>((ref) {
  return BlackboardNotifier();
});
