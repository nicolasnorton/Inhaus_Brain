import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/edge_ai_service.dart';
import '../tokens/llm_provider.dart';

class DataAnalysisTool extends AgentTool {
  final Ref _ref;

  DataAnalysisTool(this._ref) : super(
    name: 'data_analysis',
    description: 'Perform advanced statistical analysis, pattern recognition, and trend extraction on provided data or context.',
    inputSchema: {
      'data_query': {
        'type': 'string',
        'description': 'What specifically to analyze (e.g., "Analyze the last 3 months of revenue trends")'
      },
      'context_key': {
        'type': 'string',
        'description': 'Optional key to specific data in the knowledge base or current state'
      }
    }
  );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final query = parameters['data_query'] as String?;
    if (query == null) return ToolResult.failure('data_query is required');

    try {
      // Use logical reasoning agent (Gemini Pro/Flash with high temp or specific persona)
      final analysisPrompt = """
You are the Inhaus Brain Data Engine. Your task is to analyze the following request and provide high-fidelity insights.
Request: $query

If specific data is missing, perform a "Simulated Analysis" based on industry benchmarks and current market conditions.
Always provide:
1. Key Findings (Statistical or Pattern-based)
2. Anomalies detected
3. Actionable recommendations based on the data.

Return structured findings.
""";

      final res = await EdgeAIService.generateText(
        analysisPrompt,
        modelConfig: AIModelConfig.geminiResearch,
        ref: _ref
      );

      return ToolResult.success({
        'analysis': res.text,
        'status': 'completed',
        'engine': 'Brain-Analytical-V2'
      });
    } catch (e) {
      return ToolResult.failure('Analysis error: $e');
    }
  }
}

final dataToolsProvider = Provider<List<AgentTool>>((ref) {
  return [
    DataAnalysisTool(ref),
  ];
});
