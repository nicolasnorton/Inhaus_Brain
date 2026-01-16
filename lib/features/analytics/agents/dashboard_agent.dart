import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../chat/agents/base_agent.dart';
import '../../chat/models/chat_models.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/adk/services/adk_event_bus.dart';

class DashboardAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.dashboardAgent;
  @override
  String get name => "Dashboard Architect";
  @override
  String get systemPromptKey => "dashboard_agent_prompt";

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
    Ref? ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    
    final systemInstruction = """
You are a Generative UI Architect for the Inhaus Business Analytics Dashboard.
Your job is to design a live dashboard layout based on the current context (client info, project info, analyst reports).

RETURN ONLY A JSON OBJECT with the following structure:
{
  "title": "Dashboard Title",
  "components": [
    {
      "type": "kpi",
      "label": "ROI",
      "value": "3.2x",
      "trend": "+12%",
      "status": "positive"
    },
    {
      "type": "chart",
      "chartType": "line",
      "label": "Conversion over Time",
      "data": [{"x": "Mon", "y": 2}, {"x": "Tue", "y": 4}]
    },
    {
      "type": "insight",
      "text": "Markdown formatted insight text from the Strategy Agent."
    },
    {
      "type": "media",
      "mediaType": "image",
      "url": "asset_or_network_url",
      "caption": "Contextual visual"
    }
  ]
}

Input Context: $userPrompt
""";

    final result = (await EdgeAIService.generateText(
      systemInstruction,
      context: context,
      ref: ref,
    )).text;
    
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return result;
  }
}
