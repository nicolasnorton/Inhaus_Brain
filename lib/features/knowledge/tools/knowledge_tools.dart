import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import 'package:inhaus_brain/features/knowledge/services/knowledge_api_service.dart';
import 'package:inhaus_brain/features/knowledge/models/knowledge_source.dart';
import 'package:inhaus_brain/features/knowledge/providers/knowledge_provider.dart';
import 'package:uuid/uuid.dart';

class AddKnowledgeSourceTool extends AgentTool {
  final KnowledgeNotifier _notifier;
  final KnowledgeApiService _apiService;
  final String? _currentDatasetId;

  AddKnowledgeSourceTool(this._notifier, this._apiService, this._currentDatasetId)
      : super(
          name: 'add_knowledge_source',
          description: 'Add a new knowledge source (URL, document, or text).',
          inputSchema: {
            'title': {
              'type': 'string',
              'description': 'Title of the knowledge source.',
            },
            'content': {
              'type': 'string',
              'description': 'The actual content or URL.',
            },
            'url': {
              'type': 'string',
              'description': 'The URL if it is a web source.',
            },
            'type': {
              'type': 'string',
              'description': 'Type of source: web, url, text, or file.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    // Aggressive parameter extraction: check common keys
    final contentFinal = (parameters['content'] ?? 
                           parameters['url'] ?? 
                           parameters['link'] ?? 
                           parameters['source'] ?? 
                           parameters['data']) as String?;
    
    final title = parameters['title'] as String? ?? 
                  parameters['name'] as String? ??
                  (contentFinal != null ? (contentFinal.length > 30 ? 'Source: ${contentFinal.substring(0, 27)}...' : 'Source: $contentFinal') : 'New Source');
    final typeStr = parameters['type'] as String? ?? 'url';

    if (contentFinal == null) {
      return ToolResult.failure('Missing required parameter: content or url.');
    }

    if (_currentDatasetId == null) {
      return ToolResult.failure('No active Knowledge Base (Dataset) selected. Please create or select a dataset first.');
    }

    try {
      // 1. Real API Call
      await _apiService.createDocumentFromText(
        datasetId: _currentDatasetId!,
        name: title,
        text: contentFinal,
        indexingTechnique: 'high_quality',
      );

      // 2. Optimistic UI Update (Mocking the ID since API returns one but we want to be fast)
      final source = KnowledgeSource(
        id: 'ks-${const Uuid().v4().substring(0, 8)}',
        title: title,
        content: contentFinal,
        type: KnowledgeSourceType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => KnowledgeSourceType.url,
        ),
        createdAt: DateTime.now(),
      );

      _notifier.addSource(source);
      return ToolResult.success({'message': 'Knowledge source "$title" added and indexing started.'});
    } catch (e) {
      return ToolResult.failure('Failed to add knowledge source: $e');
    }
  }
}

class DeleteKnowledgeSourceTool extends AgentTool {
  final KnowledgeNotifier _notifier;

  DeleteKnowledgeSourceTool(this._notifier)
      : super(
          name: 'delete_knowledge_source',
          description: 'Remove a knowledge source from the brain.',
          inputSchema: {
            'sourceId': {
              'type': 'string',
              'description': 'The ID of the source to remove.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final sourceId = (parameters['sourceId'] ?? parameters['id']) as String?;
    if (sourceId == null) return ToolResult.failure('Missing sourceId.');

    try {
      _notifier.removeSource(sourceId);
      return ToolResult.success({'message': 'Source removed successfully.'});
    } catch (e) {
      return ToolResult.failure('Removal failed: $e');
    }
  }
}

class ListKnowledgeSourcesTool extends AgentTool {
  final List<KnowledgeSource> _sources;

  ListKnowledgeSourcesTool(this._sources)
      : super(
          name: 'list_knowledge_sources',
          description: 'List all knowledge sources currenty in the brain.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    return ToolResult.success({
      'sources': _sources.map((s) => {
        'id': s.id,
        'title': s.title,
        'type': s.type.name,
      }).toList(),
    });
  }
}

final knowledgeToolsProvider = Provider<List<AgentTool>>((ref) {
  final notifier = ref.read(knowledgeProvider.notifier);
  final apiService = ref.read(knowledgeApiServiceProvider);
  final sources = ref.watch(knowledgeProvider);
  final currentDatasetId = ref.watch(selectedDatasetIdProvider); // Assuming you have this or similar
  
  return [
    AddKnowledgeSourceTool(notifier, apiService, currentDatasetId),
    DeleteKnowledgeSourceTool(notifier),
    ListKnowledgeSourcesTool(sources),
  ];
});
