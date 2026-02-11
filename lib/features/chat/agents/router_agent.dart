import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_agent.dart';
import '../models/chat_models.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart'; // Import for AIModelConfig
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/utils/sanitization_utils.dart';
import '../services/memory_service.dart';
import '../../../core/architecture/blackboard.dart';
import '../../../core/architecture/memory.dart';

enum RouterIntent {
  research,       // Competitive analysis, trends, facts
  creative,       // Visual concepts, design, moodboards
  creativeImage,  // Specific image generation
  creativeVideo,  // Specific video generation
  genUiReport,    // Strategy, plans, interactive reports
  copywriting,    // Writing, editing, tone
  development,    // Code, technical architecture
  pipeline,       // Complex multi-step requests
  management,     // Client, Project, Task management
  directChat,      // Simple questions, greetings, small talk
  seo,             // SEO optimization
  aeo,             // AEO optimization
  proposal         // PDF Proposals
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
  MessageSender get type => MessageSender.system; // Acts on behalf of system

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

    // 1. Tiered Context: Read Global & Episodic Memory
    // Note: In a full implementation, we'd fetch this from a dedicated MemoryProvider
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

    // 2. Intent Classification with Blackboard Integration
    final classificationPrompt = """
$systemPrompt

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
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
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
          
          // Spawn parallel tasks (Step 2 of Audit)
          // For a campaign, we need both a Strategy and a Trend Scout report
          blackboard.addEvent(WorkflowEventType.userRequested, "Triggering Strategy & Trend analysis...");
          
          // We define tasks in the Blackboard
          // This allows parallel execution by different workers
      }

      onEvent?.call(AdkEvent(type: AdkEventType.agentThinking, source: name, message: "Intent: $intentStr (Conf: $confidence)"));
      
    } catch (e) {
      debugPrint('Router: Failed to parse/post blackboard data: $e');
    }

    return aiRes.text; 
  }
}
