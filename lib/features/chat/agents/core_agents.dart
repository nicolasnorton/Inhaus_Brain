import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../agents/base_agent.dart';
import '../models/chat_models.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/mcp/tools/web_search_tool.dart';
import '../../../core/adk/services/adk_event_bus.dart';

class ResearchAgent extends BaseAgent {
  @override
  String get name => "Research Agent";
  @override
  MessageSender get type => MessageSender.researchAgent;
  @override
  String get systemPromptKey => "research_prompt";

  @override
  List<AgentTool> get tools => [WebSearchTool()];

  @override
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    String? apiKey,
    String? gemmaKey,
    Uint8List? imageBytes,
    String? imageMimeType,
    Function(AdkEvent)? onEvent,
    Ref? ref,
  }) async {
    onEvent?.call(AdkEvent(
      type: AdkEventType.agentStarted,
      source: name,
      message: "Researching: $userPrompt",
    ));

    // 1. Perform Research (Using Unified Tool Interface)
    final searchTool = tools.firstWhere((t) => t.name == 'web_search');
    final result = await searchTool.execute({'query': userPrompt});
    
    String researchSummary = "";
    if (result.isSuccess) {
      final results = result.data['results'] as List;
      researchSummary = results.map((r) => "- ${r['title']}: ${r['snippet']}").join("\n");
    } else {
      researchSummary = "Search failed: ${result.errorMessage}";
    }
    
    // Use dynamic prompt if provided, otherwise default
    final promptTemplate = systemPrompt ?? "You are a Research Agent. User Request: '{{userPrompt}}'. Research Findings: {{researchSummary}}. Synthesize these findings into a clear, strategic answer.";
    final systemInstruction = promptTemplate
        .replaceAll('{{userPrompt}}', userPrompt)
        .replaceAll('{{researchSummary}}', researchSummary);

    // 2. AI Generation Grounded in Research
    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
    );
    
    onEvent?.call(AdkEvent(
      type: AdkEventType.agentCompleted,
      source: name,
      message: "Research complete.",
    ));
    
    return aiRes.text;
  }
}

class CreativeAgent extends BaseAgent {
  @override
  String get name => "Creative Agent";
  @override
  MessageSender get type => MessageSender.creativeAgent;
  @override
  String get systemPromptKey => "creative_prompt";

  @override
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    String? apiKey,
    String? gemmaKey,
    Uint8List? imageBytes,
    String? imageMimeType,
    Function(AdkEvent)? onEvent,
    Ref? ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final systemInstruction = systemPrompt ?? "You are a Creative Agent. Suggest a visual direction or concept for: $userPrompt.";

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
    );

    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return aiRes.text;
  }
}

class CopywriterAgent extends BaseAgent {
  @override
  String get name => "Copywriter Agent";
  @override
  MessageSender get type => MessageSender.copywriterAgent;
  @override
  String get systemPromptKey => "copywriter_prompt";

  @override
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    String? apiKey,
    String? gemmaKey,
    Uint8List? imageBytes,
    String? imageMimeType,
    Function(AdkEvent)? onEvent,
    Ref? ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final systemInstruction = systemPrompt ?? "You are a Copywriting Agent. Write engaging text for: $userPrompt. Tone: Professional yet bold.";

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
    );

    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return aiRes.text;
  }
}

class DeveloperAgent extends BaseAgent {
  @override
  String get name => "Developer Agent";
  @override
  MessageSender get type => MessageSender.developerAgent;
  @override
  String get systemPromptKey => "developer_prompt";

  @override
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    String? apiKey,
    String? gemmaKey,
    Uint8List? imageBytes,
    String? imageMimeType,
    Function(AdkEvent)? onEvent,
    Ref? ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final systemInstruction = systemPrompt ?? "You are a Developer Agent. Generate Flutter code for: $userPrompt. Return ONLY valid Dart code wrapped in ```dart blocks.";

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
    );

    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return aiRes.text;
  }
}

class OrchestratorAgent extends BaseAgent {
  @override
  String get name => "Orchestrator Agent";
  @override
  MessageSender get type => MessageSender.orchestratorAgent;
  @override
  String get systemPromptKey => "orchestrator_prompt";

  @override
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    String? apiKey,
    String? gemmaKey,
    Uint8List? imageBytes,
    String? imageMimeType,
    Function(AdkEvent)? onEvent,
    Ref? ref,
  }) async {
     onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
     onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
     return "Orchestrator: Executing step: $userPrompt";
  }
}
