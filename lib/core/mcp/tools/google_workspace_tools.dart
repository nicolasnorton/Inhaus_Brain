import '../agent_tool.dart';
import 'gmail_tool.dart';
import 'drive_tool.dart';

export 'gmail_tool.dart';
export 'drive_tool.dart';

class CalendarTool extends AgentTool {
  CalendarTool()
      : super(
          name: "workspace_calendar",
          description: "Google Workspace MCP: Read, schedule, or modify Google Calendar events. Uses the WebMCP proxy.",
          inputSchema: {
            "action": {
              "type": "string",
              "description": "Action to perform: 'list', 'create', 'delete'",
              "enum": ["list", "create", "delete"]
            },
            "summary": {
              "type": "string",
              "description": "Required for 'create'. Title of the event.",
            },
            "startTime": {
              "type": "string",
              "description": "ISO-8601 start time.",
            },
            "endTime": {
              "type": "string",
              "description": "ISO-8601 end time.",
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final action = parameters['action'] as String?;
    if (action == null) {
      return ToolResult.failure("Missing action parameter");
    }

    // Proxy WebMCP response mocked
    await Future.delayed(const Duration(milliseconds: 500));

    if (action == 'list') {
      return ToolResult.success({
        "events": [
          {"id": "ev1", "summary": "Sync with Agency", "startTime": "2026-03-15T10:00:00Z"},
        ]
      });
    }

    return ToolResult.success({
      "status": "staged",
      "message": "Calendar event $action staged for confirmation."
    });
  }
}
