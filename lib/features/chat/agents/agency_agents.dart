import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../features/knowledge/models/knowledge_source.dart';
import '../models/chat_models.dart';
import 'base_agent.dart';
import '../../../core/services/system_prompts_service.dart';

/// Helper to reduce boilerplate
import 'package:inhaus_brain/features/copilot/data/copilot_repository.dart';
import 'package:inhaus_brain/features/copilot/presentation/copilot_view.dart';
import 'package:ag_ui/ag_ui.dart';

/// Helper to reduce boilerplate
Future<String> _simpleExecute({
  required String agentName,
  required String systemPromptKey,
  required String userPrompt,
  required List<KnowledgeSource> context,
  String? systemPrompt,
  String? apiKey,
  String? gemmaKey,
  Uint8List? imageBytes,
  String? imageMimeType,
  Function(AdkEvent)? onEvent,
  Ref? ref, // Phase 89: Required for CopilotKit
}) async {
  onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: agentName));
  
  final promptHeader = systemPrompt ?? "You are the $agentName. Act accordingly.";

  // COPILOTKIT MIGRATION
  // If we have a Ref, use the CopilotRepository to execute via the Runtime
  if (ref != null) {
      try {
          final repo = ref.read(copilotRepositoryProvider);
          final buffer = StringBuffer();
          final completer = Completer<String>();
          
          final systemMsg = SystemMessage(
             id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
             content: promptHeader
          );

          // We append context to the user prompt for now, as SimpleRunAgentInput has specific context fields
          // but just prepending is easier for migration.
          String augmentedPrompt = userPrompt;
          if (context.isNotEmpty) {
             augmentedPrompt += "\n\nCONTEXT:\n${context.map((k) => k.content).join('\n')}";
          }

          repo.sendMessage(augmentedPrompt, systemMessage: systemMsg).listen(
             (event) {
                if (event is TextMessageContentEvent) {
                   buffer.write(event.delta);
                } else if (event is TextMessageChunkEvent) {
                   if (event.delta != null) buffer.write(event.delta);
                } else if (event is RunErrorEvent) {
                   if (!completer.isCompleted) completer.completeError(event.message);
                }
             },
             onDone: () {
                if (!completer.isCompleted) completer.complete(buffer.toString());
             },
             onError: (err) {
                 if (!completer.isCompleted) completer.completeError(err);
             }
          );
          
          final result = await completer.future;
          onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: agentName));
          return result;
      } catch (e) {
          // Fallback to core edge service if copilot fails? 
          // Or just log and rethrow.
          print("Copilot Execution Failed: $e. Falling back to EdgeAIService.");
      }
  }

  // Legacy / Fallback Path
  final fullPrompt = "SYSTEM: $promptHeader\nUSER: $userPrompt";
  
  final result = await EdgeAIService.generateText(
    fullPrompt,
    context: context,
    imageBytes: imageBytes,
    imageMimeType: imageMimeType,
    apiKey: apiKey,
    gemmaKey: gemmaKey,
    ref: ref,
  );
  
  onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: agentName));
  return result.text;
}

/// 1. Trend Scout Agent
class TrendScoutAgent extends BaseAgent {
  @override
  String get name => "Trend Scout";
  
  @override
  MessageSender get type => MessageSender.trendScoutAgent;

  @override
  String get systemPromptKey => "trend_scout.md";

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
  }) {
    return _simpleExecute(
      agentName: name,
      systemPromptKey: systemPromptKey,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      ref: ref,
    );
  }
}

/// 2. Account Director Agent
class AccountDirectorAgent extends BaseAgent {
  @override
  String get name => "Account Director";
  
  @override
  MessageSender get type => MessageSender.accountDirectorAgent;

  @override
  String get systemPromptKey => "account_director.md";

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
  }) {
    return _simpleExecute(
      agentName: name,
      systemPromptKey: systemPromptKey,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      ref: ref,
    );
  }
}

/// 3. Strategist Agent
class StrategistAgent extends BaseAgent {
  @override
  String get name => "Strategist";
  
  @override
  MessageSender get type => MessageSender.strategistAgent;

  @override
  String get systemPromptKey => "strategist.md";

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
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getStrategistPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[INPUT_DATA]', userPrompt);

    return _simpleExecute(
      agentName: name,
      systemPromptKey: systemPromptKey,
      systemPrompt: prompt,
      userPrompt: userPrompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      ref: ref,
    );
  }
}

/// 4. Editorial Manager Agent
class EditorialManagerAgent extends BaseAgent {
  @override
  String get name => "Editorial Manager";
  
  @override
  MessageSender get type => MessageSender.editorialManagerAgent;

  @override
  String get systemPromptKey => "editorial_manager.md";

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
  }) {
    return _simpleExecute(
      agentName: name,
      systemPromptKey: systemPromptKey,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      ref: ref,
    );
  }
}

/// 5. Media Buyer Agent
class MediaBuyerAgent extends BaseAgent {
  @override
  String get name => "Media Buyer";
  
  @override
  MessageSender get type => MessageSender.mediaBuyerAgent;

  @override
  String get systemPromptKey => "media_buyer.md";

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
  }) {
    return _simpleExecute(
      agentName: name,
      systemPromptKey: systemPromptKey,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      ref: ref,
    );
  }
}

/// 6. Performance Analyst Agent
class PerformanceAnalystAgent extends BaseAgent {
  @override
  String get name => "Performance Analyst";
  
  @override
  MessageSender get type => MessageSender.performanceAnalystAgent;

  @override
  String get systemPromptKey => "performance_analyst.md";

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
  }) {
    return _simpleExecute(
      agentName: name,
      systemPromptKey: systemPromptKey,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      ref: ref,
    );
  }
}
