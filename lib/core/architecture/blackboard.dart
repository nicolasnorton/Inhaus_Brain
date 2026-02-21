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
  final String? sessionId;
  final int retryCount; // For The Gavel protocol
  final DateTime lastUpdated;

  BlackboardState({
    this.facts = const {},
    this.tasks = const [],
    this.events = const [],
    this.phase = BlackboardPhase.idle,
    this.activeAgents = const {},
    this.sessionId = 'assistant_global',
    this.retryCount = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  BlackboardState copyWith({
    Map<String, dynamic>? facts,
    List<WorkflowTask>? tasks,
    List<WorkflowEvent>? events,
    BlackboardPhase? phase,
    Map<String, AgentStatus>? activeAgents,
    String? sessionId,
    int? retryCount,
    DateTime? lastUpdated,
  }) {
    return BlackboardState(
      facts: facts ?? this.facts,
      tasks: tasks ?? this.tasks,
      events: events ?? this.events,
      phase: phase ?? this.phase,
      activeAgents: activeAgents ?? this.activeAgents,
      sessionId: sessionId ?? this.sessionId,
      retryCount: retryCount ?? this.retryCount,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facts': facts,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'phase': phase.name,
      'activeAgents': activeAgents.map((key, value) => MapEntry(key, value.name)),
      'sessionId': sessionId,
      'retryCount': retryCount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory BlackboardState.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is String) return DateTime.parse(d);
      if (d.runtimeType.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp without a direct dependency if possible
        // or just rely on dynamic access if we know it's there.
        try {
          return (d as dynamic).toDate();
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return BlackboardState(
      facts: json['facts'] ?? {},
      tasks: (json['tasks'] as List?)?.map((t) => WorkflowTask.fromJson(t)).toList() ?? [],
      events: (json['events'] as List?)?.map((e) => WorkflowEvent.fromJson(e)).toList() ?? [],
      phase: BlackboardPhase.values.firstWhere((e) => e.name == json['phase'], orElse: () => BlackboardPhase.idle),
      activeAgents: (json['activeAgents'] as Map?)?.map((key, value) => 
          MapEntry(key as String, AgentStatus.values.firstWhere((e) => e.name == value, orElse: () => AgentStatus.idle))) ?? {},
      sessionId: json['sessionId'],
      retryCount: json['retryCount'] ?? 0,
      lastUpdated: parseDate(json['lastUpdated']),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'requiredCapability': requiredCapability,
      'status': status.name,
      'result': result,
      'dependencies': dependencies,
    };
  }

  factory WorkflowTask.fromJson(Map<String, dynamic> json) {
    return WorkflowTask(
      id: json['id'],
      title: json['title'],
      requiredCapability: json['requiredCapability'],
      status: TaskStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => TaskStatus.pending),
      result: json['result'] ?? {},
      dependencies: List<String>.from(json['dependencies'] ?? []),
    );
  }
}

enum WorkflowEventType { 
  userRequested, 
  taskFinished, 
  errorOccurred, 
  humanFeedbackNeeded,
  phaseTransition,
  agentStatusChange,
  agentAction,
  agentFinished
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'message': message,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WorkflowEvent.fromJson(Map<String, dynamic> json) {
    return WorkflowEvent(
      id: json['id'],
      type: WorkflowEventType.values.firstWhere((e) => e.name == json['type'], orElse: () => WorkflowEventType.agentAction),
      message: json['message'],
      data: json['data'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class BlackboardNotifier extends StateNotifier<BlackboardState> {
  BlackboardNotifier() : super(BlackboardState());

  /// Maximum number of events to keep in memory.
  /// Prevents unbounded growth in long-running sessions.
  static const int maxEvents = 200;

  /// Stale session timeout (30 minutes of inactivity).
  static const Duration staleTimeout = Duration(minutes: 30);

  /// Last activity timestamp for stale detection.
  DateTime _lastActivity = DateTime.now();

  /// Check if session is stale and auto-clear if needed.
  /// Returns true if session was reset.
  bool _checkStale() {
    if (state.phase != BlackboardPhase.idle &&
        DateTime.now().difference(_lastActivity) > staleTimeout) {
      // Session was abandoned — clear to prevent stale data
      state = BlackboardState();
      _lastActivity = DateTime.now();
      return true;
    }
    return false;
  }

  /// Touch activity timestamp.
  void _touch() => _lastActivity = DateTime.now();

  void postFact(String key, dynamic value) {
    _checkStale();
    _touch();
    state = state.copyWith(
      facts: {...state.facts, key: value},
    );
  }

  void addEvent(WorkflowEventType type, String message, {Map<String, dynamic> data = const {}}) {
    _checkStale();
    _touch();
    final event = WorkflowEvent(
      id: const Uuid().v4(),
      type: type,
      message: message,
      data: data,
      timestamp: DateTime.now(),
    );
    var events = [...state.events, event];
    // Cap events to prevent unbounded growth
    if (events.length > maxEvents) {
      events = events.sublist(events.length - maxEvents);
    }
    state = state.copyWith(events: events);
  }

  void restoreState(BlackboardState newState) {
    state = newState;
    // Log restoration event without triggering new persistence loop immediately
    // Or just silently restore. 
    // Let's create an event to mark restoration.
    addEvent(
      WorkflowEventType.agentAction, 
      "Session Restored from Persistence",
      data: {'timestamp': DateTime.now().toIso8601String()}
    );
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

  void initialize(String sessionId) {
    state = BlackboardState(sessionId: sessionId);
    _lastActivity = DateTime.now();
  }

  void clear({String? sessionId}) {
    state = BlackboardState(sessionId: sessionId ?? state.sessionId);
  }
}

final blackboardProvider = StateNotifierProvider<BlackboardNotifier, BlackboardState>((ref) {
  return BlackboardNotifier();
});
