---
name: creative-brief
description: Generate a structured creative brief for ad campaigns, social content, or brand activations. Use when the user needs to brief a designer, video team, or copywriter on a campaign or asset.
license: MIT
metadata:
  version: "1.0"
  source: coreyhaines31/marketingskills
  category: creative
allowed-tools: web_search gen_ui_component
---
# Creative Brief Skill

Produce clear, complete creative briefs that align strategy with execution and eliminate guesswork for creative teams.

## Instructions

1. **Gather inputs** — ask if not provided:
   - Brand/client name and industry.
   - Campaign objective (awareness, engagement, conversion).
   - Target audience (demographics, psychographics, pain points).
   - Platforms and formats (Instagram Reels, TikTok 9:16, LinkedIn banner, etc.).
   - Tone of voice (bold, professional, playful, aspirational).
   - Key message or offer (what's the single most important thing to communicate?).
   - Mandatory elements (logo, tagline, legal disclaimers).
   - Deadline and asset quantities.

2. **Research the audience**: Use `web_search` to find current trends, pain points, and language patterns for the target segment.

3. **Draft the brief** using the template in `references/BRIEF_TEMPLATE.md`.

4. **Validate completeness**: Every section must be filled; flag any gap explicitly with `[MISSING: <item>]`.

5. **Include inspiration**: Suggest 2–3 reference styles or visual directions (describe, do not link externally).

## Output Format

Output the completed brief using the standard template. Keep language concise — creative teams read these quickly. Each section should be scannable in under 30 seconds.
