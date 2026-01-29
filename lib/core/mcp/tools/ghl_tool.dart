import '../../mcp/agent_tool.dart';
import '../../services/ghl_service.dart';

class GHLTool extends AgentTool {
  final GHLService _service;

  GHLTool(this._service)
      : super(
          name: 'ghl_tool',
          description: 'List contacts, get opportunities, and create contacts in Go High Level.',
          inputSchema: {
            'action': {
              'type': 'string',
              'enum': ['listContacts', 'getOpportunities', 'createContact'],
              'description': 'The action to perform in GHL.',
            },
            'limit': {
              'type': 'integer',
              'description': 'The number of contacts to retrieve (for listContacts).',
            },
            'contactData': {
              'type': 'object',
              'description': 'The contact data to create (for createContact).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final action = parameters['action'] as String?;
    if (action == null) return ToolResult.failure('Missing required parameter: action');

    try {
      switch (action) {
        case 'listContacts':
          final limit = parameters['limit'] as int? ?? 20;
          final result = await _service.listContacts(limit: limit);
          return ToolResult.success(result);
        case 'getOpportunities':
          final result = await _service.getOpportunities();
          return ToolResult.success(result);
        case 'createContact':
          final contactData = parameters['contactData'] as Map<String, dynamic>?;
          if (contactData == null) return ToolResult.failure('Missing required parameter: contactData');
          final result = await _service.createContact(contactData);
          return ToolResult.success(result);
        default:
          return ToolResult.failure('Unknown action: $action');
      }
    } catch (e) {
      return ToolResult.failure('GHL operation failed: $e');
    }
  }
}
