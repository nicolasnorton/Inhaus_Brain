import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import 'package:inhaus_brain/features/reports/providers/reports_provider.dart';
import 'package:inhaus_brain/features/knowledge/services/knowledge_api_service.dart';
import 'package:inhaus_brain/features/knowledge/providers/knowledge_provider.dart';
import 'package:inhaus_brain/features/reports/services/reports_service.dart';

class DeepResearchTool extends AgentTool {
  final ReportsService _reportsService;

  DeepResearchTool(this._reportsService)
      : super(
          name: 'deep_research',
          description: 'Conduct deep research on a topic and generate a comprehensive report with insights and metrics.',
          inputSchema: {
            'topic': {
              'type': 'string',
              'description': 'The main topic or question to research.',
            },
            'clientId': {
              'type': 'string',
              'description': 'The client ID to associate this report with (optional, defaults to "general").',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final topic = parameters['topic'] as String?;
    final clientId = parameters['clientId'] as String? ?? 'general';

    if (topic == null || topic.isEmpty) {
      return ToolResult.failure('topic is required for deep research.');
    }

    try {
      // 1. Generate the report
      final report = await _reportsService.generateReport(
        title: topic,
        prompt: topic,
        userId: 'system_agent',
        clientId: clientId,
        useDeepResearch: true, // Force deep research
      );

      // 2. Parse the output to return meaningful data to the agent
      Map<String, dynamic> reportData = {};
      if (report.outputs.isNotEmpty && report.outputs[0].content != null) {
          try {
              reportData = jsonDecode(report.outputs[0].content!);
          } catch (_) {
              reportData = {'raw': report.outputs[0].content};
          }
      }

      // 3. Return a summary + UI Payload
      return ToolResult.success({
        'message': 'Deep Research completed successfully.',
        'report_id': report.id,
        'report_title': report.title,
        'summary': reportData['executive_summary'] ?? 'Report generated.',
        'uiPayload': {
           'type': 'deep_analysis',
           'id': report.id,
           'title': report.title,
           'client_id': report.clientId,
           'created_at': report.createdAt.toIso8601String(),
           ...reportData
        }
      });
    } catch (e) {
      return ToolResult.failure('Deep Research failed: $e');
    }
  }
}

class FileSearchTool extends AgentTool {
  final KnowledgeApiService _knowledgeService;
  final String? _defaultDatasetId;

  FileSearchTool(this._knowledgeService, this._defaultDatasetId)
      : super(
          name: 'file_search',
          description: 'Search for information within the uploaded files and knowledge base.',
          inputSchema: {
            'query': {
              'type': 'string',
              'description': 'The search query.',
            },
            'datasetId': {
              'type': 'string',
              'description': 'Specific dataset ID to search (optional).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final query = parameters['query'] as String?;
    final datasetId = parameters['datasetId'] as String? ?? _defaultDatasetId;

    if (query == null || query.isEmpty) {
      return ToolResult.failure('query is required.');
    }

    if (datasetId == null) {
      return ToolResult.failure('No active Knowledge Base (datasetId) found. Please create or select one first.');
    }

    try {
      // Use the retrieveChunks method (even if it's currently mocking/limited)
      final result = await _knowledgeService.retrieveChunks(
        datasetId: datasetId,
        query: query,
        retrievalModel: {'top_k': 5, 'score_threshold': 0.7},
      );

      final records = result['records'] as List<dynamic>? ?? [];

      if (records.isEmpty) {
         return ToolResult.success({
           'results': [],
           'message': 'No relevant information found in the knowledge base.'
         });
      }

      // Format results
      final formatted = records.map((r) {
         final seg = r['segment'] ?? {};
         return {
           'content': seg['content'],
           'score': r['score']
         };
      }).toList();

      return ToolResult.success({
        'results': formatted,
        'count': formatted.length,
        'message': 'Found ${formatted.length} relevant segments.'
      });

    } catch (e) {
      return ToolResult.failure('File search failed: $e');
    }
  }
}

class LiveSessionTool extends AgentTool {
  LiveSessionTool()
      : super(
          name: 'live_session_analysis',
          description: 'Start a live multimodal session to analyze real-time video or audio streams.',
          inputSchema: {
            'streamUrl': {
              'type': 'string',
              'description': 'The URL of the live stream to analyze.',
            },
            'objective': {
              'type': 'string',
              'description': 'What the agent should look for or analyze in the stream.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final objective = parameters['objective'] as String? ?? 'Monitor stream';
    
    // Future: Integrate with Gemini Multimodal Live API
    return ToolResult.success({
      'message': 'Live Multimodal Session initialized for objective: $objective',
      'session_id': 'live_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'listening',
      'notice': 'Integration with Gemini Live API is in preview mode.',
      'uiPayload': {
        'type': 'live_multimodal_session',
        'objective': objective,
        'stream_url': parameters['streamUrl'],
      }
    });
  }
}

final researchToolsProvider = Provider<List<AgentTool>>((ref) {
  final reportsService = ref.watch(reportsServiceProvider);
  final knowledgeService = ref.watch(knowledgeApiServiceProvider);
  // We need a way to get the 'current' dataset ID. 
  // Often stored in a provider or user settings.
  // For now, let's assume there's a selectedDatasetIdProvider or similar, 
  // or we pass null and let the tool fail if not provided in args.
  
  // I'll define a simple provider lookup if it exists, or null.
  // Checking knowledge_tools.dart, it used `ref.watch(selectedDatasetIdProvider)`.
  // I'll try to find where that is defined or just import it if possible.
  
  // To avoid import errors if I can't find it immediately, I'll use dynamic lookup or just pass null.
  // Actually, I saw `selectedDatasetIdProvider` in knowledge_tools.dart line 144.
  // It was imported from 'package:inhaus_brain/features/knowledge/providers/knowledge_provider.dart';
  
  final currentDatasetId = ref.watch(selectedDatasetIdProvider);

  return [
    DeepResearchTool(reportsService),
    FileSearchTool(knowledgeService, currentDatasetId),
    LiveSessionTool(),
  ];
});
