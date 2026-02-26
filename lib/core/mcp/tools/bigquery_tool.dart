import '../agent_tool.dart';
import '../../services/bigquery_service.dart';

class BigQueryTool extends AgentTool {
  BigQueryTool()
      : super(
          name: "bigquery_tool",
          description: "executeQuery: Executes a SQL query against BigQuery datasets (e.g., client performance stats).",
          inputSchema: {
            "query": {
              "type": "string",
              "description": "SQL query to execute.",
            },
          },
        );
  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final query = parameters['query'] as String?;
    if (query == null) return ToolResult.failure("Missing query parameter");

    try {
      final bq = BigQueryService();
      final results = await bq.executeQuery(query);
      return ToolResult.success({
        "rows": results,
        "status": "success"
      });
    } catch (e) {
      return ToolResult.failure("Failed to execute query: $e");
    }
  }
}
