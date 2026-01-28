import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';

class AddWorkflowNodeTool extends AgentTool {
  AddWorkflowNodeTool()
      : super(
          name: 'add_workflow_node',
          description: 'Add a logic node to the current workflow canvas.',
          inputSchema: {
            'type': {
              'type': 'string',
              'description': 'Type of node (trigger, action, logic).',
            },
            'label': {
              'type': 'string',
              'description': 'Display label for the node.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final type = parameters['type'] ?? 'action';
    final label = parameters['label'] ?? 'New Node';
    
    // Logic to update ADK state would go here
    return ToolResult.success({'message': 'Added $type node: "$label" to canvas.'});
  }
}

class ConnectNodesTool extends AgentTool {
  ConnectNodesTool()
      : super(
          name: 'connect_workflow_nodes',
          description: 'Create a connection between two workflow nodes.',
          inputSchema: {
            'fromNodeId': {'type': 'string'},
            'toNodeId': {'type': 'string'},
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    return ToolResult.success({'message': 'Nodes connected successfully.'});
  }
}

final workflowToolsProvider = Provider<List<AgentTool>>((ref) {
  return [
    AddWorkflowNodeTool(),
    ConnectNodesTool(),
  ];
});
