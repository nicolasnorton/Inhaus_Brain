import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import 'package:inhaus_brain/features/workspace/models/app_models.dart';
import 'package:inhaus_brain/features/adk/models/app_type_models.dart'; 
import 'package:inhaus_brain/features/workspace/providers/apps_provider.dart';

class CreateAppTool extends AgentTool {
  final AppsNotifier _notifier;

  CreateAppTool(this._notifier)
      : super(
          name: 'create_app',
          description: 'Create a new AI app or agent.',
          inputSchema: {
             'name': {
              'type': 'string',
              'description': 'Name of the app.',
            },
            'type': {
              'type': 'string',
              'enum': ['workflow', 'chatflow', 'chatbot', 'agent', 'textGenerator'],
              'description': 'Type of app to create.',
            },
            'description': {
              'type': 'string',
              'description': 'Short description of what the app does.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final name = parameters['name'] as String?;
    final typeStr = parameters['type'] as String?;
    final description = parameters['description'] as String?;

    if (name == null) {
      return ToolResult.failure('Missing required parameter: name.');
    }

    AppType type = AppType.workflow;
    if (typeStr != null) {
      final normalized = typeStr.toLowerCase();
      if (normalized.contains('chat')) {
        type = AppType.chatbot;
      } else if (normalized.contains('agent')) {
        type = AppType.agent;
      } else if (normalized.contains('gen') || normalized.contains('text')) {
        type = AppType.textGenerator;
      } else if (normalized.contains('workflow')) {
        type = AppType.workflow;
      }
    }

    try {
      final app = App(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate ID
        name: name,
        description: description ?? '',
        type: type,
        icon: type.icon, // Required parameter
        status: AppStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        config: {},
      );

      _notifier.createApp(app); // Correct method name
      return ToolResult.success({'message': 'App "$name" created successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to create app: $e');
    }
  }
}

class ListAppsTool extends AgentTool {
  final List<App> _apps;

  ListAppsTool(this._apps)
      : super(
          name: 'list_apps',
          description: 'List all existing apps in the workspace.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final appList = _apps.map((a) => {
      'id': a.id,
      'name': a.name,
      'type': a.type.name,
    }).toList();
    
    return ToolResult.success({'apps': appList});
  }
}

final appToolsProvider = Provider<List<AgentTool>>((ref) {
  final appsNotifier = ref.read(appsProvider.notifier);
  final apps = ref.watch(appsProvider);
  
  return [
    CreateAppTool(appsNotifier),
    ListAppsTool(apps),
  ];
});
