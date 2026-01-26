import 'package:inhaus_brain/core/mcp/agent_tool.dart';

class GenUIComponentTool extends AgentTool {
  GenUIComponentTool() : super(
    name: 'gen_ui_component',
    description: 'Renders a rich, interactive UI component in the chat. Use this for strategies, budgets, charts, and wireframes.',
    inputSchema: {
       // Defined in toFunctionSchema override below, but provided here for completeness/base class
       'component_type': {
          'type': 'string',
          'description': 'The type of UI component to render'
       },
       'data': {
          'type': 'object',
           'description': 'The structured data required by the component'
       },
       'summary_text': {
          'type': 'string',
           'description': 'A brief text summary to show alongside the component'
       }
    }
  );

  @override
  Map<String, dynamic> toFunctionSchema() => {
      'name': name,
      'description': description,
      'parameters': {
        'type': 'object',
        'properties': {
          'component_type': {
            'type': 'string',
            'enum': ['strategy_board', 'budget_chart', 'kanban_board', 'timeline'],
            'description': 'The type of UI component to render. Use "budget_chart" for any financial/budget data. Use "kanban_board" for task/status lists. Use "strategy_board" for high level plans.'
          },
          'data': {
            'type': 'object',
            'description': 'The structured data required by the component'
          },
          'summary_text': {
            'type': 'string',
            'description': 'A brief text summary to show alongside the component'
          }
        },
        'required': ['component_type', 'data']
      }
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    // This tool is a "UI Trigger". The actual rendering happens in the presentation layer.
    // We just return the data so AssistantService can package it into the message.
    return ToolResult.success({
      'is_gen_ui': true,
      'component_type': args['component_type'],
      'ui_data': args['data'],
      'summary': args['summary_text'],
    });
  }
}
