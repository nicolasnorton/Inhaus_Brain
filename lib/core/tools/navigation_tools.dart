import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mcp/agent_tool.dart';
import '../router/app_router.dart';

class NavigateTool extends AgentTool {
  final GoRouter _router;

  NavigateTool(this._router)
      : super(
          name: 'navigate_to',
          description: 'Navigate to a specific route in the application.',
          inputSchema: {
            'route': {
              'type': 'string',
              'description': 'The path to navigate to (e.g., /campaigns, /settings).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final route = parameters['route'] as String?;
    if (route == null) {
      return ToolResult.failure('Missing required parameter: route');
    }

    try {
      _router.go(route);
      return ToolResult.success({'message': 'Navigated to $route'});
    } catch (e) {
      return ToolResult.failure('Navigation failed: $e');
    }
  }
}

final navigationToolsProvider = Provider<List<AgentTool>>((ref) {
  final router = ref.watch(routerProvider);
  return [NavigateTool(router)];
});
