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
import '../../../core/architecture/memory.dart';
import 'package:ag_ui/ag_ui.dart';

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
  };

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
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
    );
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

  Future<AssistantMessage> sendMessage(String text, {List<int>? attachment, List<int>? audioAttachment}) async {
    // 1. Add user message
    final userMsg = AssistantMessage(
      id: DateTime.now().toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      attachment: attachment,
      audioAttachment: audioAttachment,
    );
    _history.add(userMsg);
    await _ref.read(persistenceServiceProvider).saveAssistantHistory(_history);

    // 2. Initialize Blackboard for this request (Blackboard Pattern)
    final blackboard = _ref.read(blackboardProvider.notifier);
    blackboard.clear();
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
      final executionResult = await _matchIntentAndExecute(text, tools, attachment: attachment, audioAttachment: audioAttachment);
      
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
        modelName: executionResult.modelName ?? 'Gemini 2.0 Flash',
        processingTime: stopwatch.elapsed,
        sources: executionResult.sources,
        artifacts: executionResult.artifacts,
      );

      _history.add(message);
      await _ref.read(persistenceServiceProvider).saveAssistantHistory(_history);
      
      // Update Blackboard with final result
      blackboard.postFact('finalResponse', message.text);
      if (message.artifacts != null) {
        blackboard.postFact('artifacts', message.artifacts!.map((a) => a.toJson()).toList());
      }
      
      try {
        await _ref.read(knowledgeIngestionServiceProvider).ingestCopilotScreencap(
          "Query: $text\nResponse: ${message.text}",
          attachment: attachment,
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('Knowledge Auto-Ingest Error: ${_safeError(e)}');
      }
      
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
    }
  }

  Future<ToolExecutionSummary> _matchIntentAndExecute(String text, List<AgentTool> tools, {List<int>? attachment, List<int>? audioAttachment}) async {
    final lower = text.toLowerCase();
    
    // 1. Agentic Automation Orchestration
    final memoryService = _ref.read(memoryServiceProvider);
    final toolRetrieval = _ref.read(toolRetrievalServiceProvider);
    final verificationService = _ref.read(verificationServiceProvider);

    // A. Read Memory (Context)
    final longTermMemory = await memoryService.readMemory();

    // B. Intent Classification
    // Use RouterAgent to determine intent and tool selection
    final routerPrompt = """
Analyze the user's request and determine the user's intent.
User Input: "$text"

Classify into one of:
- CREATIVE: User wants to GENERATE or CREATE an image, video, logo, or artistic asset.
- RESEARCH: User is asking for facts, searching for info, or analysis.
- MANAGEMENT: User wants to create/manage clients, campaigns, or tasks.
- DEVELOPMENT: User is asking for code or technical help.
- DIRECT_CHAT: Simple conversation or greeting.

Return ONLY a JSON object:
{
  "intent": "INTENT_NAME",
  "confidence": 0.9,
  "required_tools": ["tool_name_1", "tool_name_2"]
}
""";

    RouterIntent intentEnum = RouterIntent.directChat;
    List<String> suggestedTools = [];
    
    try {
       // Use RouterAgent via EdgeAIService directly for speed, or properly instantiate Agent
       final routerRes = await EdgeAIService.generateText(
          routerPrompt, 
          modelConfig: const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-2.0-flash'), // Fast router
          ref: _ref
       );
       
       final rawText = routerRes.text.trim();
       final jsonStart = rawText.indexOf('{');
       final jsonEnd = rawText.lastIndexOf('}');
       
       if (jsonStart != -1 && jsonEnd != -1) {
          final jsonStr = rawText.substring(jsonStart, jsonEnd + 1);
          final data = jsonDecode(jsonStr);
          final intentStr = data['intent']?.toString().toUpperCase() ?? 'DIRECT_CHAT';
          
          intentEnum = RouterIntent.values.firstWhere(
            (e) => e.name.toUpperCase() == intentStr, 
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
    
    // Combine and deduplicate
    final Set<AgentTool> combinedTools = {...intentTools, ...specificTools};
    
    // Always ensure generation and navigation tools are available
    combinedTools.addAll(allTools.where((t) => 
      t.name == 'image_generation' || 
      t.name == 'video_generation' || 
      t.name == 'navigate_to' || 
      t.name == 'gen_ui_component'
    ));

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
    if (intentEnum == RouterIntent.research) {
      blackboard.transitionTo(BlackboardPhase.analyzingIntent); // Or specific research phase
      blackboard.updateAgentStatus('TrendScout', AgentStatus.working);
    } else if (intentEnum == RouterIntent.creative) {
       blackboard.transitionTo(BlackboardPhase.creative);
       blackboard.updateAgentStatus('Creative', AgentStatus.working);
    } else if (intentEnum == RouterIntent.management) {
       blackboard.transitionTo(BlackboardPhase.strategy);
       blackboard.updateAgentStatus('Strategist', AgentStatus.working);
    }
    // ... add more as needed

    final mainPrompt = """
You are Brian, the Inhaus Brain Copilot.
You are deeply integrated into the Inhaus Brain web/desktop application.
You HAVE the power to navigate the interface, generate media, and orchestrate commerce.
NEVER claim you are 'just an AI' or 'cannot access settings'—you have tools explicitly for these tasks.

Context:
- Current Mode: ${currentMode.name.toUpperCase()}
- Detected Intent: ${intentEnum.name.toUpperCase()}
- System Memory: $longTermMemory

AVAILABLE TOOLS:
$toolDefinitions

VISION/MULTIMODAL:
- I can see attached images (Gemini 1.5 Flash).
- I generate images via 'image_generation'.
- I generate videos via 'video_generation'.

User Input: "$text"

CRITICAL INSTRUCTIONS:
1. If the user wants to navigate (e.g., "go to settings", "show campaigns"), YOU MUST use the 'navigate_to' tool.
2. If the user wants an image or video, YOU MUST use the corresponding generation tool.
3. To use a tool, return ONLY a JSON object: {"tool": "name", "args": {...}}.
4. DO NOT explain yourself first. DO NOT wrap JSON in code blocks.
5. If NO tool applies, answer helpfully with rich Markdown.

$ephemeralMsg
""";

    // Semantic Cache Check
    final semanticCache = _ref.read(semanticCacheServiceProvider);
    final cachedResponse = await semanticCache.lookup(intentEnum.name, mainPrompt);
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
    // CopilotKit bypassed due to protocol errors
    try {
      final edgeResult = await EdgeAIService.generateText(
        mainPrompt,
        modelConfig: const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-2.0-flash'),
        apiKey: null, // Use internal tokens
        ref: _ref,
        imageBytes: attachment != null ? Uint8List.fromList(attachment) : null,
      );
      
      responseText = edgeResult.text;
      
      // Parse JSON from EdgeAI response if present
      String cleanResponse = responseText.trim();
      
      // 1. Strip Markdown Code Blocks
      final codeBlockRegex = RegExp(r'```(?:json)?\s*(.*?)\s*```', dotAll: true);
      final matches = codeBlockRegex.allMatches(cleanResponse);

      if (matches.isNotEmpty) {
        bool foundJson = false;
        for (final match in matches) {
           final content = match.group(1)!.trim();
           if (content.startsWith('{') && content.endsWith('}')) {
             try {
                final safeContent = content.replaceAllMapped(RegExp(r'(?<=: ")(.*?)(?=")', dotAll: true), (m) {
                     return m.group(0)?.replaceAll('\n', '\\n') ?? '';
                });
                jsonDecode(safeContent);
                cleanResponse = content; 
                foundJson = true;
                break;
             } catch (_) {}
           }
        }
        if (!foundJson) {
           cleanResponse = cleanResponse.replaceAll(RegExp(r'```\w*\n?'), '').replaceAll('```', '');
        }
      }

      // 2. Find JSON Object
      int jsonStart = cleanResponse.indexOf('{');
      int jsonEnd = cleanResponse.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        var jsonStr = cleanResponse.substring(jsonStart, jsonEnd + 1);
        jsonStr = jsonStr.replaceAllMapped(RegExp(r'(?<=: ")(.*?)(?=")', dotAll: true), (match) {
             return match.group(0)?.replaceAll('\n', '\\n') ?? '';
        });

        try {
          final dynamic parsed = jsonDecode(jsonStr);
          if (parsed is Map<String, dynamic>) {
             String? toolName;
             Map<String, dynamic>? toolArgs;

             if (parsed.containsKey('tool')) {
               toolName = parsed['tool'];
               toolArgs = Map<String, dynamic>.from(parsed['args'] ?? parsed['parameters'] ?? {});
             } else {
               // Heuristic inference
               final prefix = cleanResponse.substring(0, jsonStart).trim();
               final funcMatch = RegExp(r'([a-zA-Z0-9_]+)\s*\($').firstMatch(prefix);
               if (funcMatch != null) {
                 toolName = funcMatch.group(1);
                 toolArgs = parsed;
               }
             }

             if (toolName != null && toolArgs != null) {
               if (toolArgs.containsKey('args') && toolArgs['args'] is Map) {
                 toolArgs = Map<String, dynamic>.from(toolArgs['args']);
               }
               return await _executeTool(combinedTools.toList(), toolName, toolArgs);
             }
          }
        } catch (e) {
           debugPrint('Assistant: Failed to parse tool JSON: $e');
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
       await semanticCache.store(intentEnum.name, mainPrompt, verifiedResponse);
       
       return ToolExecutionSummary(text: verifiedResponse);
    }

    // Reset agents
    blackboard.updateAgentStatus('TrendScout', AgentStatus.idle);
    blackboard.updateAgentStatus('Creative', AgentStatus.idle);
    blackboard.updateAgentStatus('Strategist', AgentStatus.idle);

    // Store in Cache
    await semanticCache.store(intentEnum.name, mainPrompt, responseText);

    return ToolExecutionSummary(text: responseText);
  }


  Future<ToolExecutionSummary> _executeTool(List<AgentTool> tools, String name, Map<String, dynamic> args) async {
    final tool = tools.firstWhere((t) => t.name == name, orElse: () => throw Exception('Tool not found: $name'));
    try {
      final result = await tool.execute(args);
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
               type: ArtifactType.values.firstWhere((e) => e.name == args['type'], orElse: () => ArtifactType.markdown),
               content: args['content'] ?? '',
               updatedAt: DateTime.now(),
             );
             return ToolExecutionSummary(
               text: "Created artifact: \${artifact.title}",
               artifacts: [artifact]
             );
        }
        if (name == 'gen_ui_component' || name == 'render_gen_ui') {
             return ToolExecutionSummary(
               text: args['summary_text'] ?? "I've generated a visual component for you.",
               uiPayload: {
                 'type': args['component_type'],
                 ...Map<String, dynamic>.from(args['data'] ?? {}),
               },
             );
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

  String get _planningModeInstructions => '''
5. You are in PLANNING mode. Prioritize creating detailed plans and artifacts.
6. Use the 'create_artifact' tool to generate documents (plans, code snippets, etc.).
7. Before executing complex tasks, ALWAYS propose a plan.
''';

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
