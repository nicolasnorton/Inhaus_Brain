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
            'description': 'The type of UI component to render. NEW EXAMPLES: Use "dialogue_scene" for 3D/immersive scenes. "avatar_conversation" for character interactions.'
          },
          'data': {
            'type': 'object',
            'description': '''The structured data for the component. CRITICAL: Generate REAL, DETAILED, SPECIFIC data. NO placeholders.
            
--- SCHEMAS ---

For "dynamic_form":
{
  "title": "Creative Brief Intake",
  "fields": [
    {"name": "campaign_name", "type": "text", "label": "Campaign Name", "required": true},
    {"name": "budget", "type": "number", "label": "Budget (\$)", "min": 1000},
    {"name": "channels", "type": "checkbox_group", "label": "Channels", "options": ["Social", "TV", "OOH"]},
    {"name": "launch_date", "type": "date", "label": "Launch Date"}
  ],
  "submit_label": "Generate Proposal"
}

For "mind_map" (GraphView):
{
  "nodes": [
    {"id": 1, "label": "Main Idea", "color": "#FF5733"},
    {"id": 2, "label": "Sub Idea A"},
    {"id": 3, "label": "Sub Idea B"}
  ],
  "edges": [
    {"source": 1, "target": 2},
    {"source": 1, "target": 3}
  ]
}

For "carousel" (Image/Video):
{
  "items": [
    {"type": "image", "url": "https://...", "caption": "Concept A"},
    {"type": "video", "url": "https://...", "caption": "TV Spot Draft"}
  ],
  "aspect_ratio": 16/9
}

For "interactive_table":
{
  "columns": [
    {"name": "id", "label": "ID", "numeric": true},
    {"name": "name", "label": "Service Name"},
    {"name": "status", "label": "Status"}
  ],
  "rows": [
    {"id": 101, "name": "SEO Audit", "status": "Active"},
    {"id": 102, "name": "Content Pack", "status": "Pending"}
  ]
}

For "radial_gauge" (KPIs):
{
  "title": "Campaign Health",
  "value": 75,
  "min": 0,
  "max": 100,
  "ranges": [
    {"start": 0, "end": 40, "color": "red"},
    {"start": 40, "end": 80, "color": "yellow"},
    {"start": 80, "end": 100, "color": "green"}
  ],
  "annotation": "Good"
}

For "stepper" (Guided Workflow):
{
  "steps": [
    {"title": "Research", "content": "Market analysis complete."},
    {"title": "Ideation", "content": "3 concepts generated.", "state": "active"},
    {"title": "Execution", "content": "Pending approval."}
  ],
  "current_step_index": 1
}

EXISTING SCHEMAS:
For "analysis_report" / "trend_report":
{
  "title": "...",
  "sections": [...] (stat_card, chart, text, table)
}
For "kanban_board":
{
  "columns": [
    {"title": "To Do", "cards": ["Task 1", "Task 2"]},
    {"title": "In Progress", "cards": []}
  ]
}
'''
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
