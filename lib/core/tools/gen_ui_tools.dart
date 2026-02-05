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
            'enum': ['strategy_board', 'budget_chart', 'kanban_board', 'timeline', 'trend_report', 'recipe_card', 'analysis_report'],
            'description': 'The type of UI component to render. Use "recipe_card" for instructions or processes. Use "analysis_report" for deep dives on data or competitors. Use "strategy_board" for high level plans. Use "trend_report" for market research reports.'
          },
          'data': {
            'type': 'object',
            'description': '''The structured data for the component. CRITICAL: Generate REAL, DETAILED, SPECIFIC data. NO placeholders like "TBD". Use realistic numbers, competitor names, metrics, and insights.

For "analysis_report" or "trend_report" (MUST include AT LEAST 5-7 diverse sections):
{
  "title": "Specific Analysis Title (e.g., 'Risk Analysis: Entering Ecuadorian Motorcycle Market')",
  "summary": "2-3 sentence executive summary with key findings",
  "sections": [
    {
      "type": "stat_card",
      "items": [
        {"label": "Current Market Cap", "value": "\\\$12.5B", "trend": "up", "change": "+5%"},
        {"label": "Risk Level", "value": "Medium", "trend": "down"}
      ]
    },
    {
      "type": "text",
      "title": "Sector Overview",
      "content": "Detailed 3-4 sentence analysis of the sector landscape."
    },
    {
      "type": "chart",
      "title": "Revenue Forecast",
      "data": {"2024": 1500, "2025": 1850, "2026": 2300}
    },
    {
       "type": "check_list",
       "title": "Key Requirements",
       "items": ["Local distribution permit", "Customs clearance", "VAT registration"]
    }
  ]
}

For "recipe_card" (used for ANY step-by-step process, not just food):
{
  "title": "Process/Recipe Name",
  "duration": "Duration (e.g., 2 hours)",
  "difficulty": "Easy/Medium/Hard",
  "ingredients": ["Requirement 1", "Requirement 2"],
  "steps": [
    {"title": "Phase 1: Preparation", "description": "Detailed 2-sentence description of preparation steps."},
    {"title": "Phase 2: Execution", "description": "..."},
    {"title": "Phase 3: Finalization", "description": "..."}
  ]
}'''
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
