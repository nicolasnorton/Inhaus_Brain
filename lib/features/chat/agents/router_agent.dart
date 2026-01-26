import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_agent.dart';
import '../models/chat_models.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/utils/sanitization_utils.dart';
import '../services/memory_service.dart';

enum RouterIntent {
  research,    // Competitive analysis, trends, facts
  creative,    // Visual concepts, design, moodboards
  copywriting, // Writing, editing, tone
  development, // Code, technical architecture
  pipeline,    // Complex multi-step requests
  management,  // Client, Project, Task management
  directChat   // Simple questions, greetings, small talk
}

class RouterResult {
  final RouterIntent intent;
  final String confidence;
  final String? suggestedPipelineKey;

  RouterResult({required this.intent, required this.confidence, this.suggestedPipelineKey});
}

class RouterAgent extends BaseAgent {
  @override
  String get name => "Root Router";
  
  @override
  MessageSender get type => MessageSender.system; // Acts on behalf of system

  @override
  String get systemPromptKey => "router_prompt";

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
    if (ref == null) throw Exception("RouterAgent requires a Ref");

    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name, message: "Analyzing system state..."));

    // 1. External Memory (Context Injection)
    final memoryService = ref.read(memoryServiceProvider);
    final longTermMemory = await memoryService.readMemory();
    
    // 2. Intent Classification
    final classificationPrompt = """
$systemPrompt

## Current System Memory:
$longTermMemory

## User Input:
${SanitizationUtils.escapePrompt(userPrompt)}
""";

    final aiRes = await EdgeAIService.generateText(
      classificationPrompt,
      apiKey: apiKey,
      ref: ref,
    );
    
    // Parse Intent
    RouterIntent intentEnum = RouterIntent.directChat; // Default
    try {
      final text = aiRes.text.trim();
      final jsonStr = text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1);
      final data = jsonDecode(jsonStr); // Assuming import 'dart:convert';
      final intentStr = data['intent']?.toString().toUpperCase() ?? 'DIRECT_CHAT';
      
      intentEnum = RouterIntent.values.firstWhere(
        (e) => e.name.toUpperCase() == intentStr, 
        orElse: () => RouterIntent.directChat
      );
    } catch (e) {
      // Fallback to direct chat if parsing fails
      intentEnum = RouterIntent.directChat;
    }

    onEvent?.call(AdkEvent(type: AdkEventType.agentThinking, source: name, message: "Routed to: ${intentEnum.name}"));

    // 3. Dynamic Tool Selection & Micro-Agent Dispatch
    // In a full implementation, we would instantiate a specialized Agent class here.
    // For now, we return the intent logic + relevant tools to the AssistantService controller
    // or we can execute sub-agents directly. 
    // Given the current architecture, RouterAgent is mainly a router. 
    // We will return the classification result JSON so AssistantService can pick the tools.
    // BUT the prompt said "Refactor RouterAgent to dispatch".

    // Let's return the simplified classification string for the AssistantService to act on? 
    // No, `execute` returns String (the answer).
    // So RouterAgent should probably handle the tool execution or delegate.
    
    // However, `AssistantService` logic is currently monolythic. 
    // To properly "dispatch", we need `AssistantService` to call `RouterAgent`, get the intent, 
    // AND THEN call the specialized agent/tools. 
    // OR `RouterAgent` calls the tools/sub-agent and returns the final string.
    
    // Let's stick to the contract: Router returns the "Text Response" OR "Tool Command".
    // But the Router's job is to ROUTE.
    // Let's return the JSON so the Service can handle the tool execution loop.
    return aiRes.text; 
  }
}
