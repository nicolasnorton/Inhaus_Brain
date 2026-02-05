import '../agent_tool.dart';

class GmailTool extends AgentTool {
  GmailTool()
      : super(
          name: "gmail_tool",
          description: "searchEmails: Searches recent emails for client communications.",
          inputSchema: {
            "query": {
              "type": "string",
              "description": "The search query to find emails.",
            },
          },
        );
  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final query = parameters['query'] as String?;
    if (query == null) return ToolResult.failure("Missing query parameter");

    await Future.delayed(const Duration(milliseconds: 500));

    return ToolResult.success({
      "emails": [
        {"subject": "Re: Campaign Update", "snippet": "We are happy with the progress...", "from": "client@example.com"},
        {"subject": "Assets for Q2", "snippet": "Attached are the new logos...", "from": "client@example.com"},
      ]
    });
  }
}
