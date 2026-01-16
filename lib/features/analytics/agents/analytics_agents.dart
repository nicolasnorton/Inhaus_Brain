import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../chat/agents/base_agent.dart';
import '../../chat/models/chat_models.dart';
import '../../knowledge/models/knowledge_source.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/adk/services/adk_event_bus.dart';

// 1. Performance Analyst Agent
class PerformanceAnalystAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.performanceAnalystAgent;
  @override
  String get name => "Performance Analyst";
  @override
  String get systemPromptKey => "performance_analyst_prompt";

  @override
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
    Function(AdkEvent)? onEvent,
    Ref? ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final systemInstruction = systemPrompt ?? """
You are a Performance Analyst. Your task is to monitor and analyze KPI data. 
Identify trends, bottlenecks, and ROI metrics. Report on what is working and what is not in terms of performance numbers.
""";
    final result = (await EdgeAIService.generateText(
      "$systemInstruction\n\nInput: $userPrompt",
      context: context,
      ref: ref,
    )).text;
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return result;
  }
}

// 2. Data Scientist Agent
class DataScientistAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.dataScientistAgent;
  @override
  String get name => "Data Scientist";
  @override
  String get systemPromptKey => "data_scientist_prompt";

  @override
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
    Function(AdkEvent)? onEvent,
    Ref? ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final systemInstruction = systemPrompt ?? """
You are a Data Scientist. Your task is to process structured and unstructured data to find deeper correlations.
Look for anomalies, predictive patterns, and data-driven insights that aren't obvious from surface-level KPIs.
""";
    final result = (await EdgeAIService.generateText(
      "$systemInstruction\n\nInput: $userPrompt",
      context: context,
      ref: ref,
    )).text;
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return result;
  }
}

// 3. Digital Strategy Agent
class DigitalStrategyAgent extends BaseAgent {
  @override
  MessageSender get type => MessageSender.digitalStrategyAgent;
  @override
  String get name => "Digital Strategist";
  @override
  String get systemPromptKey => "digital_strategy_prompt";

  @override
  Future<String> execute({
    required String userPrompt,
    required List<KnowledgeSource> context,
    String? systemPrompt,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
    Function(AdkEvent)? onEvent,
    Ref? ref,
  }) async {
    onEvent?.call(AdkEvent(type: AdkEventType.agentStarted, source: name));
    final systemInstruction = systemPrompt ?? """
You are a Digital Strategist. Your task is to take analyst and scientist reports and turn them into actionable business strategy.
Focus on decision-making, budget allocation, and high-level campaign adjustments to maximize business value.
""";
    final result = (await EdgeAIService.generateText(
      "$systemInstruction\n\nInput: $userPrompt",
      context: context,
      ref: ref,
    )).text;
    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return result;
  }
}
