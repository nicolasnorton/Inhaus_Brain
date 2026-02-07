import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_agent.dart';
import '../models/chat_models.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart'; // Import for AIModelConfig
import '../../../core/adk/services/adk_event_bus.dart';

class KnowledgeLibrarianAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.knowledgeLibrarianAgent;
  
  @override
  String get name => "Knowledge Librarian";
  
  @override
  String get systemPromptKey => "librarian_agent_prompt";

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
1. Identify outdated or redundant information.
2. Suggest categorizations (Datasets) for new knowledge snippets.
3. Cross-reference related documents to build a richer context.
4. Summarize long documents for faster retrieval.

When given project/client updates, analyze how they impact existing knowledge and suggest updates.
""";
    
    final result = (await EdgeAIService.generateText(
      "$systemInstruction\n\nInput: $userPrompt",
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
    )).text;
    
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return result;
  }
}
