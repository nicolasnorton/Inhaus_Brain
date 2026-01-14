import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'assistant_tool_registry.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/services/edge_ai_service.dart';

class AssistantMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isToolOutput;

  AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isToolOutput = false,
  });
}

class AssistantService {
  final List<AssistantMessage> _history = [];
  final Ref _ref;

  AssistantService(this._ref);

  List<AssistantMessage> get history => List.unmodifiable(_history);

  Future<AssistantMessage> sendMessage(String text) async {
    // 1. Add user message
    _history.add(AssistantMessage(
      id: DateTime.now().toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // 2. Simulate AI Intent Matching (Mock)
    await Future.delayed(const Duration(seconds: 1));

    final tools = _ref.read(assistantToolRegistryProvider);
    final response = await _matchIntentAndExecute(text, tools);

    // 3. Add response
    final message = AssistantMessage(
      id: DateTime.now().toString(),
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
      isToolOutput: false,
    );

    _history.add(message);
    return message;
  }

  Future<String> _matchIntentAndExecute(String text, List<AgentTool> tools) async {
    final lower = text.toLowerCase();
    
    // Phase 89: Use Real AI to determine intent
    final toolDefinitions = tools.map((t) => "- ${t.name}: ${t.description}").join("\n");
    final prompt = """
You are the Inhaus Super Admin Assistant. 
The user said: "$text"

Available Tools:
$toolDefinitions

If one of the tools matches the user's request, return ONLY a JSON object: {"tool": "tool_name", "args": {...}}.
Ensure you extract all necessary parameters (e.g. if the user gives a URL but no title for a knowledge source, invent a short title).
If no tool is a perfect match, or if it's a general question, provide a helpful, professional response as the assistant.

Response:
""";

    try {
      final aiRes = await EdgeAIService.generateText(prompt, ref: _ref);
      final rawResponse = aiRes.text.trim();
      
      // Robust JSON detection and extraction
      if (rawResponse.contains('{') && rawResponse.contains('}')) {
        try {
          final jsonStr = rawResponse.substring(rawResponse.indexOf('{'), rawResponse.lastIndexOf('}') + 1);
          final data = jsonDecode(jsonStr);
          if (data.containsKey('tool')) {
            // Extract parameters: Check 'args', then 'parameters', then the root object itself (minus 'tool')
            final Map<String, dynamic> params = Map<String, dynamic>.from(
              data['args'] ?? data['parameters'] ?? Map<String, dynamic>.from(data)..remove('tool')
            );
            return await _executeTool(tools, data['tool'], params);
          }
        } catch (e) {
          debugPrint('Assistant: Failed to parse tool JSON: $e');
        }
      }
      
      return rawResponse;
    } catch (e) {
      debugPrint('Assistant AI Error: $e');
      // Hybrid Fallback: Use existing hardcoded logic if AI fails
      return _runHardcodedHeuristics(lower, tools);
    }
  }

  Future<String> _runHardcodedHeuristics(String lower, List<AgentTool> tools) async {
    // 1. NAVIGATION (High Priority)
    if (lower.contains('go to') || lower.contains('navigate') || lower.contains('show') || lower.contains('open')) {
      if (lower.contains('settings')) return await _executeTool(tools, 'navigate_to', {'route': '/settings'});
      if (lower.contains('client')) return await _executeTool(tools, 'navigate_to', {'route': '/clients'});
      if (lower.contains('workflow') || lower.contains('dashboard') || lower.contains('app')) {
         return await _executeTool(tools, 'navigate_to', {'route': '/dashboard'}); 
      }
      if (lower.contains('campaign')) return await _executeTool(tools, 'navigate_to', {'route': '/campaigns'});
      if (lower.contains('monitor')) return await _executeTool(tools, 'navigate_to', {'route': '/monitor'});
      if (lower.contains('knowledge')) return await _executeTool(tools, 'navigate_to', {'route': '/knowledge'});
    }

    // 2. CREATION / ADDITION
    if (lower.contains('create') || lower.contains('add') || lower.contains('build') || lower.contains('new')) {
       if (lower.contains('client')) return await _executeTool(tools, 'add_client', {'name': 'New Client', 'industry': 'Other'});
       if (lower.contains('campaign')) return await _executeTool(tools, 'create_campaign', {'title': 'New Campaign'});
    }

    return "I am Inhaus Super Admin. I can manage clients, build apps, navigate to any module, or orchestrate commerce via UCP. Try: 'Build a new app' or 'Go to clients'.";
  }

  Future<String> _executeTool(List<AgentTool> tools, String name, Map<String, dynamic> args) async {
    final tool = tools.firstWhere((t) => t.name == name, orElse: () => throw Exception('Tool not found: $name'));
    try {
      final result = await tool.execute(args);
      if (result.isSuccess) {
        return "Executed $name: ${result.data}";
      } else {
        return "Error executing $name: ${result.errorMessage}";
      }
    } catch (e) {
      return "System error: $e";
    }
  }

  void clearHistory() {
    _history.clear();
  }
}

final assistantServiceProvider = Provider<AssistantService>((ref) => AssistantService(ref));
