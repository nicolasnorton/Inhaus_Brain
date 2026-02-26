import '../agent_tool.dart';
import '../../services/brainweave_data_service.dart';

class GenerateMarketingReportTool extends AgentTool {
  GenerateMarketingReportTool()
      : super(
          name: "generate_marketing_report",
          description: "generate_marketing_report: Generates a marketing intelligence data payload based on a natural language query.",
          inputSchema: {
            "query": {
              "type": "string",
              "description": "Natural language query about marketing performance (e.g., 'Why is TikTok ROAS dropping this week?').",
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final query = parameters['query'] as String?;
    if (query == null) {
      return ToolResult.failure("Missing query parameter");
    }

    try {
      final dataService = BrainWeaveDataService();
      final result = await dataService.executeNaturalLanguageQuery(query);
      return ToolResult.success({
        "data": result,
        "status": "success",
        "message": "Report data retrieved via NL-to-SQL."
      });
    } catch (e) {
      return ToolResult.failure("Failed to generate marketing report: \$e");
    }
  }
}
