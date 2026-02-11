import 'package:inhaus_brain/core/mcp/agent_tool.dart';

class DirectorTool extends AgentTool {
  DirectorTool() : super(
    name: 'direct_scene',
    description: 'Update an active 3D dialogue scene in real-time (Change camera, speaker, or environment).',
    inputSchema: {
      'action': {
        'type': 'string',
        'enum': ['set_speaker', 'set_camera', 'set_environment', 'trigger_gesture'],
        'description': 'The directing action to perform.'
      },
      'params': {
        'type': 'object',
        'description': 'Parameters for the action (e.g., {"speaker_id": "agent_a"}, {"anchor": "presenter"}, {"environment": "stage"}).'
      }
    }
  );

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {dynamic ref}) async {
    // In our current implementation, we'll return this as a UI-integrated update.
    // AssistantService will need to handle this to update the current Canvas state.
    return ToolResult.success({
      'is_scene_update': true,
      'action': args['action'],
      'params': args['params'],
      'message': 'Scene updated: ${args['action']}'
    });
  }
}
