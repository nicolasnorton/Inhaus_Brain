import '../agent_tool.dart';

class DriveTool extends AgentTool {
  @override
  String get name => "drive_tool";

  @override
  String get description => "readDoc: Reads content from a Google Doc or valid file ID.";

  @override
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
