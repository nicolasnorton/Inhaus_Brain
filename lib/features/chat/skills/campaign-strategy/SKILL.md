---
name: campaign-strategy
description: Build a full-funnel paid and organic marketing campaign strategy. Use when the user needs a campaign plan, launch roadmap, channel mix recommendation, or budget allocation across platforms.
license: MIT
metadata:
  version: "1.0"
  source: coreyhaines31/marketingskills
  category: strategy
allowed-tools: bigquery_query web_search generate_chart gen_ui_component
---
# Campaign Strategy Skill

Develop data-backed, full-funnel campaign strategies aligned with client objectives and LatAm market context.

## Instructions

1. **Capture the brief**: Confirm objective (awareness, leads, sales), budget, timeline, target audience, and geography.
2. **Research context**:
   - Use `web_search` to find current platform costs and competitor activity in the client's vertical.
   - Pull historical performance from `bigquery_query` on the `marketing_raw` dataset if prior campaigns exist.
3. **Define the funnel**:
   - **TOFU (Awareness)**: Reach & frequency; TikTok video, Meta broad audience.
   - **MOFU (Consideration)**: Retargeting, content ads; LinkedIn for B2B, Meta for B2C.
   - **BOFU (Conversion)**: Catalog/dynamic ads, lead forms, retargeting hot audiences.
4. **Allocate budget** using the 70/20/10 rule:
   - 70% to proven channels/tactics.
   - 20% to growth experiments.
   - 10% to emerging formats (Reels, TikTok Spark Ads).
5. **Set KPIs**: Define specific, measurable targets per funnel stage.
6. **Build the timeline**: Week-by-week launch plan with creative milestones, A/B test windows, and optimization checkpoints.
7. **Output a strategy document** using `gen_ui_component` if available, otherwise structured Markdown.

## Output Format

- **Executive Summary**: Goal, budget, primary channel, expected ROAS.
- **Channel Mix Table**: Platform | Budget % | Objective | Primary Format | KPI Target.
- **Timeline**: Gantt-style week-by-week breakdown.
- **Risk Factors**: Top 3 risks and mitigation tactics.
