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
            'enum': ['strategy_board', 'budget_chart', 'kanban_board', 'timeline', 'trend_report'],
            'description': 'The type of UI component to render. Use "budget_chart" for any financial/budget data. Use "kanban_board" for task/status lists. Use "strategy_board" for high level plans. Use "trend_report" for market research reports.'
          },
          'data': {
            'type': 'object',
            'description': '''The structured data for the component. CRITICAL: Generate REAL, DETAILED, SPECIFIC data. NO placeholders like "TBD". Use realistic numbers, competitor names, metrics, and insights.

For "trend_report" (MUST include AT LEAST 5-7 diverse sections):
{
  "title": "Specific Report Title (e.g., 'Competitor Analysis Report: Bajaj in Ecuador')",
  "summary": "2-3 sentence executive summary with key findings",
  "sections": [
    {
      "type": "stat_card",
      "items": [
        {"label": "Market Share (Bajaj)", "value": "23.4%", "trend": "up", "change": "+3.2%"},
        {"label": "Market Growth Rate", "value": "12.8%", "trend": "up", "change": "+1.5%"},
        {"label": "Price Index", "value": "\$2,850", "trend": "down", "change": "-5.0%"}
      ]
    },
    {
      "type": "text",
      "title": "Market Overview",
      "content": "Detailed 3-4 sentence analysis of the market landscape, competition dynamics, and key drivers"
    },
    {
      "type": "chart",
      "title": "Market Share Distribution",
      "data": {"Bajaj": 23.4, "Honda": 31.2, "Yamaha": 18.9, "Suzuki": 15.3, "Others": 11.2}
    },
    {
      "type": "trend_list",
      "title": "Key Market Trends",
      "items": [
        {"name": "Electric Mobility Shift", "growth": 35, "description": "2-3 sentence deep dive on why this matters", "impact_score": 0.85},
        {"name": "Price Sensitivity", "growth": 20, "description": "Detailed consumer behavior insight", "impact_score": 0.72},
        {"name": "After-Sales Service", "growth": 18, "description": "Market differentiation factor", "impact_score": 0.68}
      ]
    },
    {
      "type": "text",
      "title": "Competitive Positioning",
      "content": "Specific analysis of Bajaj's strengths (e.g., 'fuel efficiency 45km/L', 'service network: 120 centers') vs competitors"
    },
    {
      "type": "stat_card",
      "title": "Strategic Opportunities",
      "items": [
        {"label": "Untapped Rural Markets", "value": "42%", "trend": "neutral"},
        {"label": "Electric Segment Potential", "value": "\$85M", "trend": "up", "change": "+45%"}
      ]
    },
    {
      "type": "text",
      "title": "Recommendations",
      "content": "3-5 specific, actionable recommendations with rationale"
    }
  ]
}

REQUIREMENTS FOR EXCELLENCE:
1. Numbers MUST be specific and realistic (23.4%, NOT "TBD" or "XX%")
2. Competitor/brand names MUST be real (Honda, Yamaha, NOT "Competitor A")
3. Include 5-7 sections minimum with variety: stat_card, text, chart, trend_list
4. Text content MUST be 2-4 sentences minimum (NO single sentence summaries)
5. Charts MUST have 4-6 data points with realistic distribution
6. Trend items MUST include growth numbers AND detailed descriptions
7. Include both quantitative (metrics, charts) AND qualitative (analysis, recommendations) content

For "strategy_board":
{
  "title": "Specific Strategy Name",
  "objectives": ["Measurable Objective 1 (e.g., 'Increase market share to 28% by Q4')", "Objective 2 with metric", "Objective 3 with timeline"],
  "pillars": [
    {"title": "Pillar 1: [Name]", "description": "2-3 sentence detailed explanation", "kpis": ["Specific KPI with target: CAC less than fifty dollars", "KPI 2", "KPI 3"]},
    {"title": "Pillar 2", "description": "...", "kpis": ["...", "...", "..."]}
  ],
  "milestones": [
    {"date": "2026-Q1", "label": "Specific Launch Event"},
    {"date": "2026-Q2", "label": "Expansion Phase 1"},
    {"date": "2026-Q3", "label": "Market Consolidation"}
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
