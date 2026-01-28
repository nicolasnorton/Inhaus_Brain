import '../agent_tool.dart';

class GmailTool extends AgentTool {
  @override
  String get name => "gmail_tool";

  @override
  String get description => "searchEmails: Searches recent emails for client communications.";

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
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
