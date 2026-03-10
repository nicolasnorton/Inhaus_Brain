import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_agent.dart';
import '../models/chat_models.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart'; // Import for AIModelConfig
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/mcp/agent_tool.dart'; // REQUIRED FOR: AgentTool
import 'tools/brainweave_tools.dart';

class KnowledgeLibrarianAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.knowledgeLibrarianAgent;
  
  @override
  String get name => "Knowledge Librarian";
  
  @override
  String get systemPromptKey => "librarian_agent_prompt";

  @override
  List<AgentTool> get tools => [
        QueryBrainWeaveTool(),
        MeetingSyncTool(),
        AnnotateTool(),
        FeedbackTool(),
        GetExternalDocTool(),
        GetNodeContextTool(),
        CreateAtomicNodeTool(),
        PromoteNodeTool(),
        WikiGenerateTool(),
      ];

  @override
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
    Function(AdkEvent)? onEvent,
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    
    final systemInstruction = systemPrompt ?? """
You are the Inhaus Knowledge Librarian. Your goal is to monitor, update, enrich, and organize the knowledge module autonomously.

Tasks:
1. Identify outdated or redundant information in BrainWeave.
2. If you find highly valuable 'PRIVATE' or 'CLIENT' node information that would benefit the entire agency, use the `promote_node` tool to request AGENCY scope.
3. Suggest categorizations (Datasets) for new knowledge snippets.
4. Cross-reference related documents to build a richer context using `get_node_context`.

When given project/client updates, analyze how they impact existing knowledge and suggest updates.
""";
    
    final result = (await EdgeAIService.generateText(
      "$systemInstruction\n\nInput: $userPrompt",
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
      tools: tools.map((t) => t.toFunctionSchema()).toList(),
    )).text;
    
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return result;
  }
}
