---
name: ad-performance-analysis
description: Analyze paid ad performance across Meta, TikTok, and LinkedIn. Use when the user asks about campaign metrics, ROAS, CTR, CPC, conversion rates, or wants to compare platform results.
license: MIT
metadata:
  version: "1.0"
  source: coreyhaines31/marketingskills
  category: performance
allowed-tools: bigquery_query generate_chart compare_platforms web_search
---
# Ad Performance Analysis Skill

Analyze and interpret cross-platform ad performance data to surface actionable insights.

## Instructions

1. **Identify the scope**: Ask which platforms (Meta, TikTok, LinkedIn) and date range if not specified.
2. **Pull data**: Use `bigquery_query` to query the `marketing_raw` dataset tables (`tiktok_ads_raw`, `linkedin_ads_raw`, `meta_ads_raw`).
3. **Calculate core KPIs** for each platform:
   - **CTR** = clicks / impressions × 100
   - **CPC** = spend / clicks
   - **CPM** = spend / impressions × 1000
   - **ROAS** = conversion_value / spend
   - **CVR** = conversions / clicks × 100
4. **Benchmark against industry standards**: Use `web_search` to fetch current benchmarks for the client's vertical.
5. **Visualize**: Use `generate_chart` to render a bar or line chart comparing platforms side-by-side.
6. **Summarize findings** in a ranked list: best-performing platform first, with one specific optimization recommendation per platform.
7. **Flag anomalies**: Call out any metric that deviates >20% from the 7-day rolling average.

## Output Format

- Lead with a one-sentence executive summary (ROAS or top-line spend efficiency).
- Follow with a KPI table (platform × metric grid).
- Close with 3 prioritized action items.
