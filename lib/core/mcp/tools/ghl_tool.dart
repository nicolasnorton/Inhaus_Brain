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
    'updateContact': {
      'description': 'Update an existing contact.',
      'properties': {
        'contactId': {'type': 'string'},
        'updateData': {'type': 'object'}
      }
    },
    'addNote': {
      'description': 'Add a note to a contact.',
      'properties': {
        'contactId': {'type': 'string'},
        'noteContent': {'type': 'string'}
      }
    },
    'addTag': {
      'description': 'Add a tag to a contact.',
      'properties': {
        'contactId': {'type': 'string'},
        'tag': {'type': 'string'}
      }
    }
  },
);

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
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
        case 'updateContact':
          final contactId = parameters['contactId'] as String?;
          final updateData = parameters['updateData'] as Map<String, dynamic>?;
          if (contactId == null || updateData == null) return ToolResult.failure('Missing parameters for updateContact');
          final result = await _service.updateContact(contactId, updateData);
          return ToolResult.success(result);
        case 'addNote':
          final contactId = parameters['contactId'] as String?;
          final noteContent = parameters['noteContent'] as String?;
          if (contactId == null || noteContent == null) return ToolResult.failure('Missing parameters for addNote');
          await _service.addNote(contactId, noteContent);
          return ToolResult.success({'message': 'Note added successfully'});
        case 'addTag':
          final contactId = parameters['contactId'] as String?;
          final tag = parameters['tag'] as String?;
          if (contactId == null || tag == null) return ToolResult.failure('Missing parameters for addTag');
          await _service.addTag(contactId, tag);
          return ToolResult.success({'message': 'Tag added successfully'});
        default:
          return ToolResult.failure('Unknown action: $action');
      }
    } catch (e) {
      return ToolResult.failure('GHL operation failed: $e');
    }
  }
}
