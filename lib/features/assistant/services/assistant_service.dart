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
  };

  factory AssistantMessage.fromJson(Map<String, dynamic> json) => AssistantMessage(
    id: json['id'],
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
    isToolOutput: json['isToolOutput'] ?? false,
    generatedAssetPath: json['generatedAssetPath'],
    generatedAssetType: json['generatedAssetType'],
    modelName: json['modelName'],
    processingTime: json['processingTimeMs'] != null ? Duration(milliseconds: json['processingTimeMs']) : null,
    sources: json['sources'] != null ? List<String>.from(json['sources']) : null,
    attachment: json['attachment'] != null ? base64Decode(json['attachment']) : null,
    audioAttachment: json['audioAttachment'] != null ? base64Decode(json['audioAttachment']) : null,
  );
}

class AssistantService {
  final List<AssistantMessage> _history = [];
  final Ref _ref;

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
    _history.add(AssistantMessage(
      id: DateTime.now().toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      attachment: attachment,
      audioAttachment: audioAttachment,
    ));
    await _ref.read(persistenceServiceProvider).saveAssistantHistory(_history);

    // 2. Simulate AI Intent Matching (Mock)
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
      isToolOutput: executionResult.assetPath != null, // Mark as tool output if we have an asset
      generatedAssetPath: executionResult.assetPath,
      generatedAssetType: executionResult.assetType,
      modelName: executionResult.modelName ?? 'Gemini 1.5 Flash',
      processingTime: stopwatch.elapsed,
      sources: executionResult.sources,
    );

    _history.add(message);
    await _ref.read(persistenceServiceProvider).saveAssistantHistory(_history);
    
    // Ingest into knowledge autonomously
    _ref.read(knowledgeIngestionServiceProvider).ingestCopilotScreencap(
      "Query: $text\nResponse: ${message.text}",
      attachment: attachment,
    );
    
    return message;
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
    final mainPrompt = """
You are the Inhaus Brain Super Admin Assistant.
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
      
      // 1. Strip Markdown Code Blocks
      final codeBlockRegex = RegExp(r'```(?:json)?\s*(.*?)\s*```', dotAll: true);
      final codeMatch = codeBlockRegex.firstMatch(cleanResponse);
      if (codeMatch != null) {
        cleanResponse = codeMatch.group(1)!.trim();
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

    return "I am Inhaus Super Admin. I can manage clients, build apps, navigate to any module, or orchestrate commerce via UCP. Try: 'Build a new app' or 'Go to clients'.";
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
}

class ToolExecutionSummary {
  final String text;
  final String? assetPath;
  final String? assetType; // 'image', 'video'
  final String? modelName;
  final List<String>? sources;

  ToolExecutionSummary({
    required this.text, 
    this.assetPath, 
    this.assetType,
    this.modelName,
    this.sources,
  });

  String get displayText => text;
}

final assistantServiceProvider = Provider<AssistantService>((ref) => AssistantService(ref));
