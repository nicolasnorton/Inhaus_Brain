import 'package:flutter/foundation.dart';

/// Tiered Context Memory structure based on the First Principles Audit.
/// 
/// Helps prevent "Context Bloat" and reduces latency by only passing relevant tokens.
class AgentMemory {
  /// Long-term project goals and high-level constraints.
  /// Shared across all agents in the workspace.
  final GlobalContext globalContext;

  /// The active task data. Passed only to the currently executing agent.
  /// Cleared when a workflow step completes.
  final WorkingMemory workingMemory;

  /// High-level summaries of past decisions and past campaign insights.
  /// Retrieved via vector search (if implemented) or summarized logs.
  final List<EpisodicFragment> episodicMemory;

  AgentMemory({
    required this.globalContext,
    required this.workingMemory,
    this.episodicMemory = const [],
  });

  /// Assembles a system prompt component from the tiered memory.
  String toSystemPromptFragment() {
    final buffer = StringBuffer();
    
    buffer.writeln("## Global Project Context");
    buffer.writeln(globalContext.description);
    
    if (workingMemory.isActive) {
      buffer.writeln("\n## Active Task Working Memory");
      buffer.writeln(workingMemory.currentTaskData);
    }
    
    if (episodicMemory.isNotEmpty) {
      buffer.writeln("\n## Relevant Insights (Episodic Memory)");
      for (var fragment in episodicMemory) {
        buffer.writeln("- ${fragment.summary}");
      }
    }
    
    return buffer.toString();
  }
}

class GlobalContext {
  final String projectName;
  final String description;
  final Map<String, dynamic> brandGuidelines;
  final List<String> primaryObjectives;

  GlobalContext({
    required this.projectName,
    required this.description,
    this.brandGuidelines = const {},
    this.primaryObjectives = const [],
  });
}

class WorkingMemory {
  final String currentTaskId;
  final String currentTaskData;
  final bool isActive;
  final DateTime? startedAt;

  WorkingMemory({
    required this.currentTaskId,
    required this.currentTaskData,
    this.isActive = true,
    this.startedAt,
  });

  static WorkingMemory empty() => WorkingMemory(currentTaskId: '', currentTaskData: '', isActive: false);
}

class EpisodicFragment {
  final String id;
  final String summary;
  final double relevanceScore;
  final DateTime timestamp;

  EpisodicFragment({
    required this.id,
    required this.summary,
    required this.relevanceScore,
    required this.timestamp,
  });
}
