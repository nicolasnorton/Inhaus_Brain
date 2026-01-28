import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/adk/services/adk_event_bus.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../features/knowledge/models/knowledge_source.dart';
import '../../chat/agents/base_agent.dart';
import '../../chat/models/chat_models.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/mcp/tools/bigquery_tool.dart';
import '../../../core/mcp/tools/drive_tool.dart';
import '../../../core/mcp/tools/gmail_tool.dart';
import '../../chat/agents/agency_agents.dart';

class ReportsAgent extends BaseAgent {
  @override
  String get name => "Reports Agent";
  
  @override
  MessageSender get type => MessageSender.reportsAgent;

  @override
  String get systemPromptKey => "reports_agent_prompt";

  @override
  List<AgentTool> get tools => [
    BigQueryTool(),
    DriveTool(),
    GmailTool(),
  ];

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

    // Default system prompt
    final systemInstruction = systemPrompt ?? """
You are the Reports Agent. Your goal is to synthesize data from various sources (BigQuery, Drive, Gmail) to create comprehensive reports for clients.
You have access to tools: bigquery_tool, drive_tool, and gmail_tool.
If the user asks for performance stats, use bigquery_tool.
If the user asks for document summaries, use drive_tool.
If the user asks for email updates, use gmail_tool.
Output your findings in a structured format suitable for a "Notebook" view (Markdown) or prepare data for visualization.
""";
    
    // Simple Orchestration Logic (LLM decides tool use)
    // 1. Ask LLM which tool to use (Function Calling simulation)
    // For MVP, we will do a deterministic check or a "Planning Step"
    
    String toolOutput = "";
    
    if (userPrompt.toLowerCase().contains("performance") || userPrompt.toLowerCase().contains("stats")) {
       final tool = tools.firstWhere((t) => t.name == 'bigquery_tool');
       final startMsg = "Fetching data from BigQuery...";
       onEvent?.call(AdkEvent(type: AdkEventType.toolStarted, source: name, message: startMsg));
       final result = await tool.execute({'query': userPrompt});
       toolOutput += "\nBigQuery Data: ${result.data}";
    }
    
    if (userPrompt.toLowerCase().contains("email") || userPrompt.toLowerCase().contains("communication")) {
       final tool = tools.firstWhere((t) => t.name == 'gmail_tool');
       final startMsg = "Searching emails...";
       onEvent?.call(AdkEvent(type: AdkEventType.toolStarted, source: name, message: startMsg));
       final result = await tool.execute({'query': userPrompt});
       toolOutput += "\nGmail Data: ${result.data}";
    }
    
    if (userPrompt.toLowerCase().contains("doc") || userPrompt.toLowerCase().contains("research") || userPrompt.toLowerCase().contains("strategy")) {
       final tool = tools.firstWhere((t) => t.name == 'drive_tool');
       final startMsg = "Searching documents...";
       onEvent?.call(AdkEvent(type: AdkEventType.toolStarted, source: name, message: startMsg));
       final result = await tool.execute({'query': userPrompt});
       toolOutput += "\nDrive Data: ${result.data}";
    }
    
    // Agent Orchestration
    if (userPrompt.toLowerCase().contains("trend")) {
       final startMsg = "Consulting Trend Scout...";
       onEvent?.call(AdkEvent(type: AdkEventType.agentThinking, source: name, message: startMsg));
       final trendAgent = TrendScoutAgent();
       final trendAnalysis = await trendAgent.execute(
         userPrompt: "Analyze current trends related to: $userPrompt",
         context: context,
         apiKey: apiKey,
         gemmaKey: gemmaKey,
         ref: ref,
       );
       toolOutput += "\nTrend Scout Analysis: $trendAnalysis";
    }

    if (userPrompt.toLowerCase().contains("performance") || userPrompt.toLowerCase().contains("analyst")) {
       final startMsg = "Consulting Performance Analyst...";
       onEvent?.call(AdkEvent(type: AdkEventType.agentThinking, source: name, message: startMsg));
       final perfAgent = PerformanceAnalystAgent();
       final perfAnalysis = await perfAgent.execute(
         userPrompt: "Analyze campaign performance metrics related to: $userPrompt",
         context: context,
         apiKey: apiKey,
         gemmaKey: gemmaKey,
         ref: ref,
       );
       toolOutput += "\nPerformance Analyst Analysis: $perfAnalysis";
    }

    final finalPrompt = "$systemInstruction\n\nUser Request: $userPrompt\n\nTool Data Gathered:\n$toolOutput\n\nSynthesize this into a professional report.";

    final aiRes = await EdgeAIService.generateText(
      finalPrompt,
      context: context,
      apiKey: apiKey,
      gemmaKey: gemmaKey,
      ref: ref,
    );

    onEvent?.call(AdkEvent(type: AdkEventType.agentCompleted, source: name));
    return aiRes.text;
  }
}
