/// ContextAssembler — Central context assembly service.
///
/// Replaces ad-hoc context construction scattered across every agent.
/// Assembles a structured, token-budgeted context window from:
///
/// 1. **Global context** – project, brand guidelines
/// 2. **Conversation history** – structured, last N turns
/// 3. **Episodic memory** – top-K BrainWeave results for the current query
/// 4. **Working memory** – current task state from Blackboard
/// 5. **Knowledge sources** – attached documents
///
/// Competitive parity:
/// - Claude Workspace: Persistent memory + 1M token context
/// - Grok 4.2 Heavy: 2M token context window
/// - Google ADK 2.0: Session state + RAG integration
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/knowledge/models/knowledge_source.dart';
import '../../features/brainweave/services/brainweave_mcp_client.dart';
import '../architecture/blackboard.dart';
import '../architecture/memory.dart';
import '../config/app_environment.dart';
import '../services/memory_service.dart';

/// Record of a single conversation turn.
class ConversationTurn {
  final String role; // 'user', 'agent', 'tool'
  final String content;
  final String? agentName;
  final DateTime timestamp;

  const ConversationTurn({
    required this.role,
    required this.content,
    this.agentName,
    required this.timestamp,
  });

  String toPromptLine() {
    final prefix = agentName != null ? '[$agentName]' : '[${role.toUpperCase()}]';
    return '$prefix: $content';
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    if (agentName != null) 'agentName': agentName,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Assembled context ready for injection into an agent's system prompt.
class AssembledContext {
  final String systemPromptFragment;
  final List<EpisodicFragment> episodicMemories;
  final List<ConversationTurn> recentHistory;
  final int estimatedTokens;

  const AssembledContext({
    required this.systemPromptFragment,
    this.episodicMemories = const [],
    this.recentHistory = const [],
    this.estimatedTokens = 0,
  });
}

/// Central service that assembles the full context for any agent call.
class ContextAssembler {
  final Ref _ref;

  /// In-memory conversation history buffer (per session).
  final List<ConversationTurn> _conversationHistory = [];

  /// Maximum conversation turns to include in context.
  static const int _maxHistoryTurns = 20;

  /// Maximum episodic memories to retrieve.
  static const int _maxEpisodicResults = 5;

  /// Approximate token budget (chars / 4 as rough estimate).
  /// Gemini 3.x supports 1M tokens but we target ~32K for working context.
  static const int _tokenBudget = 32000;

  ContextAssembler(this._ref);

  /// Add a conversation turn to the session history.
  void addTurn(ConversationTurn turn) {
    _conversationHistory.add(turn);
    // Trim to last N turns
    if (_conversationHistory.length > _maxHistoryTurns * 2) {
      _conversationHistory.removeRange(0, _conversationHistory.length - _maxHistoryTurns * 2);
    }
  }

  /// Add a user message to the conversation history.
  void addUserMessage(String content) {
    addTurn(ConversationTurn(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    ));
  }

  /// Add an agent response to the conversation history.
  void addAgentResponse(String agentName, String content) {
    addTurn(ConversationTurn(
      role: 'agent',
      content: content,
      agentName: agentName,
      timestamp: DateTime.now(),
    ));
  }

  /// Get the current conversation history.
  List<ConversationTurn> get history => List.unmodifiable(_conversationHistory);

  /// Clear conversation history (e.g., on new session).
  void clearHistory() => _conversationHistory.clear();

  /// Assemble the full context for an agent call.
  ///
  /// This is the main entry point. It gathers all context layers,
  /// respects the token budget, and returns a formatted system prompt fragment.
  Future<AssembledContext> assemble({
    required String currentQuery,
    required String agentName,
    List<KnowledgeSource> attachedKnowledge = const [],
    String? campaignId,
  }) async {
    final buffer = StringBuffer();
    int estimatedTokens = 0;

    // ── Layer 1: Global Context ──
    final globalFragment = _buildGlobalContext(campaignId: campaignId);
    if (globalFragment.isNotEmpty) {
      buffer.writeln(globalFragment);
      estimatedTokens += globalFragment.length ~/ 4;
    }

    // ── Layer 2: Conversation History ──
    final historyFragment = _buildConversationHistory();
    if (historyFragment.isNotEmpty && estimatedTokens + historyFragment.length ~/ 4 < _tokenBudget) {
      buffer.writeln(historyFragment);
      estimatedTokens += historyFragment.length ~/ 4;
    }

    // ── Layer 3: Episodic Memory (BrainWeave vector search) ──
    List<EpisodicFragment> episodicMemories = [];
    if (AppConfig.brainweaveV2Enabled) {
      episodicMemories = await _retrieveEpisodicMemory(currentQuery);
      if (episodicMemories.isNotEmpty) {
        final episodicFragment = _buildEpisodicFragment(episodicMemories);
        if (estimatedTokens + episodicFragment.length ~/ 4 < _tokenBudget) {
          buffer.writeln(episodicFragment);
          estimatedTokens += episodicFragment.length ~/ 4;
        }
      }
    }

    // ── Layer 4: Working Memory (Blackboard state) ──
    final workingFragment = _buildWorkingMemory();
    if (workingFragment.isNotEmpty && estimatedTokens + workingFragment.length ~/ 4 < _tokenBudget) {
      buffer.writeln(workingFragment);
      estimatedTokens += workingFragment.length ~/ 4;
    }

    // ── Layer 5: Remembered Facts (MemoryService) ──
    final memoryContext = _buildRememberedFacts(campaignId: campaignId);
    if (memoryContext.isNotEmpty && estimatedTokens + memoryContext.length ~/ 4 < _tokenBudget) {
      buffer.writeln(memoryContext);
      estimatedTokens += memoryContext.length ~/ 4;
    }

    // ── Layer 6: Attached Knowledge Sources ──
    if (attachedKnowledge.isNotEmpty) {
      final knowledgeFragment = _buildKnowledgeFragment(attachedKnowledge, _tokenBudget - estimatedTokens);
      buffer.writeln(knowledgeFragment);
      estimatedTokens += knowledgeFragment.length ~/ 4;
    }

    final recentTurns = _conversationHistory.length > _maxHistoryTurns
        ? _conversationHistory.sublist(_conversationHistory.length - _maxHistoryTurns)
        : List<ConversationTurn>.from(_conversationHistory);

    return AssembledContext(
      systemPromptFragment: buffer.toString(),
      episodicMemories: episodicMemories,
      recentHistory: recentTurns,
      estimatedTokens: estimatedTokens,
    );
  }

  // ─── Layer Builders ───────────────────────────────────────

  String _buildGlobalContext({String? campaignId}) {
    final memoryService = _ref.read(memoryServiceProvider);
    final contextStr = memoryService.getContextString(campaignId: campaignId);
    if (contextStr.isEmpty) return '';
    return '## Global Context\n$contextStr';
  }

  String _buildConversationHistory() {
    if (_conversationHistory.isEmpty) return '';

    final recentTurns = _conversationHistory.length > _maxHistoryTurns
        ? _conversationHistory.sublist(_conversationHistory.length - _maxHistoryTurns)
        : _conversationHistory;

    final lines = recentTurns.map((t) => t.toPromptLine()).join('\n');
    return '## Recent Conversation\n$lines';
  }

  Future<List<EpisodicFragment>> _retrieveEpisodicMemory(String query) async {
    try {
      final mcpClient = _ref.read(brainweaveMcpClientProvider);
      final results = await mcpClient.graphQuery(
        query: query,
        limit: _maxEpisodicResults,
      ).timeout(const Duration(seconds: 10));

      return results.map((r) => EpisodicFragment(
        id: r['id'] as String? ?? '',
        summary: '${r['title'] ?? ''}: ${r['content'] ?? r['description'] ?? ''}',
        relevanceScore: (r['similarity'] as num?)?.toDouble() ?? 0.5,
        timestamp: DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
      )).where((f) => f.relevanceScore > 0.3).toList();
    } catch (e) {
      debugPrint('ContextAssembler: Episodic memory retrieval failed: $e');
      return [];
    }
  }

  String _buildEpisodicFragment(List<EpisodicFragment> fragments) {
    if (fragments.isEmpty) return '';

    final lines = fragments
        .map((f) => '- [${(f.relevanceScore * 100).toInt()}% relevant] ${f.summary}')
        .join('\n');
    return '## Relevant Knowledge (from Memory)\n$lines';
  }

  String _buildWorkingMemory() {
    try {
      final blackboard = _ref.read(blackboardProvider);
      final facts = blackboard.facts;
      if (facts.isEmpty) return '';

      final factLines = facts.entries
          .where((e) => e.value != null)
          .take(10) // Limit facts to prevent bloat
          .map((e) => '- ${e.key}: ${_truncate(e.value.toString(), 200)}')
          .join('\n');

      return '## Working Memory (Current Session)\n$factLines';
    } catch (e) {
      return '';
    }
  }

  String _buildRememberedFacts({String? campaignId}) {
    final memoryService = _ref.read(memoryServiceProvider);
    final memories = campaignId != null
        ? memoryService.getMemoriesForCampaign(campaignId)
        : memoryService.memory;

    if (memories.isEmpty) return '';

    final lines = memories
        .take(15)
        .map((m) => '- ${m.key}: ${_truncate(m.value, 150)}')
        .join('\n');
    return '## Remembered Facts & Preferences\n$lines';
  }

  String _buildKnowledgeFragment(List<KnowledgeSource> sources, int remainingTokenBudget) {
    if (sources.isEmpty) return '';

    final buffer = StringBuffer('## Attached Knowledge\n');
    int used = 0;

    for (final source in sources) {
      final entry = '### ${source.title}\n${source.content}\n';
      final entryTokens = entry.length ~/ 4;
      if (used + entryTokens > remainingTokenBudget) {
        // Truncate this source to fit
        final availableChars = (remainingTokenBudget - used) * 4;
        if (availableChars > 200) {
          buffer.writeln('### ${source.title}');
          buffer.writeln(_truncate(source.content, availableChars));
        }
        break;
      }
      buffer.writeln(entry);
      used += entryTokens;
    }

    return buffer.toString();
  }

  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Save an agent's execution as an episodic memory in BrainWeave.
  ///
  /// Called automatically after each agent execution to build the
  /// persistent episodic memory layer.
  Future<void> saveEpisode({
    required String agentName,
    required String taskSummary,
    required String output,
    String? campaignId,
  }) async {
    if (!AppConfig.brainweaveV2Enabled) return;

    try {
      final mcpClient = _ref.read(brainweaveMcpClientProvider);
      await mcpClient.create(
        title: '[$agentName] $taskSummary',
        content: _truncate(output, 2000),
        nodeType: 'episodic',
        topics: ['agent_memory', agentName.toLowerCase().replaceAll(' ', '_')],
        sourceAgent: agentName,
        metadata: {
          'type': 'agent_episode',
          'agent': agentName,
          'timestamp': DateTime.now().toIso8601String(),
          if (campaignId != null) 'campaign_id': campaignId,
        },
      );
      debugPrint('ContextAssembler: Saved episode for $agentName');
    } catch (e) {
      debugPrint('ContextAssembler: Failed to save episode: $e');
    }
  }
}

// ─── Riverpod Provider ────────────────────────────────────────────

final contextAssemblerProvider = Provider<ContextAssembler>((ref) {
  return ContextAssembler(ref);
});
