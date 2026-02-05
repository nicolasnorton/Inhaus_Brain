import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';

class ListModulesTool extends AgentTool {
  ListModulesTool()
      : super(
          name: 'list_modules',
          description: 'List all available application modules.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    return ToolResult.success({
      'modules': [
        {'name': 'Workspace', 'route': '/dashboard', 'description': 'App management and creation'},
        {'name': 'Clients', 'route': '/clients', 'description': 'Client and CRM management'},
        {'name': 'Campaigns', 'route': '/campaigns', 'description': 'Marketing campaign orchestration'},
        {'name': 'Knowledge', 'route': '/knowledge', 'description': 'Knowledge base and documents'},
        {'name': 'UCP Commerce', 'route': '/ucp', 'description': 'Universal Commerce integration'},
        {'name': 'Monitoring', 'route': '/monitor', 'description': 'System health and logs'},
      ]
    });
  }
}

class GetAppStatusTool extends AgentTool {
  GetAppStatusTool()
      : super(
          name: 'get_app_status',
          description: 'Get the current status of the application environment.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    return ToolResult.success({
      'status': 'Online',
      'version': '1.0.0-brain',
      'active_tasks': 4,
      'environment': 'development',
    });
  }
}

final systemToolsProvider = Provider<List<AgentTool>>((ref) {
  return [
    ListModulesTool(),
    GetAppStatusTool(),
  ];
});
