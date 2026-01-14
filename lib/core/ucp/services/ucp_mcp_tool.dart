import '../../mcp/agent_tool.dart';
import 'ucp_service.dart';
import '../models/participant_model.dart';

class UCPDiscoverTool extends AgentTool {
  final UCPService _service;

  UCPDiscoverTool(this._service)
      : super(
          name: 'ucp_discover_businesses',
          description: 'Discover businesses and their commerce capabilities using UCP.',
          inputSchema: {
            'query': {
              'type': 'string',
              'description': 'Search query for businesses (e.g., "shoes", "electronics").',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final query = parameters['query'] as String?;
    if (query == null) {
      return ToolResult.failure('Missing required parameter: query');
    }

    try {
      final businesses = await _service.discoverBusinesses(query);
      final businessList = businesses.map((b) => {
        'id': b.id,
        'name': b.name,
        'merchantId': b.merchantId,
        'capabilities': b.capabilities.map((c) => c.name).toList(),
      }).toList();

      return ToolResult.success({'businesses': businessList});
    } catch (e) {
      return ToolResult.failure('Discovery failed: $e');
    }
  }
}

class UCPCheckoutTool extends AgentTool {
  final UCPService _service;

  UCPCheckoutTool(this._service)
      : super(
          name: 'ucp_initiate_checkout',
          description: 'Initiate a UCP checkout session with a discovered business.',
          inputSchema: {
            'businessId': {
              'type': 'string',
              'description': 'The ID of the business to checkout with.',
            },
            'itemIds': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of item IDs to purchase.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final businessId = parameters['businessId'] as String?;
    final itemIds = (parameters['itemIds'] as List?)?.cast<String>() ?? [];

    if (businessId == null) {
      return ToolResult.failure('Missing required parameter: businessId');
    }

    try {
      // Create a dummy business object for the service call
      final dummyBusiness = Business(id: businessId, name: 'Unknown', merchantId: 'unknown');
      
      final result = await _service.initiateCheckout(dummyBusiness, itemIds);
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Checkout failed: $e');
    }
  }
}
class UCPListCategoriesTool extends AgentTool {
  UCPListCategoriesTool()
      : super(
          name: 'ucp_list_categories',
          description: 'List available business categories in the UCP network.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    return ToolResult.success({
      'categories': [
        'Retail', 'Electronics', 'Fashion', 'Grocery', 'Services', 'Healthcare', 'Entertainment'
      ]
    });
  }
}

class UCPListParticipantsTool extends AgentTool {
  final UCPService _service;

  UCPListParticipantsTool(this._service)
      : super(
          name: 'ucp_list_participants',
          description: 'List all active participants in the UCP network.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final participants = await _service.getParticipants();
      return ToolResult.success({
        'participants': participants.map((p) => {
          'id': p.id,
          'name': p.name,
          'type': p.runtimeType.toString(),
        }).toList()
      });
    } catch (e) {
      return ToolResult.failure('Failed to list participants: $e');
    }
  }
}
