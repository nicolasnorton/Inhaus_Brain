---
name: bilingual_output_skill
description: Standardizes bilingual (English/Spanish) output generation for global and LatAm audiences.
---

# Bilingual Output Skill

## Purpose
To ensure all agent outputs (summaries, reports, creative copy) are available in both English and Spanish, formatted clearly and consistently.

## Application Rules
**Apply this skill when:**
- The user requests content in "Both" or "Bilingual".
- Generating "Chief of Staff" summaries (Brian).
- Creating client-facing reports for mixed regions.

## Core Guidelines

### 1. Structure
- **Format**: Use a split structure or clear headers.
    - **Option A (Split)**:
      ```markdown
      ## 🇬🇧 English Section
      Content...

      ## 🇪🇸 Sección en Español
      Contenido...
      ```
    - **Option B (Inline)**:
      `**Role**: Chief of Staff / **Rol**: Jefe de Gabinete`

### 2. Translation Quality
- **Contextual, Not Literal**: Translate the *meaning* and *intent*, not just word-for-word.
  - *Bad*: "Running a campaign" -> "Corriendo una campaña" (Anglicism).
  - *Good*: "Running a campaign" -> "Ejecutando una campaña".
- **Terminology**: Use industry-standard marketing terms in Spanish (e.g., "Engagement", "Leads", "Funnel" are often used as-is, but define if unclear).

### 3. Consistency
- Ensure formatting (bolding, lists, emojis) is identical across both languages for visual symmetry.

## Verification Steps
1. **Completeness**: Are both language sections present?
2. **Accuracy**: Is the Spanish natural and professional (LatAm neutral)?
3. **Parity**: Do both versions convey the exact same key information?
