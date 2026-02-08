import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_schema/json_schema.dart';
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
  
  /// Phase Machine: Optional Strict Schemas
  Map<String, dynamic>? get inputSchema => null; // Override to enforce input validation
  Map<String, dynamic>? get outputSchema => null; // Override to enforce output validation

  /// Phase Machine: Validation
  void validateInput(Map<String, dynamic> input) {
    if (inputSchema != null) {
      final schema = JsonSchema.create(inputSchema!);
      final result = schema.validate(input);
      if (!result.isValid) {
        throw FormatException("Input Validation Failed for $name: ${result.errors.join(', ')}");
      }
    }
  }

  void validateOutput(dynamic output) {
    if (outputSchema != null) {
       // Only validate if output is a Map/List (JSON object)
       if (output is! Map && output is! List) {
         // If schema exists but output is raw string, decide if we parse or fail.
         // Typically agents return String, so we might need to parse JSON first.
         // Here we assume strict validation is done on structured data.
         return; 
       }
       
      final schema = JsonSchema.create(outputSchema!);
      final result = schema.validate(output);
      if (!result.isValid) {
        throw FormatException("Output Validation Failed for $name: ${result.errors.join(', ')}");
      }
    }
  }

  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt, // Optional override from SystemPromptsService
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
    Function(AdkEvent)? onEvent,
    dynamic ref, // Phase 89
  });
}
