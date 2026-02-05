import '../../../core/mcp/agent_tool.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import 'base_agent.dart';
import '../../knowledge/models/knowledge_source.dart';

/// Adapter that allows any [BaseAgent] to be used as an [AgentTool]
/// This enables the "Agent-as-a-Tool" pattern from the Google ADK maturity roadmap.
class AgentToolAdapter extends AgentTool {
  final BaseAgent agent;
  final String? apiKey;
  final String? gemmaKey;
  final String priority;

  AgentToolAdapter({
    required this.agent,
    this.apiKey,
    this.gemmaKey,
    this.priority = 'normal',
  }) : super(
         name: agent.name.replaceAll(' ', '_').toLowerCase(),
         description: "A specialized agent for ${agent.name} tasks. Input is the specific query or task for this agent.",
         inputSchema: {
           'query': {
             'type': 'string',
             'description': 'The prompt or instruction for the agent.',
           },
         },
       );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final query = parameters['query'] as String?;
    if (query == null || query.isEmpty) {
      return ToolResult.failure('Missing required parameter: query');
    }
    
    // Attempt to extract context if provided in parameters (optional)
    final context = (parameters['context'] as List?)?.map((c) => c as KnowledgeSource).toList() ?? [];

    try {
      final result = await agent.execute(
        userPrompt: query,
        context: context,
        apiKey: apiKey,
        gemmaKey: gemmaKey,
        onEvent: (e) => AdkEventBus().publish(e), // Relay events to the bus
        ref: ref,
      );
      return ToolResult.success({'response': result});
    } catch (e) {
      return ToolResult.failure('Agent execution failed: $e');
    }
  }
}
