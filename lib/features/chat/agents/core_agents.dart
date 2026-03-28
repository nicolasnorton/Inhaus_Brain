/// Core Agents — migrated to AgentExecutor ReAct loop.
///
/// Each agent now uses [executeWithTools] for iterative tool calling,
/// while preserving [execute] as a backward-compatible wrapper.
///
/// Eliminated ~400 lines of duplicated boilerplate. Each agent's
/// personality comes from its system prompt; the execution engine
/// is shared via [BaseAgent.executeWithTools].
library;

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../agents/base_agent.dart';
import '../models/chat_models.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/services/system_prompts_service.dart';
import '../../../core/architecture/context_assembler.dart';
import '../../../core/tokens/llm_provider.dart';
import 'tools/brainweave_tools.dart';

// ═══════════════════════════════════════════════════════════════════
// Shared helper: wraps executeWithTools for backward compat with
// the legacy String-returning execute() signature.
// ═══════════════════════════════════════════════════════════════════

/// Executes an agent using the new ReAct loop, returning a String
/// for backward compatibility with the legacy execute() API.
Future<String> _executeViaReactLoop({
  required BaseAgent agent,
  required String userPrompt,
  required List<KnowledgeSource> context,
  required String systemPrompt,
  Uint8List? imageBytes,
  String? imageMimeType,
  Function(AdkEvent)? onEvent,
  dynamic ref,
}) async {
  String effectiveSystemPrompt = systemPrompt;
  if (ref != null) {
    try {
      final assembler = ref.read(contextAssemblerProvider);
      final assembledCtx = await assembler.assemble(
        currentQuery: userPrompt,
        agentName: agent.name,
        attachedKnowledge: context,
      );
      
      // Inject assembled memory block into system prompt
      effectiveSystemPrompt = '$systemPrompt\n\n${assembledCtx.systemPromptFragment}';
      
      // Add user turn to session history
      assembler.addUserMessage(userPrompt);
    } catch (e) {
      debugPrint('CoreAgents: ContextAssembler failed: $e');
    }
  }

  final result = await agent.executeWithTools(
    userPrompt: userPrompt,
    context: context,
    systemPrompt: effectiveSystemPrompt,
    imageBytes: imageBytes,
    imageMimeType: imageMimeType,
    onEvent: onEvent,
    ref: ref,
  );

  // Append sources if present
  String responseText = result.text;
  
  if (ref != null) {
      try {
        final assembler = ref.read(contextAssemblerProvider);
        assembler.addAgentResponse(agent.name, responseText);
        
        // Asynchronously save to long-term episodic memory (Phase 5)
        assembler.saveEpisode(
           agentName: agent.name,
           taskSummary: userPrompt,
           output: responseText,
        );
      } catch (e) {
        debugPrint('CoreAgents: Failed to save episode: $e');
      }
  }

  if (result.sourceCitations.isNotEmpty) {
    responseText += '\n\n**Sources:**\n${result.sourceCitations.map((s) => '- $s').join('\n')}';
  }
  return responseText;
}

// ═══════════════════════════════════════════════════════════════════
// Agent Definitions
// ═══════════════════════════════════════════════════════════════════

class ResearchAgent extends BaseAgent {
  @override
  String get name => "Research Agent";
  @override
  MessageSender get type => MessageSender.researchAgent;
  @override
  String get systemPromptKey => "research_prompt";
  @override
  AIModelConfig get modelConfig => AIModelConfig.geminiResearch;
  @override
  bool get enableThinking => true; // Research benefits from reasoning

  @override
  List<AgentTool> get tools => [
        QueryBrainWeaveTool(),
        MeetingSyncTool(),
        AnnotateTool(),
        FeedbackTool(),
        GetExternalDocTool(),
        GetNodeContextTool(),
        CreateAtomicNodeTool(),
        WikiGenerateTool(),
      ];

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getResearchPrompt();
    
    final effectivePrompt = basePrompt
        .replaceAll('[TASK]', userPrompt)
        .replaceAll('{{userPrompt}}', userPrompt)
        .replaceAll('{{researchSummary}}', "Use [GROUNDING] to find latest data.");

    return _executeViaReactLoop(
      agent: this,
      userPrompt: userPrompt,
      context: context,
      systemPrompt: systemPrompt ?? effectivePrompt,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      ref: ref,
    );
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
  AIModelConfig get modelConfig => AIModelConfig.geminiResearch;

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getCreativePrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[TASK]', userPrompt);

    return _executeViaReactLoop(
      agent: this,
      userPrompt: userPrompt,
      context: context,
      systemPrompt: prompt,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      ref: ref,
    );
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
  AIModelConfig get modelConfig => AIModelConfig.geminiResearch;

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getDesignPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[CONCEPT]', userPrompt);

    return _executeViaReactLoop(
      agent: this,
      userPrompt: userPrompt,
      context: context,
      systemPrompt: prompt,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      ref: ref,
    );
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
  AIModelConfig get modelConfig => AIModelConfig.geminiResearch;

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getVideoPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[SCRIPT]', userPrompt);

    return _executeViaReactLoop(
      agent: this,
      userPrompt: userPrompt,
      context: context,
      systemPrompt: prompt,
      onEvent: onEvent,
      ref: ref,
    );
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
  AIModelConfig get modelConfig => AIModelConfig.geminiFlash;

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getServicePrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[ISSUE]', userPrompt);

    return _executeViaReactLoop(
      agent: this,
      userPrompt: userPrompt,
      context: context,
      systemPrompt: prompt,
      onEvent: onEvent,
      ref: ref,
    );
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
  AIModelConfig get modelConfig => AIModelConfig.geminiFlash;

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getCRMPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[CLIENT_DATA]', userPrompt);

    return _executeViaReactLoop(
      agent: this,
      userPrompt: userPrompt,
      context: context,
      systemPrompt: prompt,
      onEvent: onEvent,
      ref: ref,
    );
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
  AIModelConfig get modelConfig => AIModelConfig.geminiResearch;
  @override
  bool get enableThinking => true; // Strategic advice benefits from reasoning

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getCSuitePrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[REPORT]', userPrompt);

    return _executeViaReactLoop(
      agent: this,
      userPrompt: userPrompt,
      context: context,
      systemPrompt: prompt,
      onEvent: onEvent,
      ref: ref,
    );
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
  AIModelConfig get modelConfig => AIModelConfig.geminiFlash;

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getStorytellingPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[INPUT]', userPrompt);

    return _executeViaReactLoop(
      agent: this,
      userPrompt: userPrompt,
      context: context,
      systemPrompt: prompt,
      onEvent: onEvent,
      ref: ref,
    );
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
  AIModelConfig get modelConfig => AIModelConfig.geminiFlash;

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getCopywriterPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[TASK]', userPrompt);

    return _executeViaReactLoop(
      agent: this,
      userPrompt: userPrompt,
      context: context,
      systemPrompt: prompt,
      onEvent: onEvent,
      ref: ref,
    );
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
  AIModelConfig get modelConfig => AIModelConfig.geminiPro;
  @override
  bool get enableThinking => true; // Complex code benefits from reasoning

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getDeveloperPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[TASK]', userPrompt);

    return _executeViaReactLoop(
      agent: this,
      userPrompt: userPrompt,
      context: context,
      systemPrompt: prompt,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      ref: ref,
    );
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
  AIModelConfig get modelConfig => AIModelConfig.geminiPro;
  @override
  bool get enableThinking => true;

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
