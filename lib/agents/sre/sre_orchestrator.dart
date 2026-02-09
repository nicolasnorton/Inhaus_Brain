import 'dart:async';
import 'dart:typed_data';

import 'package:ag_ui/ag_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/features/copilot/data/copilot_repository.dart';

import '../../core/adk/services/adk_event_bus.dart';
import '../../core/services/edge_ai_service.dart';
import '../../core/tokens/llm_provider.dart';
import '../../core/services/system_prompts_service.dart';
import '../../features/chat/agents/base_agent.dart';
import '../../features/chat/models/chat_models.dart';
import '../../features/knowledge/models/knowledge_source.dart';

class SreOrchestratorAgent extends BaseAgent {
  @override
  String get name => "SRE Orchestrator";
  
  @override
  MessageSender get type => MessageSender.sreOrchestratorAgent;

  @override
  String get systemPromptKey => "sre_orchestrator.md"; 

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
    
    String? prompt = systemPrompt;
    if (ref != null) {
      final promptService = ref.read(systemPromptsProvider);
      final basePrompt = await promptService.getSreOrchestratorPrompt();
      prompt = systemPrompt ?? basePrompt;
    }

    // Default if ref is null or something fails
    prompt ??= "You are the SRE Orchestrator. Manage incidents safely.";

    return _sreExecute(
      agentName: name,
      systemPrompt: prompt,
      userPrompt: userPrompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      onEvent: onEvent,
      modelConfig: AIModelConfig.geminiPro,
      ref: ref,
    );
  }
}

Future<String> _sreExecute({
  required String agentName,
  required String userPrompt,
  required List<KnowledgeSource> context,
  String? systemPrompt,
  String? apiKey,
  String? gemmaKey,
  Uint8List? imageBytes,
  String? imageMimeType,
  Function(AdkEvent)? onEvent,
  AIModelConfig? modelConfig,
  bool jsonMode = false,
  dynamic ref,
}) async {
  
  final promptHeader = systemPrompt ?? "You are the $agentName.";

  // COPILOTKIT INTEGRATION
  if (ref != null) {
      try {
          final repo = ref.read(copilotRepositoryProvider);
          final buffer = StringBuffer();
          final completer = Completer<String>();
          
          final systemMsg = SystemMessage(
             id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
             content: promptHeader + (jsonMode ? "\n\nCRITICAL: You MUST return a valid JSON object." : "")
          );

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
                String text = buffer.toString();
                if (jsonMode) {
                  if (text.contains('```json')) {
                    text = text.split('```json').last.split('```').first.trim();
                  } else if (text.contains('```')) {
                    text = text.split('```').last.split('```').first.trim();
                  }
                }
                if (!completer.isCompleted) completer.complete(text);
             },
             onError: (err) {
                 if (!completer.isCompleted) completer.completeError(err);
             }
          );
          
          final result = await completer.future;
          onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: agentName));
          return result;
      } catch (e) {
          // Fallback
          print("Copilot Execution Failed: $e. Falling back to EdgeAIService.");
      }
  }

  // Fallback
  final fullPrompt = "SYSTEM: $promptHeader\nUSER: $userPrompt";
  
  final result = await EdgeAIService.generateText(
    fullPrompt,
    context: context,
    imageBytes: imageBytes,
    imageMimeType: imageMimeType,
    apiKey: apiKey,
    gemmaKey: gemmaKey,
    modelConfig: modelConfig,
    outputMode: jsonMode ? 'json' : null,
    ref: ref,
  );
  
  onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: agentName));
  return result.text;
}
