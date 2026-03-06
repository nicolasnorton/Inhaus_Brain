import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/brainweave/services/brainweave_mcp_client.dart';
import '../config/feature_flags.dart';

class ToolExecutor {
  final Ref _ref;

  ToolExecutor(this._ref);

  /// PreToolUse Hook (BrainWeave 2.1)
  /// Automatically injects relevant Graph context into the LLM system prompt
  /// right before execution. This ensures the agent has up-to-date knowledge
  /// of the subgraph relevant to the user's prompt without a dedicated RAG step.
  Future<String> injectGraphContextIfNeeded(String systemPrompt, String userPrompt) async {
    if (!FeatureFlags.brainweave21Enabled) {
      return systemPrompt;
    }

    try {
      final mcpClient = _ref.read(brainweaveMcpClientProvider);
      
      // We do a lightweight context fetch
      final results = await mcpClient.graphQuery(
        query: userPrompt,
        limit: 5,
      );
      final contextJson = jsonEncode(results);

      final enrichedPrompt = '''
$systemPrompt

[BRAINWEAVE GRAPH CONTEXT (Auto-Injected PreToolUse)]
The following nodes/edges are currently relevant to the user request. Incorporate this knowledge when using tools:
$contextJson
''';
      return enrichedPrompt;

    } catch (e) {
      // If the graph query fails, we silently fail open and just return original prompt
      return systemPrompt;
    }
  }
}

final toolExecutorProvider = Provider<ToolExecutor>((ref) => ToolExecutor(ref));
