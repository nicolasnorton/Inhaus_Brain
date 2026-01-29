import '../../mcp/agent_tool.dart';
import '../../services/notion_service.dart';

class NotionTool extends AgentTool {
  final NotionService _service;

  NotionTool(this._service)
      : super(
          name: 'notion_tool',
          description: 'Search, read, and create pages in Notion.',
          inputSchema: {
            'action': {
              'type': 'string',
              'enum': ['search', 'getPage', 'createPage'],
              'description': 'The action to perform in Notion.',
            },
            'query': {
              'type': 'string',
              'description': 'The search query or page title.',
            },
            'pageId': {
              'type': 'string',
              'description': 'The ID of the page to retrieve.',
            },
            'parentId': {
              'type': 'string',
              'description': 'The parent database or page ID (for createPage).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final action = parameters['action'] as String?;
    if (action == null) return ToolResult.failure('Missing required parameter: action');

    try {
      switch (action) {
        case 'search':
          final query = parameters['query'] as String? ?? '';
          final result = await _service.search(query);
          return ToolResult.success(result);
        case 'getPage':
          final pageId = parameters['pageId'] as String?;
          if (pageId == null) return ToolResult.failure('Missing required parameter: pageId');
          final result = await _service.getPage(pageId);
          return ToolResult.success(result);
        case 'createPage':
          final parentId = parameters['parentId'] as String?;
          final title = parameters['query'] as String?;
          if (parentId == null || title == null) {
            return ToolResult.failure('Missing required parameters for createPage: parentId and query (title)');
          }
          final result = await _service.createPage(parentId, title);
          return ToolResult.success(result);
        default:
          return ToolResult.failure('Unknown action: $action');
      }
    } catch (e) {
      return ToolResult.failure('Notion operation failed: $e');
    }
  }
}
