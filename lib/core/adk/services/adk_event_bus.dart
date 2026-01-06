import 'dart:async';
import '../models/adk_artifact.dart';

enum AdkEventType {
  agentStarted,
  agentThinking,
  agentArtifactGenerated,
  agentCompleted,
  agentError,
  toolStarted,
  toolCompleted,
  pipelineStarted,
  pipelineCompleted,
}

class AdkEvent {
  final AdkEventType type;
  final String source; // Agent name or Pipeline ID
  final String? message;
  final AdkArtifact? artifact;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  AdkEvent({
    required this.type,
    required this.source,
    this.message,
    this.artifact,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => "[$timestamp] $source: $type ${message ?? ''}";
}

/// A centralized singleton/provider for ADK events.
/// This enables the UI to react to agent thoughts, tool usage, etc.
class AdkEventBus {
  static final AdkEventBus _instance = AdkEventBus._internal();
  factory AdkEventBus() => _instance;
  AdkEventBus._internal();

  final _controller = StreamController<AdkEvent>.broadcast();

  Stream<AdkEvent> get events => _controller.stream;

  void publish(AdkEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
