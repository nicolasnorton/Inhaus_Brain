import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import 'package:inhaus_brain/core/adk/models/pipeline_models.dart';
import 'package:inhaus_brain/features/adk/providers/pipeline_provider.dart';
import 'package:uuid/uuid.dart';

class CreateAppTool extends AgentTool {
  final PipelineNotifier _notifier;

  CreateAppTool(this._notifier)
      : super(
          name: 'create_app',
          description: 'Create a new AI workflow app (Pipeline).',
          inputSchema: {
            'name': {
              'type': 'string',
              'description': 'The name of the app.',
            },
            'description': {
              'type': 'string',
              'description': 'What the app does.',
            },
            'type': {
              'type': 'string',
              'description': 'Type of workflow (e.g., research, creative, marketing).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final name = parameters['name'] as String?;
    final description = parameters['description'] as String? ?? '';
    
    if (name == null || name.isEmpty) {
      return ToolResult.failure('Missing required parameter: name');
    }

    try {
      final pipeline = Pipeline(
        id: 'app-${const Uuid().v4().substring(0, 8)}',
        name: name,
        description: description,
        steps: [], // Initially empty, user can edit later
      );

      _notifier.savePipeline(pipeline);
      return ToolResult.success({
        'message': 'App "$name" created successfully.',
        'appId': pipeline.id,
      });
    } catch (e) {
      return ToolResult.failure('Failed to create app: $e');
    }
  }
}

class UpdateAppTool extends AgentTool {
  final PipelineNotifier _notifier;
  final List<Pipeline> _pipelines;

  UpdateAppTool(this._notifier, this._pipelines)
      : super(
          name: 'update_app',
          description: 'Update an app name or description.',
          inputSchema: {
            'appId': {
              'type': 'string',
              'description': 'ID of the app to update.',
            },
            'name': {
              'type': 'string',
              'description': 'New name.',
            },
            'description': {
              'type': 'string',
              'description': 'New description.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final appId = (parameters['appId'] ?? parameters['id']) as String?;
    if (appId == null) return ToolResult.failure('Missing appId');

    try {
      final app = _pipelines.firstWhere((p) => p.id == appId);
      final updated = app.copyWith(
        name: parameters['name'] as String?,
        description: parameters['description'] as String?,
      );
      _notifier.savePipeline(updated);
      return ToolResult.success({'message': 'App updated.'});
    } catch (e) {
      return ToolResult.failure('Update failed: $e');
    }
  }
}

class DeleteAppTool extends AgentTool {
  final PipelineNotifier _notifier;

  DeleteAppTool(this._notifier)
      : super(
          name: 'delete_app',
          description: 'Delete an AI workflow app.',
          inputSchema: {
            'appId': {
              'type': 'string',
              'description': 'ID of the app to delete.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final appId = (parameters['appId'] ?? parameters['id']) as String?;
    if (appId == null) return ToolResult.failure('Missing appId');

    try {
      _notifier.deletePipeline(appId);
      return ToolResult.success({'message': 'App deleted successfully.'});
    } catch (e) {
      return ToolResult.failure('Delete failed: $e');
    }
  }
}

class ListAppsTool extends AgentTool {
  final List<Pipeline> _pipelines;

  ListAppsTool(this._pipelines)
      : super(
          name: 'list_apps',
          description: 'List all available workflow apps.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    return ToolResult.success({
      'apps': _pipelines.map((p) => {
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'stepsCount': p.steps.length,
      }).toList(),
    });
  }
}

final adkToolsProvider = Provider<List<AgentTool>>((ref) {
  final notifier = ref.read(pipelineProvider.notifier);
  final pipelines = ref.watch(pipelineProvider);
  
  return [
    CreateAppTool(notifier),
    UpdateAppTool(notifier, pipelines),
    DeleteAppTool(notifier),
    ListAppsTool(pipelines),
  ];
});
