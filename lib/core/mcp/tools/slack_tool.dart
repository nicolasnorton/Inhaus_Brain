import '../../mcp/agent_tool.dart';
import '../../services/slack_service.dart';

class SlackTool extends AgentTool {
  final SlackService _service;

  SlackTool(this._service)
      : super(
          name: 'slack_tool',
          description: 'List channels, post messages, and read history from Slack.',
          inputSchema: {
            'action': {
              'type': 'string',
              'enum': ['listChannels', 'postMessage', 'getHistory'],
              'description': 'The action to perform in Slack.',
            },
            'channel': {
              'type': 'string',
              'description': 'The channel ID to interact with.',
            },
            'text': {
              'type': 'string',
              'description': 'The message text to post (for postMessage).',
            },
            'limit': {
              'type': 'integer',
              'description': 'The number of messages to retrieve (for getHistory).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final action = parameters['action'] as String?;
    if (action == null) return ToolResult.failure('Missing required parameter: action');

    try {
      switch (action) {
        case 'listChannels':
          final result = await _service.listChannels();
          return ToolResult.success(result);
        case 'postMessage':
          final channel = parameters['channel'] as String?;
          final text = parameters['text'] as String?;
          if (channel == null || text == null) {
            return ToolResult.failure('Missing required parameters for postMessage: channel and text');
          }
          final result = await _service.postMessage(channel, text);
          return ToolResult.success(result);
        case 'getHistory':
          final channel = parameters['channel'] as String?;
          if (channel == null) return ToolResult.failure('Missing required parameter: channel');
          final limit = parameters['limit'] as int? ?? 10;
          final result = await _service.getHistory(channel, limit: limit);
          return ToolResult.success(result);
        default:
          return ToolResult.failure('Unknown action: $action');
      }
    } catch (e) {
      return ToolResult.failure('Slack operation failed: $e');
    }
  }
}
