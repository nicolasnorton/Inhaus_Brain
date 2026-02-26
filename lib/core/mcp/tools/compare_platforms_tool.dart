import '../agent_tool.dart';
import '../../services/brainweave_data_service.dart';

class ComparePlatformsTool extends AgentTool {
  ComparePlatformsTool()
      : super(
          name: "compare_platforms",
          description: "compare_platforms: Compares ad performance across platforms for a specific client within a date range.",
          inputSchema: {
            "client_id": {
              "type": "string",
              "description": "The client identifier.",
            },
            "start_date": {
              "type": "string",
              "description": "Start date in YYYY-MM-DD format.",
            },
            "end_date": {
              "type": "string",
              "description": "End date in YYYY-MM-DD format.",
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final clientId = parameters['client_id'] as String?;
    final startStr = parameters['start_date'] as String?;
    final endStr = parameters['end_date'] as String?;

    if (clientId == null || startStr == null || endStr == null) {
      return ToolResult.failure("Missing required parameters (client_id, start_date, end_date)");
    }

    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      final dataService = BrainWeaveDataService();
      final result = await dataService.comparePlatforms(clientId, start, end);
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure("Failed to compare platforms: \$e");
    }
  }
}
