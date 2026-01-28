import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../models/chat_models.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/mcp/agent_tool.dart';
import 'agent_config.dart';

abstract class BaseAgent {
  MessageSender get type;
  String get name;
  String get systemPromptKey; // Key to fetch from SystemPromptsService if needed, or hardcoded default
  
  /// Configuration for this agent (model, temp, etc.)
  AgentConfig get config => const AgentConfig();

  /// Tools available to this agent
  List<AgentTool> get tools => []; 

  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt, // Optional override from SystemPromptsService
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
    Function(AdkEvent)? onEvent,
    Ref? ref, // Phase 89
  });
}
