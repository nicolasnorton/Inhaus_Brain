import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'base_agent.dart';
import '../models/chat_models.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/utils/sanitization_utils.dart';
import '../services/memory_service.dart';
import '../../../core/architecture/blackboard.dart';
import '../../../core/architecture/memory.dart';
import '../../workspace/services/agent_registry_service.dart';

enum RouterIntent {
  research,       // Competitive analysis, trends, facts
  creative,       // Visual concepts, design, moodboards
  creativeImage,  // Specific image generation
  creativeVideo,  // Specific video generation
  creativeDesign, // Stitch UI/Web design
  genUiReport,    // Strategy, plans, interactive reports
  copywriting,    // Writing, editing, tone
  development,    // Code, technical architecture
  pipeline,       // Complex multi-step requests
  management,     // Client, Project, Task management
  directChat,      // Simple questions, greetings, small talk
  seo,             // SEO optimization
  aeo,             // AEO optimization
  proposal,        // PDF Proposals
  knowledge        // Explicit knowledge/data retrieval
}

class RouterResult {
  final RouterIntent intent;
  final String confidence;
  final String? suggestedPipelineKey;

  RouterResult({required this.intent, required this.confidence, this.suggestedPipelineKey});
}

class RouterAgent extends BaseAgent {
  @override
  String get name => "Brian";
  
  @override
  MessageSender get type => MessageSender.system;

  @override
  String get systemPromptKey => "brian_prompt";

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
    if (ref == null) throw Exception("RouterAgent requires a Ref");

    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name, message: "Analyzing system state..."));

    // 0. Fast-Path: Salutations
    if (SanitizationUtils.isSimpleSalutation(userPrompt)) {
      onEvent?.call(AdkEvent(type: AdkEventType.agentThinking, source: name, message: "Intent: DIRECT_CHAT (Heuristic)"));
      return '{"intent": "directChat", "confidence": 1.0, "reasoning": "Heuristic: Simple salutation detected."}';
    }

    // 1. Build Dynamic Router Context from Agent Registry
    String dynamicAgentContext = '';
    try {
      final registryService = ref.read(agentRegistryServiceProvider);
      dynamicAgentContext = await registryService.buildAgentSummaries();
      if (dynamicAgentContext.isNotEmpty) {
        debugPrint('Router: Loaded ${dynamicAgentContext.split('\n').length} lines of dynamic agent context');
      }
    } catch (e) {
      debugPrint('Router: Could not load dynamic agent context, using static prompt: $e');
    }

    // 2. Tiered Context: Read Global & Episodic Memory
    final globalContext = GlobalContext(
      projectName: "Inhaus Brain Default",
      description: "A production-grade agentic orchestration system.",
      primaryObjectives: ["Scale creative output", "Automate marketing workflows"],
    );
    
    final memoryService = ref.read(memoryServiceProvider);
    final rawMemory = await memoryService.readMemory();
    
    // Assemble Tiered Memory for the Router
    final tieredMemory = AgentMemory(
      globalContext: globalContext,
      workingMemory: WorkingMemory(currentTaskId: 'routing', currentTaskData: 'User initial query'),
    );

    // 3. Intent Classification with Blackboard Integration
    // Combine static systemPrompt with dynamic agent registry context
    final effectiveSystemPrompt = dynamicAgentContext.isNotEmpty
        ? '${systemPrompt ?? ''}\n\n## Available Agents (Dynamic Registry)\n$dynamicAgentContext'
        : systemPrompt ?? '';

    final classificationPrompt = """
$effectiveSystemPrompt

${tieredMemory.toSystemPromptFragment()}

## Raw System History:
$rawMemory

## User Input:
${SanitizationUtils.escapePrompt(userPrompt)}
""";

    final aiRes = await EdgeAIService.generateText(
      classificationPrompt,
      apiKey: apiKey,
      ref: ref,
      modelConfig: AIModelConfig.geminiResearch,
    );
    
    // Parse Intent & Post to Blackboard
    final blackboard = ref.read(blackboardProvider.notifier);
    
    try {
      final text = aiRes.text.trim();
      final jsonStr = text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1);
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      
      final intentStr = data['intent']?.toString().toUpperCase() ?? 'DIRECT_CHAT';
      final confidence = data['confidence'] ?? 0.0;
      final reason = data['reasoning'] ?? 'N/A';

      // Update Blackboard Facts
      blackboard.postFact('user_intent', intentStr);
      blackboard.postFact('routing_reason', reason);

      if (intentStr == 'PIPELINE') {
          final pipelineKey = data['pipeline'] ?? 'standard-campaign';
          blackboard.addEvent(
            WorkflowEventType.userRequested, 
            "Initializing Pipeline: $pipelineKey",
            data: {'pipeline': pipelineKey}
          );
          
          blackboard.addEvent(WorkflowEventType.userRequested, "Triggering Strategy & Trend analysis...");
      }

      onEvent?.call(AdkEvent(type: AdkEventType.agentThinking, source: name, message: "Intent: $intentStr (Conf: $confidence)"));
      
    } catch (e) {
      debugPrint('Router: Failed to parse/post blackboard data: $e');
    }

    return aiRes.text; 
  }
}
