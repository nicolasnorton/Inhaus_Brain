import 'dart:typed_data';
import 'base_agent.dart';
import '../models/chat_models.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/adk/services/adk_event_bus.dart';

enum RouterIntent {
  research,    // Competitive analysis, trends, facts
  creative,    // Visual concepts, design, moodboards
  copywriting, // Writing, editing, tone
  development, // Code, technical architecture
  pipeline,    // Complex multi-step requests
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
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name, message: "Classifying intent..."));
    final systemInstruction = """
You are the Root Router for Inhaus Brain. Your goal is to classify user intent into one of these categories:
- research: Fact finding, competitor analysis, market trends.
- creative: Visual direction, logo concepts, art direction.
- copywriting: Ad copy, social posts, writing tasks.
- development: Coding, technical logic.
- pipeline: Complex, multi-stage requests (e.g., "Build a full brand strategy from scratch").
- directChat: Casual conversation, clarifying questions.

Return ONLY a JSON object: {"intent": "category", "confidence": "0.xx", "pipeline": "optional_suggested_key"}
User Input: $userPrompt
""";

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      apiKey: apiKey,
    );

    return aiRes.text;
  }
}
