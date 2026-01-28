import '../agent_tool.dart';

class DriveTool extends AgentTool {
  DriveTool()
      : super(
          name: "drive_tool",
          description: "readDoc: Reads content from a Google Doc or valid file ID.",
          inputSchema: {
            "fileId": {
              "type": "string",
              "description": "The ID of the file to read.",
            },
            "query": {
              "type": "string",
              "description": "Search query to find files.",
            },
          },
        );
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final fileId = parameters['fileId'] as String?;
    final query = parameters['query'] as String?; // Search query
    
    if (fileId == null && query == null) return ToolResult.failure("Missing fileId or query parameter");

    await Future.delayed(const Duration(milliseconds: 500));

    if (fileId != null) {
      return ToolResult.success({
        "content": "Doc Content for $fileId: Market research indicates a 20% growth in sector X...",
        "title": "Q1 Market Research"
      });
    } else {
       return ToolResult.success({
        "files": [
          {"id": "doc_123", "name": "Q1 Strategy"},
          {"id": "doc_456", "name": "Competitor Analysis"}
        ]
      });
    }
  }
}
