---
name: report_lm_skill
description: Specialized logic for generating high-fidelity business reports and dashboards.
---

# Report LM Skill

## Purpose
To synthesize diverse data points into professional, executive-ready reports.

## Application Rules
**Apply this skill when:**
- Generating "Campaign Reports", "Monthly Reviews", or "Audit Summaries".
- Summarizing large datasets.

## Core Guidelines

### 1. Structure
- **Executive Summary**: 3 bullet points max (BLUF - Bottom Line Up Front).
- **Deep Dive**: Detailed analysis with data backing.
- **Action Items**: Clear next steps.

### 2. Visuals via Text
- Use Markdown tables for data.
- Suggest charts where appropriate: "[Chart: Monthly Growth Line Graph]".

### 3. Bilingual Delivery
- Apply `bilingual_output_skill` strictly.
- Ensure numerical formats match the locale (e.g., $1.000,00 vs $1,000.00 where appropriate, though US standard is common in LatAm business).

## Verification Steps
1. **Structure**: Is the BLUF present?
2. **Data**: Are numbers accurate (no hallucinations)?
3. **Tone**: Is it professional/objective?
