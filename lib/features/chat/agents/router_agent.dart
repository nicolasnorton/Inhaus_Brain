import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_agent.dart';
import '../models/chat_models.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/utils/sanitization_utils.dart';

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
    Ref? ref, // Phase 89
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name, message: "Classifying intent..."));
    // Use passed systemPrompt if available (from assets/SystemPromptsService), otherwise fallback to this robust default.
    final finalSystemPrompt = systemPrompt ?? """
You are the Root Router (Copilot) for the Inhaus Brain system. Your SOLE responsibility is to analyze the user's request and route it to the most capable specialized agent. You do NOT answer the question yourself unless it is simple small talk.

## Capabilities Registry
- **research**: Fact-finding, market analysis, competitor research, "find me information about...", "what is...".
- **creative**: Visual concepts, art direction, logo ideas, "generate an image...", "concept for...".
- **copywriting**: Writing ad copy, emails, social posts, blogs, "write a caption...", "create a script...".
- **development**: Coding tasks, technical explanations, "write a function...", "debug this...".
- **pipeline**: Multi-step strategies, full multi-channel branding, or automated workflows. "Plan a 3-month strategy...", "Execute a full agency flow...".
- **management**: Managed CRUD operations for Clients, Projects, Tasks, Campaigns, Apps (Workflows), and Knowledge Sources. "Add a client...", "Create a project...", "Create a campaign...", "List all apps", "Add knowledge source...".
- **directChat**: Casual conversation, clarifying questions.

## Output Format
Return **ONLY** a valid JSON object. Do not include markdown formatting (```json ... ```).

```json
{
  "intent": "category", 
  "confidence": 0.95, 
  "pipeline": "optional_suggested_key",
  "reasoning": "Brief explanation"
}
```
""";

    final systemInstruction = """
$finalSystemPrompt
User Input: ${SanitizationUtils.escapePrompt(userPrompt)}
""";

    final aiRes = await EdgeAIService.generateText(
      systemInstruction,
      apiKey: apiKey,
      ref: ref,
    );

    return aiRes.text;
  }
}
