import 'context_assembler.dart';

/// Tiered Context Memory structure based on the First Principles Audit.
/// 
/// Helps prevent "Context Bloat" and reduces latency by only passing relevant tokens.
///
/// March 2026 upgrade: Now integrates with [ContextAssembler] for automatic
/// episodic memory population via BrainWeave vector search.
class AgentMemory {
  /// Long-term project goals and high-level constraints.
  /// Shared across all agents in the workspace.
  final GlobalContext globalContext;

  /// The active task data. Passed only to the currently executing agent.
  /// Cleared when a workflow step completes.
  final WorkingMemory workingMemory;

  /// High-level summaries of past decisions and past campaign insights.
  /// Now populated automatically via BrainWeave vector search through [ContextAssembler].
  final List<EpisodicFragment> episodicMemory;

  /// Structured conversation history for multi-turn context.
  final List<ConversationTurn> conversationHistory;

  AgentMemory({
    required this.globalContext,
    required this.workingMemory,
    this.episodicMemory = const [],
    this.conversationHistory = const [],
  });

  /// Create an AgentMemory from a [ContextAssembler] result.
  /// This is the March 2026 standard way to build memory for agents.
  factory AgentMemory.fromAssembledContext(AssembledContext assembled) {
    return AgentMemory(
      globalContext: GlobalContext(
        projectName: 'InhausBrain',
        description: assembled.systemPromptFragment,
      ),
      workingMemory: WorkingMemory.empty(),
      episodicMemory: assembled.episodicMemories,
      conversationHistory: assembled.recentHistory,
    );
  }

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
        buffer.writeln("- [${(fragment.relevanceScore * 100).toInt()}%] ${fragment.summary}");
      }
    }

    if (conversationHistory.isNotEmpty) {
      buffer.writeln("\n## Recent Conversation");
      final recent = conversationHistory.length > 10
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory;
      for (var turn in recent) {
        buffer.writeln(turn.toPromptLine());
      }
    }
    
    return buffer.toString();
  }

  /// Estimated token count for this memory block.
  int get estimatedTokens => toSystemPromptFragment().length ~/ 4;
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
  final String? sourceAgent;
  final String? nodeType;

  EpisodicFragment({
    required this.id,
    required this.summary,
    required this.relevanceScore,
    required this.timestamp,
    this.sourceAgent,
    this.nodeType,
  });
}

