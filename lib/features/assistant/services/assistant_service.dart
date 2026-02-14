import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/features/knowledge/providers/knowledge_service_providers.dart';
import 'assistant_tool_registry.dart';
import '../../../core/services/semantic_cache_service.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../chat/services/memory_service.dart';
import '../../chat/services/tool_retrieval_service.dart';
import '../../chat/services/verification_service.dart';
import '../../chat/agents/router_agent.dart';
import '../../../core/services/local_persistence_service.dart';
import '../../chat/models/chat_models.dart'; // For Artifact model
import '../../copilot/data/copilot_repository.dart';
import '../../copilot/presentation/copilot_view.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../../core/architecture/blackboard.dart';
import '../../../core/services/system_prompts_service.dart';
import '../../../core/architecture/memory.dart';
import 'package:ag_ui/ag_ui.dart';
import '../../../core/services/json_parser_service.dart';
import '../../../core/services/blackboard_persistence_service.dart';

import '../domain/agent_outputs.dart';
import '../providers/assistant_provider.dart';
import '../../reports/providers/reports_provider.dart';
import '../../knowledge/services/knowledge_retriever_service.dart';
import '../../clients/providers/client_provider.dart';

enum AssistantMode { fast, planning }

class AssistantMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isToolOutput;
  final List<int>? attachment; // Image attachment
  final List<int>? audioAttachment; // Raw audio attachment
  final String? generatedAssetPath;
  final String? generatedAssetType; // 'image', 'video'
  final String? modelName;
  final Duration? processingTime;
  final List<String>? sources;
  final List<Artifact>? artifacts;
  final Map<String, dynamic>? uiPayload; // For GenUI components
  final List<String>? clarificationQuestions; // New: For ambiguity handling

  AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isToolOutput = false,
    this.attachment,
    this.audioAttachment,
    this.generatedAssetPath,
    this.generatedAssetType,
    this.modelName,
    this.processingTime,
    this.sources,
    this.artifacts,
    this.uiPayload,
    this.clarificationQuestions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'isToolOutput': isToolOutput,
    'generatedAssetPath': generatedAssetPath,
    'generatedAssetType': generatedAssetType,
    'modelName': modelName,
    'processingTimeMs': processingTime?.inMilliseconds,
    'sources': sources,
    'attachment': attachment != null ? base64Encode(attachment!) : null,
    'audioAttachment': audioAttachment != null ? base64Encode(audioAttachment!) : null,
    'artifacts': artifacts?.map((a) => a.toJson()).toList(),
    'uiPayload': uiPayload,
    'clarificationQuestions': clarificationQuestions,
  };

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    try {
      return AssistantMessage(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        text: json['text']?.toString() ?? '',
        isUser: json['isUser'] == true,
        timestamp: json['timestamp'] != null 
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isToolOutput: json['isToolOutput'] == true,
        generatedAssetPath: json['generatedAssetPath']?.toString(),
        generatedAssetType: json['generatedAssetType']?.toString(),
        modelName: json['modelName']?.toString(),
        processingTime: json['processingTimeMs'] != null 
            ? Duration(milliseconds: int.tryParse(json['processingTimeMs'].toString()) ?? 0) 
            : null,
        sources: (json['sources'] as List?)?.map((e) => e.toString()).toList(),
        attachment: (json['attachment'] != null && json['attachment'] is String) 
            ? base64Decode(json['attachment'] as String) 
            : null,
        audioAttachment: (json['audioAttachment'] != null && json['audioAttachment'] is String) 
            ? base64Decode(json['audioAttachment'] as String) 
            : null,
        artifacts: (json['artifacts'] as List?)
            ?.map((e) => Artifact.fromJson(Map<String, dynamic>.from(e as Map? ?? {})))
            .toList(),
        uiPayload: (json['uiPayload'] != null && json['uiPayload'] is Map) 
            ? Map<String, dynamic>.from(json['uiPayload'] as Map) 
            : null,
        clarificationQuestions: (json['clarificationQuestions'] as List?)?.map((e) => e.toString()).toList(),
      );
    } catch (e, stack) {
      debugPrint('Error parsing AssistantMessage: $e\nData: $json');
      // Return a safe error message object
      return AssistantMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Error parsing message data: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }
}

class AssistantService {
  final List<AssistantMessage> _history = [];
  final Ref _ref;
  // AssistantMode state is now managed by assistantModeProvider

  AssistantService(this._ref) {
    _initHistory();
  }

  Future<void> _initHistory() async {
    final persistence = _ref.read(persistenceServiceProvider);
    final history = await persistence.getAssistantHistory();
    if (history.isNotEmpty) {
      _history.addAll(history);
    }
  }

  List<AssistantMessage> get history => List.unmodifiable(_history);

  Future<AssistantMessage> sendMessage(String text, {List<int>? attachment, List<int>? audioAttachment, ToolMode toolMode = ToolMode.chat}) async {
    // 1. Add user message
    final userMsg = AssistantMessage(
      id: DateTime.now().toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      attachment: attachment,
      audioAttachment: audioAttachment,
    );

    // Special Commands: /clean-cache, /clear-cache, /clear cache
    final cmd = text.trim().toLowerCase();
    if (cmd == '/clean-cache' || cmd == '/clear-cache' || cmd == '/clear cache') {
       await _ref.read(semanticCacheServiceProvider).clearCache();
       final response = AssistantMessage(
         id: DateTime.now().toString(),
         text: "🛡️ Workspace Cache Cleared. Local context reset. I'm ready for fresh instructions.",
         isUser: false,
         timestamp: DateTime.now(),
       );
       _history.add(userMsg);
       _history.add(response);
       await _ref.read(persistenceServiceProvider).saveAssistantHistory(_history);
       return response;
    }

    _history.add(userMsg);
    await _ref.read(persistenceServiceProvider).saveAssistantHistory(_history);

    // 2. Initialize Blackboard for this request (Blackboard Pattern)
    final blackboard = _ref.read(blackboardProvider.notifier);
    final String currentSessionId = 'assistant_global'; // Default global assistant session
    
    // Load session from persistence if not already the active one
    if (blackboard.state.sessionId != currentSessionId) {
      debugPrint('Assistant: Loading persistent session $currentSessionId...');
      await _ref.read(blackboardPersistenceServiceProvider).loadSession(currentSessionId);
    }

    blackboard.addEvent(
      WorkflowEventType.userRequested, 
      "New User Request: $text",
      data: {
        'prompt': text,
        'hasAttachment': attachment != null,
      }
    );

    try {
      final stopwatch = Stopwatch()..start();
      
      // 3. Orchestration Loop (Tiered Orchestration)
      // Phase A: Intent & Routing
      final tools = _ref.read(assistantToolRegistryProvider);
      final executionResult = await _matchIntentAndExecute(text, tools, attachment: attachment, audioAttachment: audioAttachment, toolMode: toolMode);
      
      stopwatch.stop();

      // 4. Add response
      final message = AssistantMessage(
        id: DateTime.now().toString(),
        text: executionResult.text,
        isUser: false,
        timestamp: DateTime.now(),
        isToolOutput: executionResult.assetPath != null,
        generatedAssetPath: executionResult.assetPath,
        generatedAssetType: executionResult.assetType,
        modelName: executionResult.modelName ?? 'Gemini 2.5 Flash',
        processingTime: stopwatch.elapsed,
        sources: executionResult.sources,
        artifacts: executionResult.artifacts,
        uiPayload: executionResult.uiPayload,
      );

      _history.add(message);
      await _ref.read(persistenceServiceProvider).saveAssistantHistory(_history);
      
      // Update Blackboard with final result
      blackboard.postFact('finalResponse', message.text);
      if (message.artifacts != null) {
        blackboard.postFact('artifacts', message.artifacts!.map((a) => a.toJson()).toList());
      }
      
      // FIRE-AND-FORGET: Non-blocking Knowledge Ingestion
      // Agent 2: Prevent blocking video generation flow
      // We start this immediately but DO NOT await it, so the UI updates instantly.
      debugPrint('AssistantService: 🚀 Starting background knowledge ingestion...');
      unawaited(
        _ref.read(knowledgeIngestionServiceProvider).ingestCopilotScreencap(
          "Query: $text\nResponse: ${message.text}",
          attachment: attachment,
        ).timeout(const Duration(seconds: 120)) // Increased timeout to 120s
        .then((_) => debugPrint('AssistantService: ✅ Knowledge Auto-Ingest Complete'))
        .catchError((e) => debugPrint('AssistantService: ⚠️ Knowledge Auto-Ingest Error (Background): ${_safeError(e)}'))
      );
      
      return message;
    } catch (e) {
      debugPrint('Assistant Service Error: ${_safeError(e)}');
      final errorMsg = AssistantMessage(
        id: DateTime.now().toString(),
        text: "Sorry, I encountered an internal error. Please try again or check your connection.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _history.add(errorMsg);
      
      blackboard.addEvent(WorkflowEventType.errorOccurred, "Service Error: $e");
      
      // Persist the error state so user knows what happened on reload
      try {
        await _ref.read(persistenceServiceProvider).saveAssistantHistory(_history);
      } catch (_) {}
      return errorMsg;
    } finally {
      _ref.read(assistantStatusProvider.notifier).state = null;
    }
  }

  Future<ToolExecutionSummary> _matchIntentAndExecute(String text, List<AgentTool> tools, {List<int>? attachment, List<int>? audioAttachment, ToolMode toolMode = ToolMode.chat}) async {
    final lower = text.toLowerCase();
    
    // 0. Explicit Tool Mode Override
    if (toolMode == ToolMode.image) {
       _ref.read(assistantStatusProvider.notifier).state = "Generating image...";
       return await _executeTool(tools, 'image_generation', {'prompt': text});
    }
    if (toolMode == ToolMode.video) {
       _ref.read(assistantStatusProvider.notifier).state = "Generating video...";
       
       // Inject selected model if it's a video model
       final selectedModel = _ref.read(selectedAIModelProvider);
       String? modelId;
       // Check if selected model is a Veo model (or generally a video model)
       if (selectedModel.modelId.toLowerCase().contains('veo')) {
           modelId = selectedModel.modelId;
       }
       
       return await _executeTool(tools, 'video_generation', {
         'prompt': text,
         if (modelId != null) 'model_id': modelId
       });
    }
    if (toolMode == ToolMode.code) {
       // Code mode: Force developer context
       final systemPrompts = _ref.read(systemPromptsProvider);
       final devPrompt = "You are a Developer Agent. Generate production-ready code. \nUser Request: $text";
       _ref.read(assistantStatusProvider.notifier).state = "Writing code...";
       final res = await EdgeAIService.generateText(devPrompt, modelConfig: AIModelConfig.geminiFlash, ref: _ref);
       return ToolExecutionSummary(text: res.text, modelName: 'Gemini 2.5 Flash (Code Mode)');
    }

    // 1. Agentic Automation Orchestration
    final memoryService = _ref.read(memoryServiceProvider);
    final toolRetrieval = _ref.read(toolRetrievalServiceProvider);
    final verificationService = _ref.read(verificationServiceProvider);

    // A. Read Memory (Context)
    final longTermMemory = await memoryService.readMemory();

    // B. Intent Classification
    // Use RouterAgent to determine intent and tool selection
    final systemPrompts = _ref.read(systemPromptsProvider);
    final rawRouterPrompt = await systemPrompts.getIntentClassifierPrompt();
    final routerPrompt = rawRouterPrompt.replaceAll('{{USER_INPUT}}', text);

    RouterIntent intentEnum = RouterIntent.directChat;
    List<String> suggestedTools = [];
    
    try {
       print('DEBUG: Assistant - Setting status: Analyzing intent...');
       _ref.read(assistantStatusProvider.notifier).state = "Analyzing intent...";
       // Use RouterAgent via EdgeAIService directly for speed, or properly instantiate Agent
       final routerRes = await EdgeAIService.generateText(
          routerPrompt, 
          modelConfig: AIModelConfig.geminiFlash, // Fast router
          ref: _ref
       );
       
       final data = JsonParserService.parseJson(routerRes.text);
       
       if (data != null) {
          final intentStr = data['intent']?.toString().toUpperCase() ?? 'DIRECT_CHAT';
          
          intentEnum = RouterIntent.values.firstWhere(
            (e) => e.toString().split('.').last.toUpperCase() == intentStr, 
            orElse: () => RouterIntent.directChat
          );
          
          if (data['required_tools'] != null) {
              suggestedTools = List<String>.from(data['required_tools']);
          }
          debugPrint('Assistant: Router Intent: $intentStr, Suggested Tools: $suggestedTools');
       }
    } catch (e) {
       debugPrint('Assistant: Router failed ($e). Fallback to heuristic.');
       // Fallback Heuristic
       if (lower.contains('image') || lower.contains('video') || lower.contains('logo')) intentEnum = RouterIntent.creative;
       else if (lower.contains('search') || lower.contains('find')) intentEnum = RouterIntent.research;
    }

    // C. Dynamic Tool Loading
    // Load tools based on intent AND specific suggestions from Router
    final intentTools = toolRetrieval.getToolsForIntent(intentEnum);
    
    // Merge explicitly requested tools if available in registry
    final allTools = _ref.read(assistantToolRegistryProvider);
    final specificTools = allTools.where((t) => suggestedTools.contains(t.name)).toList();
    
    // Combine and deduplicate by name
    final Map<String, AgentTool> combinedToolsMap = {};
    for (final t in intentTools) combinedToolsMap[t.name] = t;
    for (final t in specificTools) combinedToolsMap[t.name] = t;
    
    // Naming Mismatch Fix: If "Stitch" is suggested by Router, add all stitch_* tools
    if (suggestedTools.any((s) => s.toLowerCase() == 'stitch')) {
      for (final t in allTools.where((t) => t.name.startsWith('stitch_'))) {
        combinedToolsMap[t.name] = t;
      }
    }

    // Always ensure generation and navigation tools are available
    for (final t in allTools.where((t) => 
      t.name == 'image_generation' || 
      t.name == 'video_generation' || 
      t.name == 'navigate_to' || 
      t.name == 'gen_ui_component'
    )) {
      combinedToolsMap[t.name] = t;
    }

    final combinedTools = combinedToolsMap.values.toList();

    final toolDefinitions = combinedTools.map((t) {
      final schema = t.toFunctionSchema();
      final params = (schema['parameters'] as Map?)?['properties'] ?? {};
      return "- ${t.name}: ${t.description}. Params: ${jsonEncode(params)}";
    }).join("\n");

    // D. Main Execution
    final currentMode = _ref.read(assistantModeProvider);
    final ephemeralMsg = _injectEphemeralMessages(currentMode);
    
    // State Machine & Observability Integration
    final blackboard = _ref.read(blackboardProvider.notifier);
    
    // Transition based on Intent
    if (intentEnum == RouterIntent.research || intentEnum == RouterIntent.genUiReport) {
      blackboard.transitionTo(BlackboardPhase.analyzingIntent); 
      blackboard.updateAgentStatus('TrendScout', AgentStatus.working);
      blackboard.updateAgentStatus('Strategist', AgentStatus.working);
    } else if (intentEnum == RouterIntent.creative || intentEnum == RouterIntent.creativeImage || intentEnum == RouterIntent.creativeVideo) {
       blackboard.transitionTo(BlackboardPhase.creative);
       blackboard.updateAgentStatus('Creative', AgentStatus.working);
    } else if (intentEnum == RouterIntent.management) {
       blackboard.transitionTo(BlackboardPhase.strategy);
       blackboard.updateAgentStatus('Strategist', AgentStatus.working);
    }
    // ... add more as needed
    
    // E. Knowledge Retrieval & Grounding (v2.0 Upgrade)
    String retrievedGroundingContext = "";
    List<String> groundingSources = [];
    
    final knowledgeIntents = [RouterIntent.research, RouterIntent.knowledge, RouterIntent.proposal, RouterIntent.genUiReport];
    if (knowledgeIntents.contains(intentEnum)) {
      _ref.read(assistantStatusProvider.notifier).state = "Searching knowledge base...";
      try {
        final retriever = _ref.read(knowledgeRetrieverProvider);
        final activeClientId = _ref.read(clientProvider).selectedClientId;
        if (activeClientId == null) {
          debugPrint('Assistant: No client selected — skipping knowledge grounding.');
        }
        final results = activeClientId != null
            ? await retriever.retrieve(query: text, clientId: activeClientId)
            : <KnowledgeChunkResult>[];
        
        if (results.isNotEmpty) {
           retrievedGroundingContext = retriever.formatForGrounding(results);
           groundingSources = results.map((r) => "${r.sourceTitle} (${r.platform})").toList();
           debugPrint('Assistant: Grounding successful with ${results.length} sources.');
        }
      } catch (e) {
        debugPrint('Assistant: Grounding failed: $e');
      }
    }

    final promptService = _ref.read(systemPromptsProvider);
    final brianPersona = await promptService.getBrianPrompt();

    // Build Conversation History (Last 6 messages)
    final recentHistory = _history.reversed.take(6).toList().reversed.map((m) {
      final role = m.isUser ? "User" : "Brian";
      return "$role: ${m.text}";
    }).join("\n");

    final rawMainPrompt = await systemPrompts.getAssistantMainPrompt();
    final mainPrompt = rawMainPrompt
      .replaceAll('{{BRIAN_PERSONA}}', brianPersona)
      .replaceAll('{{CURRENT_MODE}}', currentMode.toString().split('.').last.toUpperCase())
      .replaceAll('{{DETECTED_INTENT}}', intentEnum.toString().split('.').last.toUpperCase())
      .replaceAll('{{SYSTEM_MEMORY}}', longTermMemory)
      .replaceAll('{{CONVERSATION_HISTORY}}', recentHistory)
      .replaceAll('{{AVAILABLE_TOOLS}}', toolDefinitions)
      .replaceAll('{{USER_INPUT}}', text)
      .replaceAll('{{EPHEMERAL_MESSAGE}}', ephemeralMsg)
      .replaceAll('{{KNOWLEDGE_GROUNDING}}', retrievedGroundingContext);

    // Semantic Cache Check
    final semanticCache = _ref.read(semanticCacheServiceProvider);
    final cachedResponse = await semanticCache.lookup(intentEnum.toString().split('.').last, mainPrompt);
    if (cachedResponse != null) {
      debugPrint('Assistant: Cache Hit! Returning cached response.');
      // Update blackboard to reflect "fast" path
      blackboard.postFact('cacheHit', true);
      // Reset agent status
      blackboard.updateAgentStatus('TrendScout', AgentStatus.idle);
      blackboard.updateAgentStatus('Creative', AgentStatus.idle);
      blackboard.updateAgentStatus('Strategist', AgentStatus.idle);

      return ToolExecutionSummary(text: cachedResponse);
    }

    String responseText = "";
    
    // DIRECT EDGE AI SERVICE (Primary)
    List<String>? sources;
    try {
      _ref.read(assistantStatusProvider.notifier).state = "Thinking...";
      
      // SPECIAL HANDLING: Deep Research & Reports
      if (intentEnum == RouterIntent.research || intentEnum == RouterIntent.genUiReport) {
          debugPrint('Assistant: 🕵️ Routing to ReportsService for Deep Research/Report...');
          _ref.read(blackboardProvider.notifier).updateAgentStatus('TrendScout', AgentStatus.working);
          
          final reportsService = _ref.read(reportsServiceProvider);
          final reportClientId = _ref.read(clientProvider).selectedClientId ?? 'unassigned';
          final report = await reportsService.generateReport(
              title: "Research: ${text.length > 30 ? text.substring(0, 30) + '...' : text}",
              prompt: text,
              userId: "user_current",
              clientId: reportClientId,
              useDeepResearch: intentEnum == RouterIntent.research // Use Deep Research for 'research' intent
          );
          
          // Construct UI Payload for GenUI (Report View)
          Map<String, dynamic> reportData = {};
          if (report.outputs.isNotEmpty && report.outputs[0].content != null) {
              try {
                  reportData = jsonDecode(report.outputs[0].content!);
              } catch (e) {
                  debugPrint('Assistant: Failed to parse report JSON: $e');
                  reportData = {'raw_content': report.outputs[0].content};
              }
          }
          
          return ToolExecutionSummary(
              text: "I've completed the research and generated a detailed report for you.",
              modelName: 'Gemini 3.0 Pro (Deep Research)',
              uiPayload: {
                  'type': 'deep_analysis',
                  'id': report.id,
                  'title': report.title,
                  'client_id': report.clientId,
                  'created_at': report.createdAt.toIso8601String(),
                  ...reportData
              }
          );
      }

      // 1. Determine base config based on user selection or intent safety
      final userSelectedModel = _ref.read(selectedAIModelProvider);
      AIModelConfig mainConfig;
      
      final textLower = text.toLowerCase();
      final isComplexIntent = intentEnum == RouterIntent.management || 
                            intentEnum == RouterIntent.copywriting ||
                            intentEnum == RouterIntent.creative ||
                            intentEnum == RouterIntent.creativeImage ||
                            intentEnum == RouterIntent.creativeVideo ||
                            intentEnum == RouterIntent.proposal;
      
      final forcesPro = textLower.contains('video') || 
                       textLower.contains('generate a video') || 
                       textLower.contains('create a video') ||
                       textLower.contains('checklist');

      // Priority: 
      // 1. User selected a non-default model -> Use it
      // 2. Intent forces Pro -> Use Pro
      // 3. Otherwise -> Use Flash (Default)
      
      if (userSelectedModel != AIModelConfig.geminiFlash) {
        mainConfig = userSelectedModel;
      } else if (isComplexIntent || forcesPro) {
        mainConfig = AIModelConfig.geminiPro.copyWith(useGoogleSearch: true);
      } else {
        mainConfig = AIModelConfig.geminiFlash;
      }
      
      final edgeResult = await EdgeAIService.generateText(
        mainPrompt,
        modelConfig: mainConfig,
        ref: _ref,
        imageBytes: attachment != null ? Uint8List.fromList(attachment) : null,
        tools: combinedTools.map((t) => t.toFunctionSchema()).toList(),
      );

      sources = edgeResult.sourceCitations;
      
      print('DEBUG: Assistant - Received AI Response: ${edgeResult.text.substring(0, edgeResult.text.length > 50 ? 50 : edgeResult.text.length)}...');
      
      responseText = edgeResult.text;
      
      // Parse JSON from EdgeAI response using JsonParserService
      final parsed = JsonParserService.parseJson(responseText);
      debugPrint('Assistant: Parsed Object: $parsed');

      if (parsed != null) {
          debugPrint('Assistant: JSON decode successful. Keys: ${parsed.keys.toList()}');
          String? toolName;
          Map<String, dynamic>? toolArgs;

          // Helper for fuzzy key access
          dynamic getFuzzy(Map map, String key) {
            if (map.containsKey(key)) return map[key];
            final matchingKey = map.keys.firstWhere(
              (k) => k.toString().toLowerCase().trim() == key.toLowerCase(), 
              orElse: () => null
            );
            return matchingKey != null ? map[matchingKey] : null;
          }

           if (parsed.containsKey('tool')) {
             toolName = parsed['tool'];
             toolArgs = Map<String, dynamic>.from(parsed['args'] ?? parsed['parameters'] ?? {});
           } else if (parsed.containsKey('name') && (parsed.containsKey('args') || parsed.containsKey('parameters'))) {
             // NEW: Support for {"name": "tool_name", "args": {...}}
             toolName = parsed['name'];
             toolArgs = Map<String, dynamic>.from(parsed['args'] ?? parsed['parameters'] ?? {});
           } else if (parsed.containsKey('call')) {
             // NEW: Support for {"call": {"function_name": "...", "args": ...}} (Gemini 2.5/3 Proxy Format)
             print('DEBUG: Found "call" key in parsed JSON.');
             final call = parsed['call'];
             print('DEBUG: "call" value: $call');
             print('DEBUG: "call" type: ${call.runtimeType}');
             
             if (call is Map) {
                // Ensure it's a Map<String, dynamic>
                final callMap = Map<String, dynamic>.from(call);
                print('DEBUG: callMap keys: ${callMap.keys}');
                
                // Handle "google:image_generation" -> "image_generation"
                String rawName = callMap['function_name'] ?? callMap['function'] ?? callMap['name'] ?? '';
                print('DEBUG: extracted rawName: "$rawName"');
                
                if (rawName.contains(':')) {
                   rawName = rawName.split(':').last;
                }
                toolName = rawName;
                
                final args = callMap['args'] ?? callMap['arguments'] ?? callMap['parameters'] ?? {};
                print('DEBUG: extracted args: $args');
                if (args is Map) {
                   toolArgs = Map<String, dynamic>.from(args);
                } else {
                   print('DEBUG: Args is not a map! Type: ${args.runtimeType}');
                   toolArgs = {};
                }
             } else {
                print('DEBUG: "call" is NOT a Map.');
             }
           } else if (parsed.containsKey('functionCall')) {
             // NATIVE GEMINI FORMAT (passed through proxy)
             final call = parsed['functionCall'];
             if (call is Map) {
                toolName = call['name'];
                toolArgs = Map<String, dynamic>.from(call['args'] ?? {});
             }
            } else if (getFuzzy(parsed, 'tool_calls') != null) {
              debugPrint('Assistant: 🛠️ Found tool_calls in JSON response (Fuzzy Match)');
              final calls = getFuzzy(parsed, 'tool_calls');
              if (calls is List && calls.isNotEmpty) {
                 final call = calls[0];
                 debugPrint('Assistant: 🛠️ Processing first tool call: $call');
                 if (call is Map) {
                    // Standard OpenAI/Gemini format uses 'function'
                    if (call.containsKey('function')) {
                       final function = call['function'];
                       debugPrint('Assistant: 🛠️ Found function object: $function');
                       if (function is Map) {
                          toolName = function['name'];
                          final dynamic args = function['arguments'];
                          if (args is String) {
                            try {
                              toolArgs = Map<String, dynamic>.from(jsonDecode(args));
                            } catch (e) {
                              debugPrint('Assistant: ❌ Failed to decode tool_calls function arguments (String): $e');
                            }
                          } else if (args is Map) {
                            toolArgs = Map<String, dynamic>.from(args);
                          }
                       }
                    } else {
                       // Custom/Direct format: {"tool": "...", "args": {...}} inside the list
                       toolName = call['tool'] ?? call['name'] ?? call['type'];
                       final dynamic args = call['args'] ?? call['parameters'] ?? call['arguments'];
                       if (args is String) {
                         try {
                           toolArgs = Map<String, dynamic>.from(jsonDecode(args));
                         } catch (e) {
                           debugPrint('Assistant: ❌ Failed to decode tool_calls direct arguments (String): $e');
                         }
                       } else if (args is Map) {
                         toolArgs = Map<String, dynamic>.from(args);
                       }
                    }
                 }
              }
            } else if (parsed.containsKey('candidates')) {
              // GEMINI PROXY RESPONSE (Start)
              final candidates = parsed['candidates'];
              if (candidates is List && candidates.isNotEmpty) {
                 final candidate = candidates[0];
                 if (candidate is Map && candidate.containsKey('content')) {
                    final content = candidate['content'];
                    if (content is Map && content.containsKey('parts')) {
                       final parts = content['parts'];
                       if (parts is List && parts.isNotEmpty) {
                          for (final part in parts) {
                             if (part is Map) {
                                if (part.containsKey('call')) {
                                   final call = part['call'];
                                   if (call is Map) {
                                      String rawName = call['function_name'] ?? call['function'] ?? call['name'] ?? '';
                                      if (rawName.contains(':')) rawName = rawName.split(':').last;
                                      toolName = rawName;
                                      final args = call['args'] ?? call['arguments'] ?? call['parameters'] ?? {};
                                      toolArgs = args is Map<String, dynamic> ? args : Map<String, dynamic>.from(args as Map);
                                      break;
                                   }
                                } else if (part.containsKey('functionCall')) {
                                   final call = part['functionCall'];
                                   if (call is Map) {
                                      toolName = call['name'];
                                      toolArgs = Map<String, dynamic>.from(call['args'] ?? {});
                                      break;
                                   }
                                }
                             }
                          }
                       }
                    }
                 }
              }
            } else if (parsed.containsKey('component_type') && parsed.containsKey('data')) {
             // DIRECT COMPONENT OUTPUT SUPPORT
             toolName = 'gen_ui_component';
              toolArgs = Map<String, dynamic>.from(parsed);
           } else {
              // Fallback: Check if the root key corresponds to a known tool
              // e.g. {"video_generation": {"prompt": "..."}}
              for (final tool in combinedTools) {
                 if (parsed.containsKey(tool.name)) {
                    toolName = tool.name;
                    final inner = parsed[tool.name];
                    if (inner is Map) {
                       toolArgs = Map<String, dynamic>.from(inner);
                    }
                    break;
                 }
              }
           }

           // FINAL FALLBACK: Deep Search / Wrapper Unwrap
           // e.g. { "executable_adunit": { "call": { "function_name": "...", ... } } }
           if (toolName == null) {
              print('Assistant: 🕵️ Standard parsing failed. Attempting deep search for tool call...');
              
              void searchMap(Map<dynamic, dynamic> map) {
                  if (toolName != null) return; // Found it

                  // Case A: Map has "call" -> { "function_name": ... }
                  if (map.containsKey('call')) {
                      final call = map['call'];
                      if (call is Map) {
                          final fName = call['function_name'] ?? call['function'] ?? call['name'];
                          if (fName != null && fName is String) {
                             String rawName = fName;
                             if (rawName.contains(':')) rawName = rawName.split(':').last;
                             toolName = rawName;
                             toolArgs = Map<String, dynamic>.from(call['args'] ?? call['arguments'] ?? call['parameters'] ?? {});
                             print('Assistant: 🎯 Deep search found nested "call" object. Tool: $toolName');
                             return;
                          }
                      }
                  }

                  // Case B: Map IS the call -> { "function_name": ... }
                  // Only valid if clearly a function object, careful not to match random maps
                  if (map.containsKey('function_name') && (map.containsKey('args') || map.containsKey('arguments'))) {
                      final fName = map['function_name'];
                      if (fName is String) {
                          String rawName = fName;
                          if (rawName.contains(':')) rawName = rawName.split(':').last;
                          toolName = rawName;
                          toolArgs = Map<String, dynamic>.from(map['args'] ?? map['arguments'] ?? map['parameters'] ?? {});
                          print('Assistant: 🎯 Deep search found direct function object. Tool: $toolName');
                          return;
                      }
                  }

                  // Recurse
                  for (final value in map.values) {
                      if (value is Map) {
                          searchMap(value);
                      } else if (value is List) {
                          for (final item in value) {
                              if (item is Map) {
                                  searchMap(item);
                              }
                          }
                      }
                      if (toolName != null) return;
                  }
              }

              searchMap(parsed);
           }

           debugPrint('Assistant: 🕵️ Resolved toolName: $toolName');
           debugPrint('Assistant: 🕵️ Resolved toolArgs keys: ${toolArgs?.keys}');

           if (toolName != null && toolArgs != null) {
             final String safeToolName = toolName!;
             Map<String, dynamic> safeToolArgs = toolArgs!;

             if (safeToolArgs.containsKey('args') && safeToolArgs['args'] is Map) {
               safeToolArgs = Map<String, dynamic>.from(safeToolArgs['args']);
             }
             debugPrint('Assistant: ✅ Attempting to execute tool: $safeToolName');
             _ref.read(assistantStatusProvider.notifier).state = "Using $safeToolName...";
             final result = await _executeTool(combinedTools.toList(), safeToolName, safeToolArgs);
             _ref.read(assistantStatusProvider.notifier).state = null;
             debugPrint('Assistant: 🏁 Tool execution completed for: $safeToolName');
             return result;
           } else {
              debugPrint('Assistant: ⚠️ JSON parsed but toolName or toolArgs is still null.');
              debugPrint('Assistant: Raw parsed response: $parsed');
           }

           // BRIAN ORCHESTRATION EXTRACTION
           final hasOrchestration = parsed.containsKey('subtasks') || 
                                  parsed.containsKey('final_output') ||
                                  parsed.containsKey('subtareas') ||
                                  parsed.containsKey('salida_final');
           
           if (hasOrchestration) {
             debugPrint('Assistant: Detected Brian Orchestration JSON');
             final blackboard = _ref.read(blackboardProvider.notifier);
             final subtasks = parsed['subtasks'] ?? parsed['subtareas'];
             if (subtasks is List) {
               for (var task in subtasks) {
                 blackboard.addEvent(WorkflowEventType.agentAction, "Brian Plan: $task");
               }
             }
             final output = parsed['final_output'] ?? parsed['salida_final'] ?? responseText;
             final notes = parsed['verification_notes'] ?? parsed['notas_verificacion'];
             if (notes != null) {
               blackboard.postFact('verification_notes', notes);
             }
             return ToolExecutionSummary(text: output.toString());
           }
      }

      // If no tool was executed, responseText remains the raw text
    } catch (e) {
      debugPrint('Assistant AI Error: $e');
      return ToolExecutionSummary(text: "I encountered an error while processing your request: $e");
    }


    // ... Verification Layer ...
    bool needsVerification = intentEnum == RouterIntent.research || intentEnum == RouterIntent.copywriting;
    if (needsVerification && responseText.length > 50) {
       final verifiedResponse = await verificationService.verifyOutput(text, responseText);
       // Reset agents
       blackboard.updateAgentStatus('TrendScout', AgentStatus.idle);
       blackboard.updateAgentStatus('Creative', AgentStatus.idle);
       blackboard.updateAgentStatus('Strategist', AgentStatus.idle);
       
       // Store in Cache
       await semanticCache.store(intentEnum.toString().split('.').last, mainPrompt, verifiedResponse);
       
       return ToolExecutionSummary(text: verifiedResponse);
    }

    // Reset agents
    blackboard.updateAgentStatus('TrendScout', AgentStatus.idle);
    blackboard.updateAgentStatus('Creative', AgentStatus.idle);
    blackboard.updateAgentStatus('Strategist', AgentStatus.idle);

    // Store in Cache (only if valid/successful/real)
    final isMock = responseText.contains("Mock") || 
                   responseText.contains("Simulated") || 
                   responseText.contains("unavailable");
    
    if (!isMock &&
        !responseText.contains("No content generated") && 
        !responseText.contains("I encountered an error") &&
        responseText.length > 20) {
      await semanticCache.store(intentEnum.toString().split('.').last, mainPrompt, responseText);
    }

    return ToolExecutionSummary(
      text: responseText, 
      sources: sources
    );
  }

  Future<ToolExecutionSummary> _executeTool(List<AgentTool> tools, String name, Map<String, dynamic> args) async {
    final tool = tools.firstWhere((t) => t.name == name, orElse: () => throw Exception('Tool not found: $name'));
    try {
      final result = await tool.execute(args, ref: _ref);
      if (result.isSuccess) {
        if (name == 'image_generation') {
          return ToolExecutionSummary(
            text: "Here is the generated image based on your prompt: \"${args['prompt']}\"",
            assetPath: result.data['url'],
            assetType: 'image'
          );
        }
        if (name == 'video_generation') {
          return ToolExecutionSummary(
            text: "I've created a video for you: \"${args['prompt']}\"",
            assetPath: result.data['url'],
            assetType: 'video'
          );
        }
        if (name == 'create_artifact') {
             final artifact = Artifact(
               id: DateTime.now().toString(),
               title: args['title'] ?? 'Untitled',
               type: ArtifactType.values.firstWhere((e) => e.toString().split('.').last == args['type'], orElse: () => ArtifactType.markdown),
               content: args['content'] ?? '',
               updatedAt: DateTime.now(),
             );
             return ToolExecutionSummary(
               text: "Created artifact: ${artifact.title}",
               artifacts: [artifact]
             );
        }
        if (name == 'gen_ui_component' || name == 'render_gen_ui') {
             final rawData = args['data'];
             final Map<String, dynamic> safeData = (rawData is Map) 
                 ? Map<String, dynamic>.from(rawData)
                 : {'error': 'Invalid data format from AI'};

             String summary = args['summary_text'] ?? "I've generated a visual component for you.";
             if (summary.length > 250) {
                summary = "${summary.substring(0, 247).trim()}...";
             }

             return ToolExecutionSummary(
               text: summary,
               uiPayload: {
                 'type': args['component_type'],
                 ...safeData,
               },
             );
        }
        print('DEBUG: Assistant - _executeTool result success for tool: $name');
        print('DEBUG: Assistant - result.data: ${jsonEncode(result.data)}');
        
        // Normalize tool name check
        final normalizedName = name.toLowerCase().trim();
        if (normalizedName == 'web_search' || normalizedName == 'search_web' || normalizedName == 'search') {
             print('DEBUG: Assistant - Matched web_search tool output block');
             final results = result.data['results'] as List?;
             final List<String> sources = [];
             String summary = "I've researched market trends for your request.\n\n";
             
             if (results != null) {
               for (var r in results) {
                 if (r is Map) {
                   sources.add(r['url'] ?? '');
                   summary += "- **${r['title']}**: ${r['snippet']}\n";
                 }
               }
             }

             return ToolExecutionSummary(
               text: summary,
               sources: sources,
             );
        }
        if (name == 'direct_scene') {
              // Real-time update for Dialogue Scenes
              _ref.read(dialogueSceneCommandProvider.notifier).state = {
                'action': args['action'],
                'params': args['params'],
              };
              return ToolExecutionSummary(text: result.data['message'] ?? 'Scene updated.');
        }
        return ToolExecutionSummary(text: "Executed $name successfully.\n\n```json\n${jsonEncode(result.data)}\n```");
      } else {
        return ToolExecutionSummary(text: "Error executing $name: ${result.errorMessage}");
      }
    } catch (e) {
      return ToolExecutionSummary(text: "System error: $e");
    }
  }

  void clearHistory() {
    _history.clear();
  }

  String _injectEphemeralMessages(AssistantMode mode) {
    if (mode == AssistantMode.planning) {
       // Check if there are recent artifacts or if the user is asking strictly for a plan
       // For now, inject a static reminder
       return '''
<EPHEMERAL_REMINDER>
You are in Planning Mode. If the user's request is complex, create an artifact using 'create_artifact' tool.
Format: {"tool": "create_artifact", "args": {"title": "Title", "type": "markdown", "content": "..."}}
</EPHEMERAL_REMINDER>
''';
    }
    return "";
  }

  static String _safeError(dynamic e) {
    if (e == null) return "Unknown Error (null)";
    try {
      final dynamic err = e;
      return err.toString();
    } catch (_) {
      try {
        return "$e";
      } catch (e2) {
        return "Internal error parsing exception stack";
      }
    }
  }
}

class ToolExecutionSummary {
  final String text;
  final String? assetPath;
  final String? assetType; // 'image', 'video'
  final String? modelName;
  final List<String>? sources;
  final List<Artifact>? artifacts;
  final Map<String, dynamic>? uiPayload;

  ToolExecutionSummary({
    required this.text, 
    this.assetPath, 
    this.assetType,
    this.modelName,
    this.sources,
    this.artifacts,
    this.uiPayload,
  });

  String get displayText => text;
}

final assistantServiceProvider = Provider<AssistantService>((ref) => AssistantService(ref));
final assistantModeProvider = StateProvider<AssistantMode>((ref) => AssistantMode.fast);
