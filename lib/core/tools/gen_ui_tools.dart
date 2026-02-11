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
            'enum': [
              'strategy_board', 'budget_chart', 'kanban_board', 'timeline', 'trend_report', 'recipe_card', 'analysis_report',
              'dynamic_form', 'mind_map', 'carousel', 'interactive_table', 'radial_gauge', 'accordion', 'stepper', 'word_cloud', 'calendar',
              'dialogue_scene', 'avatar_conversation'
            ],
            'description': 'The type of UI component to render.'
          },
          'data': {
            'type': 'object',
            'description': 'The structured data for the component. CRITICAL: Generate REAL, DETAILED, SPECIFIC data. Match the schema for the chosen component_type.'
          },
          'summary_text': {
            'type': 'string',
            'description': 'A 2-3 sentence executive summary highlighting the most critical insights'
          }
        },
        'required': ['component_type', 'data']
      }
  };

  @override
  Future<ToolResult> execute(Map<String, dynamic> args, {dynamic ref}) async {
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
