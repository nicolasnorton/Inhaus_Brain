import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../agents/base_agent.dart';
import '../models/chat_models.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/mcp/tools/web_search_tool.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/services/system_prompts_service.dart';
import '../../../core/tokens/llm_provider.dart';

class ResearchAgent extends BaseAgent {
  @override
  String get name => "Research Agent";
  @override
  MessageSender get type => MessageSender.researchAgent;
  @override
  String get systemPromptKey => "research_prompt";

  @override
  List<AgentTool> get tools => [];

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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(
      type: AdkEventType.agentStarted,
      source: name,
      message: "Researching: $userPrompt",
    ));

    // Fetch system prompt from service
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getResearchPrompt();
    
    final systemInstruction = basePrompt
        .replaceAll('[TASK]', userPrompt)
        .replaceAll('{{userPrompt}}', userPrompt)
        .replaceAll('{{researchSummary}}', "Use [GROUNDING] to find latest data.");

    // 2. AI Generation Grounded in Research (NATIVE)
    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
    );
    
    onEvent?.call(AdkEvent(
      type: AdkEventType.agentCompleted,
      source: name,
      message: "Research complete (Found ${aiRes.sourceCitations?.length ?? 0} sources).",
    ));
    
    // We append sources to the text for the Chat UI to handle if it doesn't support metadata citations yet
    String responseText = aiRes.text;
    if (aiRes.sourceCitations != null && aiRes.sourceCitations!.isNotEmpty) {
       responseText += "\n\n**Sources:**\n" + aiRes.sourceCitations!.map((s) => "- $s").join("\n");
    }

    return responseText;
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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getCreativePrompt();
    final systemInstruction = systemPrompt ?? basePrompt.replaceAll('[TASK]', userPrompt);

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
    );

    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return aiRes.text;
  }
}

class DesignAgent extends BaseAgent {
  @override
  String get name => "Design Agent";
  @override
  MessageSender get type => MessageSender.designAgent;
  @override
  String get systemPromptKey => "design_prompt";

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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getDesignPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[CONCEPT]', userPrompt);
    
    final aiRes = await EdgeAIService.generateText(
      prompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
    );
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return aiRes.text;
  }
}

class VideoProductionAgent extends BaseAgent {
  @override
  String get name => "Video Production Agent";
  @override
  MessageSender get type => MessageSender.videoProductionAgent;
  @override
  String get systemPromptKey => "video_prompt";

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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getVideoPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[SCRIPT]', userPrompt);
    
    final aiRes = await EdgeAIService.generateText(
      prompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
    );
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return aiRes.text;
  }
}

class CustomerServiceAgent extends BaseAgent {
  @override
  String get name => "Customer Service Agent";
  @override
  MessageSender get type => MessageSender.customerServiceAgent;
  @override
  String get systemPromptKey => "service_prompt";

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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getServicePrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[ISSUE]', userPrompt);
    
    final aiRes = await EdgeAIService.generateText(
      prompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
    );
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return aiRes.text;
  }
}

class CRMAgent extends BaseAgent {
  @override
  String get name => "CRM Agent";
  @override
  MessageSender get type => MessageSender.crmAgent;
  @override
  String get systemPromptKey => "crm_prompt";

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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getCRMPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[CLIENT_DATA]', userPrompt);
    
    final aiRes = await EdgeAIService.generateText(
      prompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
    );
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return aiRes.text;
  }
}

class CSuiteAdvisorAgent extends BaseAgent {
  @override
  String get name => "C-Suite Advisor Agent";
  @override
  MessageSender get type => MessageSender.cSuiteAdvisorAgent;
  @override
  String get systemPromptKey => "csuite_prompt";

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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getCSuitePrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[REPORT]', userPrompt);
    
    final aiRes = await EdgeAIService.generateText(
      prompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
    );
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return aiRes.text;
  }
}

class StorytellingAgent extends BaseAgent {
  @override
  String get name => "Storytelling Agent";
  @override
  MessageSender get type => MessageSender.storytellingAgent;
  @override
  String get systemPromptKey => "storytelling_prompt";

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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getStorytellingPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[INPUT]', userPrompt);
    
    final aiRes = await EdgeAIService.generateText(
      prompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getCopywriterPrompt();
    final systemInstruction = systemPrompt ?? basePrompt.replaceAll('[TASK]', userPrompt);

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getDeveloperPrompt();
    final systemInstruction = systemPrompt ?? basePrompt.replaceAll('[TASK]', userPrompt);

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
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
    dynamic ref,
  }) async {
     onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
     onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
     return "Orchestrator: Executing step: $userPrompt";
  }
}
