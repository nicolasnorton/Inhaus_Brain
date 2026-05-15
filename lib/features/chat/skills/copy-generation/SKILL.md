---
name: copy-generation
description: Write high-converting marketing copy for ads, landing pages, emails, and social posts. Use when the user needs ad headlines, body copy, CTAs, email subject lines, or social captions.
license: MIT
metadata:
  version: "1.0"
  source: coreyhaines31/marketingskills
  category: creative
allowed-tools: web_search
---
# Copy Generation Skill

Write persuasive, on-brand marketing copy tailored to platform, audience, and conversion objective.

## Instructions

1. **Identify the format** — different copy rules apply per channel:
   - **Meta / TikTok Ad**: Primary text (≤125 chars for mobile preview), headline (≤40 chars), description (≤30 chars), CTA button.
   - **LinkedIn Ad**: Introductory text (≤150 chars preview), headline (≤70 chars), description (≤100 chars).
   - **Email**: Subject line (≤50 chars), preview text (≤100 chars), body (scannable, 150–300 words), single CTA.
   - **Social Caption**: Hook in first line (no "See more" cutoff), body, hashtags (3–5 relevant), CTA.
   - **Landing Page**: Hero headline, sub-headline, 3 benefit bullets, social proof line, CTA.

2. **Apply the copywriting framework** appropriate to the objective:
   - **Awareness**: AIDA (Attention → Interest → Desire → Action).
   - **Consideration**: PAS (Problem → Agitation → Solution).
   - **Conversion**: FAB (Feature → Advantage → Benefit) + urgency/scarcity.

3. **Tone alignment**: Match the brand voice specified in the brief. Default to active voice, second person ("you"), and specific over generic.

4. **Bilingual output**: Always generate both Spanish (ES) and English (EN) versions for LatAm campaigns unless instructed otherwise.

5. **Generate 3 variations** of the primary copy element so the team can A/B test.

6. **Flag platform policy risks**: Mention if copy contains superlatives ("best", "#1"), health claims, or before/after implications that may trigger ad rejection.

## Output Format

For each asset:
```
[EN] Headline: ...
[EN] Body: ...
[EN] CTA: ...

[ES] Titular: ...
[ES] Cuerpo: ...
[ES] CTA: ...
```

Provide 3 variations labeled V1, V2, V3. End with one sentence on which variation to test first and why.
