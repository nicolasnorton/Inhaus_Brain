import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../../features/knowledge/models/knowledge_source.dart';
import '../models/chat_models.dart';
import 'base_agent.dart';
import '../../../core/services/system_prompts_service.dart';
import '../../../core/services/ai_proxy_service.dart';
import '../../../core/architecture/blackboard.dart';

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
  AIModelConfig? modelConfig,
  bool jsonMode = false,
  dynamic ref, // Phase 89: Required for CopilotKit
}) async {
  onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: agentName));
  
  final promptHeader = systemPrompt ?? "You are the $agentName. Act accordingly.";

  // COPILOTKIT MIGRATION
  // If we have a Ref, use the CopilotRepository to execute via the Runtime
  if (ref != null) {
      try {
          final repo = ref.read(vertexChatRepositoryProvider);
          final buffer = StringBuffer();
          final completer = Completer<String>();
          
          final systemMsg = SystemMessage(
             id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
             content: promptHeader + (jsonMode ? "\n\nCRITICAL: You MUST return a valid JSON object." : "")
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
                String text = buffer.toString();
                if (jsonMode) {
                  // Basic cleanup for CopilotKit which might not support mimeType directly yet
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
    modelConfig: modelConfig,
    outputMode: jsonMode ? 'json' : null,
    ref: ref,
  );
  
  onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: agentName));
  return result.text;
}

/// Structured Extraction Helper for Agents
mixin LangExtractMixin {
  Future<void> extractFromContext({
    required List<KnowledgeSource> context,
    required Map<String, dynamic> schema,
    required WidgetRef ref,
    String? agentName,
  }) async {
    final docs = context.where((k) => k.type == KnowledgeSourceType.text || k.content.length > 500).toList();
    if (docs.isEmpty) return;

    final blackboard = ref.read(blackboardProvider.notifier);
    
    for (final doc in docs) {
      try {
        debugPrint('LangExtract: Attempting structured extraction for ${doc.title}');
        final result = await AIProxyService.extractStructured(
          document: doc.content,
          schema: schema,
        );
        
        String? groundingUrl;
        final groundingHtml = result['extraction']?['grounding_html'] as String?;
        
        if (groundingHtml != null && groundingHtml.isNotEmpty) {
           try {
             final storageRef = FirebaseStorage.instance
                 .ref()
                 .child('extractions/${doc.id}_${DateTime.now().millisecondsSinceEpoch}.html');
             
             await storageRef.putString(
               groundingHtml, 
               format: PutStringFormat.raw, 
               metadata: SettableMetadata(contentType: 'text/html')
             );
             groundingUrl = await storageRef.getDownloadURL();
             debugPrint('LangExtract: Grounding HTML uploaded: $groundingUrl');
           } catch (e) {
             debugPrint('LangExtract: Grounding upload failed: $e');
           }
        }

        final finalResult = {
          ...result,
          'grounding_url': groundingUrl,
        };

        // Post to Blackboard
        blackboard.postFact('extraction_${doc.id}', finalResult);
        blackboard.postFact('last_grounding_url', groundingUrl); // For quick UI preview
        
        blackboard.addEvent(
          WorkflowEventType.agentAction, 
          "Structured extraction completed for ${doc.title}",
          data: {
            'agent': agentName, 
            'sourceId': doc.id, 
            'summary': result['message'],
            'grounding_url': groundingUrl
          }
        );
      } catch (e) {
        debugPrint('LangExtract: Extraction failed for ${doc.title}: $e');
      }
    }
  }
}

/// 1. Trend Scout Agent
class TrendScoutAgent extends BaseAgent with LangExtractMixin {
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
    dynamic ref,
  }) {
    // LangExtract for deep market research (Background)
    if (userPrompt.toLowerCase().contains('research') || context.length > 1) {
      extractFromContext(
        context: context,
        schema: {
          "type": "object",
          "properties": {
            "market_trends": {"type": "array", "items": {"type": "string"}},
            "consumer_insights": {"type": "array", "items": {"type": "string"}},
            "growth_opportunities": {"type": "array", "items": {"type": "string"}}
          }
        },
        ref: ref,
        agentName: name
      ).catchError((e) => debugPrint('TrendScout Extract Error: $e'));
    }

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
      modelConfig: AIModelConfig.geminiResearch,
      jsonMode: true,
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
    dynamic ref,
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
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
      ref: ref,
    );
  }
}

/// 3. Strategist Agent
class StrategistAgent extends BaseAgent with LangExtractMixin {
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
    dynamic ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getStrategistPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[INPUT_DATA]', userPrompt);

    final result = await _simpleExecute(
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
      modelConfig: AIModelConfig.geminiResearch,
      jsonMode: true,
      ref: ref,
    );

    // BACKGROUND TASK: Structured Extraction of context docs if this is a deep analysis
    if (userPrompt.toLowerCase().contains('analiza') || userPrompt.toLowerCase().contains('extract')) {
      // Fire and forget extraction to Blackboard
      extractFromContext(
        context: context, 
        schema: {
          "type": "object",
          "properties": {
            "key_objectives": {"type": "array", "items": {"type": "string"}},
            "budget_constraints": {"type": "string"},
            "target_audience": {"type": "string"},
            "competitors": {"type": "array", "items": {"type": "string"}}
          }
        }, 
        ref: ref,
        agentName: name
      );
    }

    return result;
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
    dynamic ref,
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
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
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
    dynamic ref,
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
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
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
    dynamic ref,
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
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
      ref: ref,
    );
  }
}

/// 7. SEO Agent
class SEOAgent extends BaseAgent {
  @override
  String get name => "SEO Agent";
  
  @override
  MessageSender get type => MessageSender.seoAgent;

  @override
  String get systemPromptKey => "seo_agent.md";

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getSEOPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[TASK]', userPrompt);

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
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
      ref: ref,
    );
  }
}

/// 8. AEO Agent
class AEOAgent extends BaseAgent {
  @override
  String get name => "AEO Agent";
  
  @override
  MessageSender get type => MessageSender.aeoAgent;

  @override
  String get systemPromptKey => "aeo_agent.md";

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
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getAEOPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[TASK]', userPrompt);

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
      modelConfig: AIModelConfig.geminiResearch, // Enable Google Search
      ref: ref,
    );
  }
}

/// 9. Proposal Specialist Agent
class ProposalSpecialistAgent extends BaseAgent with LangExtractMixin {
  @override
  String get name => "Proposal Specialist";
  
  @override
  MessageSender get type => MessageSender.proposalSpecialistAgent;

  @override
  String get systemPromptKey => "proposal_specialist.md";

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
    
    // Custom logic to ensure we get JSON back as requested in the system prompt
    String? prompt = systemPrompt;
    if (prompt == null && ref != null) {
       try {
         final service = ref.read(systemPromptsProvider);
         prompt = await service.getProposalSpecialistPrompt();
       } catch (e) {
         debugPrint("Failed to load proposal specialist prompt: $e");
       }
    }
    
    prompt ??= """
Bilingual Client Proposal Specialist - INHAUS Edition (v2.0)

You are the Bilingual Client Proposal Specialist for Inhaus Brain. Your goal is to generate professional, stunning, and conversion-focused business proposals in the authentic INHAUS style using a modular JSON structure that prioritizes visual hierarchy.

🎯 CORE OBJECTIVE
Generate valid JSON objects that represent business proposals. These objects will be consumed by a front-end renderer to create PDFs or Slides with the signature INHAUS dark-purple aesthetic.

🎨 INHAUS VISUAL IDENTITY (Locked to Official Style)
* Backgrounds: Dark/Black (#05050B) with subtle card elevations (#0F0F16).
* Headers: Rounded purple bars (#1A1423) for section titles.
* Typography: Montserrat or Sans-serif. White (#FFFFFF) for titles, Light Gray (#A0A0A0) for body text.
* Pricing: High-contrast white text in dedicated boxes, usually right-aligned.
* Footer: "inhauscorp.com" small right-aligned.

📋 PROPOSAL TYPES & SCHEMAS

1. DETAILED PROPOSAL (Modular Section System)
2. ONE PAGE QUOTE (High-Impact Summary)

Output MUST be a structured JSON following the INHAUS modular formats.
Tone: Professional, Premium. Spanish PRIMARY (ES), English OPTIONAL.
""";

    final result = await _simpleExecute(
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
      modelConfig: AIModelConfig.geminiPro, // Use Pro for complex synthesis
      jsonMode: true,
      ref: ref,
    );
    
    // LangExtract for brief intake/structured proposal data
    if (context.isNotEmpty) {
      extractFromContext(
        context: context,
        schema: {
          "type": "object",
          "properties": {
            "deliverables": {"type": "array", "items": {"type": "string"}},
            "timeline": {"type": "string"},
            "total_budget": {"type": "string"},
            "legal_requirements": {"type": "string"}
          }
        },
        ref: ref,
        agentName: name
      );
    }
    
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return result;
  }
}

/// 10. Copywriter Agent
class CopywriterAgent extends BaseAgent {
  @override
  String get name => "Copywriter";
  
  @override
  MessageSender get type => MessageSender.editorialManagerAgent; // Reusing editorial for now or add specific

  @override
  String get systemPromptKey => "copywriter.md";

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
    
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getCopywriterPrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[INPUT_DATA]', userPrompt);

    final result = await _simpleExecute(
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
      modelConfig: AIModelConfig.geminiPro,
      ref: ref,
    );
    
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return result;
  }
}

/// 11. Creative Agent
class CreativeAgent extends BaseAgent {
  @override
  String get name => "Creative";
  
  @override
  MessageSender get type => MessageSender.creativeAgent;

  @override
  String get systemPromptKey => "creative.md";

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
    
    final promptService = ref!.read(systemPromptsProvider);
    final basePrompt = await promptService.getCreativePrompt();
    final prompt = systemPrompt ?? basePrompt.replaceAll('[INPUT_DATA]', userPrompt);

    final result = await _simpleExecute(
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
      modelConfig: AIModelConfig.geminiPro,
      ref: ref,
    );
    
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return result;
  }
}

/// 12. Proposal Chat Agent
class ProposalChatAgent extends BaseAgent {
  @override
  String get name => "Proposal Chat Agent";
  
  @override
  MessageSender get type => MessageSender.proposalSpecialistAgent; // Reusing icon/persona

  @override
  String get systemPromptKey => "proposal_chat.md";

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
    
    // FETCH OFFICIAL PROMPT
    String? prompt = systemPrompt;
    if (prompt == null && ref != null) {
       try {
         final service = ref.read(systemPromptsProvider);
         prompt = await service.getProposalChatPrompt();
       } catch (e) {
         debugPrint("Failed to load proposal chat prompt: $e");
       }
    }

    final result = await _simpleExecute(
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
      modelConfig: AIModelConfig.geminiFlash,
      jsonMode: false, // Text mode for chat
      ref: ref,
    );
    
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return result;
  }
}

