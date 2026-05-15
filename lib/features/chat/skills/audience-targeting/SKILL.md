---
name: audience-targeting
description: Build audience segments, lookalike strategies, and retargeting funnels for paid media. Use when the user needs to define who to target, build custom audiences, or structure a retargeting hierarchy.
license: MIT
metadata:
  version: "1.0"
  source: coreyhaines31/marketingskills
  category: strategy
allowed-tools: bigquery_query web_search generate_chart
---
# Audience Targeting Skill

Design precise audience architectures that minimize wasted spend and maximize relevance.

## Instructions

1. **Define the audience tiers**:
   - **Cold (Prospecting)**: Interest, demographic, or lookalike audiences. No prior brand interaction.
   - **Warm (Consideration)**: Website visitors (30-day), video viewers (50%+), social engagers (90-day).
   - **Hot (Conversion)**: Add-to-cart, checkout abandoners, lead form openers, customer list.

2. **Build the prospecting layer**:
   - Use demographic filters (age, location, language) first to constrain reach.
   - Layer interests relevant to the product vertical (see `references/AUDIENCE_TAXONOMY.md`).
   - Create a 1–2% lookalike from the best-performing customer segment.

3. **Structure retargeting exclusions**:
   - Always exclude existing purchasers from prospecting campaigns.
   - Exclude 1-day website visitors (low intent) from BOFU retargeting.
   - Cap frequency: 3–5 impressions/week per user for retargeting.

4. **Pull audience insights** via `bigquery_query`:
   - Query `crm_data` or `pixel_events` tables for first-party segments if available.
   - Identify highest-LTV customer attributes to seed lookalikes.

5. **Estimate reach**: Use platform-specific minimums (see reference) and flag if estimated audience is too small (<5,000 for Meta, <300 for LinkedIn).

6. **Document the audience map** as a table with Audience Name, Platform, Type, Size Estimate, Exclusions, and Suggested Budget %.

## Output Format

- **Audience Architecture Table**: All segments across all platforms.
- **Exclusion Logic**: Which audiences are excluded from which campaigns.
- **Lookalike Seed**: Which source audience and why.
- **Risk flags**: Audience overlap warnings, small audience size alerts.
