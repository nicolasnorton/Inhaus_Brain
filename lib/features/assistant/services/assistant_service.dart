import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/features/knowledge/providers/knowledge_service_providers.dart';
import 'assistant_tool_registry.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../chat/services/memory_service.dart';
import '../../chat/services/tool_retrieval_service.dart';
import '../../chat/services/verification_service.dart';
import '../../chat/agents/router_agent.dart';
import '../../../core/services/local_persistence_service.dart';
import '../../chat/models/chat_models.dart'; // For Artifact model

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

    try {
      // 2. Simulate AI Intent Matching
      final stopwatch = Stopwatch()..start();
      
      final tools = _ref.read(assistantToolRegistryProvider);
      final executionResult = await _matchIntentAndExecute(text, tools, attachment: attachment, audioAttachment: audioAttachment);
      
      stopwatch.stop();

      // 3. Add response
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
    // Reuse existing heuristic for speed if API not available, or use Router properly
    // For this 'Super Assistant' upgrade, let's try to be smart about Intent.
    
    String intentStr = "DIRECT_CHAT";
    final creativeKeywords = ['image', 'logo', 'picture', 'painting', 'sketch', 'drawing', 'art', 'photo', 'video', 'movie', 'clip', 'footage'];
    final creationVerbs = ['generate', 'create', 'make', 'draw', 'design', 'render'];
    
    bool isCreative = false;
    // Check if any creative keyword is present
    if (creativeKeywords.any((k) => lower.contains(k))) {
       // If it contains a creation verb OR specific strong nouns like 'image', it's likely creative
       if (creationVerbs.any((v) => lower.contains(v)) || lower.contains('image') || lower.contains('video')) {
          isCreative = true;
       }
    }

    if (isCreative) {
       intentStr = "CREATIVE";
    } else if (lower.contains('research') || lower.contains('find') || lower.contains('search')) {
       intentStr = "RESEARCH";
    } else if (lower.contains('add') || lower.contains('create') || lower.contains('build') || lower.contains('new')) {
       // "Create" falls here ONLY if not caught by Creative logic above
       intentStr = "MANAGEMENT";
    }

    final intentEnum = RouterIntent.values.firstWhere(
      (e) => e.name.toUpperCase() == intentStr.toUpperCase(), 
      orElse: () => RouterIntent.directChat
    );

    // C. Dynamic Tool Loading
    final relevantTools = toolRetrieval.getToolsForIntent(intentEnum);
    final toolDefinitions = relevantTools.map((t) => "- ${t.name}: ${t.description}").join("\n");

    // D. Main Execution
    final currentMode = _ref.read(assistantModeProvider);
    final ephemeralMsg = _injectEphemeralMessages(currentMode);

    final mainPrompt = """
You are Brian, the Inhaus Brain Copilot.
Current Mode: ${currentMode.name.toUpperCase()}
Intent: $intentStr
Memory Context:
$longTermMemory

Available Tools:
$toolDefinitions

VISION CAPABILITY: I can see any images you attach. I use Gemini 1.5 Flash/Pro for visual reasoning.
MULTIMODAL CAPABILITY: I can generate images using Imagen 3 and videos using Veo.

User Input: "$text"

Instructions:
1. If the user wants to generate an image or video, YOU MUST use the 'image_generation' or 'video_generation' tool.
2. If using a tool, return ONLY a JSON object: {"tool": "name", "args": {...}}. 
3. Do NOT wrap the JSON in markdown code blocks.
4. If no tool matches, answer helpfully using rich Markdown formatting.
${currentMode == AssistantMode.planning ? _planningModeInstructions : ""}

$ephemeralMsg
""";

    String responseText = "";
    try {
      final aiRes = await EdgeAIService.generateText(
        mainPrompt, 
        ref: _ref,
        imageBytes: attachment != null ? Uint8List.fromList(attachment) : null,
        audioBytes: audioAttachment != null ? Uint8List.fromList(audioAttachment) : null,
      );
      final rawResponse = aiRes.text.trim();
      debugPrint('Assistant: AI Raw Response: "$rawResponse"');
      // Robust Parsing (Markdown + Function Call Support)
      String cleanResponse = rawResponse.trim();
      
      // 1. Strip Markdown Code Blocks (Iterate all matches to find JSON)
      final codeBlockRegex = RegExp(r'```(?:json)?\s*(.*?)\s*```', dotAll: true);
      final matches = codeBlockRegex.allMatches(cleanResponse);
      
      // If code blocks exist, try to parse ANY of them as JSON
      if (matches.isNotEmpty) {
        bool foundJson = false;
        for (final match in matches) {
           final content = match.group(1)!.trim();
           // Quick check if it looks like a JSON object
           if (content.startsWith('{') && content.endsWith('}')) {
             try {
                // validation logic duplicated for safety
                final safeContent = content.replaceAllMapped(RegExp(r'(?<=: ")(.*?)(?=")', dotAll: true), (m) {
                     return m.group(0)?.replaceAll('\n', '\\n') ?? '';
                });
                jsonDecode(safeContent);
                cleanResponse = content; // Found valid JSON block!
                foundJson = true;
                break;
             } catch (_) {
                // Not valid JSON, continue searching
             }
           }
        }
        // If we found code blocks but none were valid JSON, we might fallback to raw text 
        // OR if the model gave us python print statements, we might want to extract from there.
        // For now, if we didn't find specific JSON block, let's fall back to the largest bracketed section in the WHOLE text
        // assuming the Main extraction logic below handles it.
        if (!foundJson) {
           // If we have a python script, maybe we ignore the script wrapper and just look at the raw text 
           // but the raw text IS the script. 
           // Let's just strip the ``` markers and let the bracket finder do its work.
           cleanResponse = cleanResponse.replaceAll(RegExp(r'```\w*\n?'), '').replaceAll('```', '');
        }
      }

      // 2. Find JSON Object
      int jsonStart = cleanResponse.indexOf('{');
      int jsonEnd = cleanResponse.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        var jsonStr = cleanResponse.substring(jsonStart, jsonEnd + 1);
        debugPrint('Assistant: Found JSON block candidate: $jsonStr');
        
        // Validation: Create a safe JSON string by escaping unescaped newlines
        // This handles cases where models output multi-line strings invalidly
        jsonStr = jsonStr.replaceAllMapped(RegExp(r'(?<=: ")(.*?)(?=")', dotAll: true), (match) {
             return match.group(0)?.replaceAll('\n', '\\n') ?? '';
        });

        try {
          final dynamic parsed = jsonDecode(jsonStr);
          debugPrint('Assistant: Parsed JSON: $parsed');
          if (parsed is Map<String, dynamic>) {
             String? toolName;
             Map<String, dynamic>? toolArgs;

             if (parsed.containsKey('tool')) {
               // Case A: Standard Protocol {"tool": "name", "args": {...}}
               toolName = parsed['tool'];
               toolArgs = Map<String, dynamic>.from(parsed['args'] ?? parsed['parameters'] ?? {});
             } else {
               // Case B: Function Call inferred `tool_name({...})`
               // Check text BEFORE the JSON
               final prefix = cleanResponse.substring(0, jsonStart).trim();
               // Look for "tool_name(" pattern
               final funcMatch = RegExp(r'([a-zA-Z0-9_]+)\s*\($').firstMatch(prefix);
               if (funcMatch != null) {
                 toolName = funcMatch.group(1);
                 toolArgs = parsed;
                 debugPrint('Assistant: Inferred tool $toolName from function prefix');
               } else if (cleanResponse.contains('(') && cleanResponse.endsWith(')')) {
                  // Fallback: simple prefix check if no strict regex match
                   final cleanPrefix = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
                   if (cleanPrefix.isNotEmpty) {
                      toolName = cleanPrefix;
                      toolArgs = parsed;
                      debugPrint('Assistant: Inferred tool $toolName from dirty prefix');
                   }
               }
             }

             if (toolName != null && toolArgs != null) {
               debugPrint('Assistant: Executing tool $toolName with $toolArgs');
               // Special handling for bad args nesting (sometimes models wrap args in "args" key inside the function call)
               if (toolArgs.containsKey('args') && toolArgs['args'] is Map) {
                 toolArgs = Map<String, dynamic>.from(toolArgs['args']);
               }
               return await _executeTool(relevantTools, toolName, toolArgs);
             }
          }
        } catch (e) {
           debugPrint('Assistant: Failed to parse tool JSON: $e');
        }
      }

      responseText = rawResponse;
    } catch (e) {
      debugPrint('Assistant AI Error: $e');
      if (e.toString().contains("Tool not found")) {
         return ToolExecutionSummary(text: "I tried to use a tool but it wasn't available. Please try a simpler request.");
      }
      return ToolExecutionSummary(text: await _runHardcodedHeuristics(lower, tools));
    }

    // E. Verification Layer (Agent B)
    // Only verify if the output is long/complex or critical
    bool needsVerification = intentEnum == RouterIntent.research || intentEnum == RouterIntent.copywriting;
    
    if (needsVerification && responseText.length > 50) {
       final verifiedResponse = await verificationService.verifyOutput(text, responseText);
       return ToolExecutionSummary(text: verifiedResponse);
    }

    return ToolExecutionSummary(text: responseText);
  }

  Future<String> _runHardcodedHeuristics(String lower, List<AgentTool> tools) async {
    // 1. NAVIGATION (High Priority)
    if (lower.contains('go to') || lower.contains('navigate') || lower.contains('show') || lower.contains('open')) {
      if (lower.contains('settings')) return (await _executeTool(tools, 'navigate_to', {'route': '/settings'})).text;
      if (lower.contains('client')) return (await _executeTool(tools, 'navigate_to', {'route': '/clients'})).text;
      if (lower.contains('workflow') || lower.contains('dashboard') || lower.contains('app')) {
         return (await _executeTool(tools, 'navigate_to', {'route': '/dashboard'})).text; 
      }
      if (lower.contains('campaign')) return (await _executeTool(tools, 'navigate_to', {'route': '/campaigns'})).text;
      if (lower.contains('monitor')) return (await _executeTool(tools, 'navigate_to', {'route': '/monitor'})).text;
      if (lower.contains('knowledge')) return (await _executeTool(tools, 'navigate_to', {'route': '/knowledge'})).text;
    }

    // 2. CREATION / ADDITION
    if (lower.contains('create') || lower.contains('add') || lower.contains('build') || lower.contains('new')) {
       if (lower.contains('client')) return (await _executeTool(tools, 'add_client', {'name': 'New Client', 'industry': 'Other'})).text;
       if (lower.contains('campaign')) return (await _executeTool(tools, 'create_campaign', {'title': 'New Campaign'})).text;
    }

    return "I am Brian, your Inhaus Copilot. I can manage clients, build apps, navigate to any module, or orchestrate commerce via UCP. Try: 'Build a new app' or 'Go to clients'.";
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

  ToolExecutionSummary({
    required this.text, 
    this.assetPath, 
    this.assetType,
    this.modelName,
    this.sources,
    this.artifacts,
  });

  String get displayText => text;
}

final assistantServiceProvider = Provider<AssistantService>((ref) => AssistantService(ref));
final assistantModeProvider = StateProvider<AssistantMode>((ref) => AssistantMode.fast);
