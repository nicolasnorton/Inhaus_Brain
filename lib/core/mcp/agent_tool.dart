/// Standardized result from any Agent Tool
class ToolResult {
  final Map<String, dynamic> data;
  final String? errorMessage;
  final bool isSuccess;

  ToolResult.success(this.data)
      : isSuccess = true,
        errorMessage = null;

  ToolResult.failure(this.errorMessage)
      : isSuccess = false,
        data = {};

  @override
  String toString() => isSuccess ? 'Success: $data' : 'Error: $errorMessage';
}

/// Abstract base class for all Agent Tools (MCP Compliant)
abstract class AgentTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  AgentTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  /// Executes the tool with the given parameters
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref});

  /// Returns the JSON schema for this tool (for LLM function calling)
  Map<String, dynamic> toFunctionSchema() {
    return {
      'name': name,
      'description': description,
      'parameters': {
        'type': 'object',
        'properties': inputSchema,
      },
    };
  }
}
