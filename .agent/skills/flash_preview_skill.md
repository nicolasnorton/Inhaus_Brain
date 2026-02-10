---
name: flash_preview_skill
description: Logic for generating fast, cloud-based previews using Gemini Flash-Lite before high-fidelity generation.
---

# Flash Preview Skill

## Purpose
To provide near-instantaneous, high-quality visual or conceptual previews using Gemini 2.0 Flash-Lite, allowing users to iterate quickly without the latency of Pro models or the quality loss of on-device models.

## Application Rules
**Apply this skill when:**
- The user requests visual generation (Image/Video) but hasn't approved a "Final Render".
- The user needs a "draft", "concept", or "sketch".
- Speed and iteration are prioritized over final pixel-perfection.

## Core Guidelines

### 1. Routing Logic
- **Flash First**: ALWAYS attempt initial generation with `gemini-2.0-flash-lite-001`.
- **Pro Second**: If the user approves the preview or requests "Final Output", route to the relevant Pro/Specialized model.

### 2. Performance Constraints
- **Latency**: Previews should aim for < 3 seconds response time.
- **Visuals**: Use "Fast" variants of generation models (e.g., `veo-3.1-fast-generate-preview`).

### 3. User Experience
- **Labeling**: Clearly label outputs as "⚡ Flash Preview".
- **Actionable**: Provide a clear "Render Final" or "Upscale" button in the UI.

## Verification Steps
1. **Model Check**: Is the request using Flash-Lite?
2. **UI Feedback**: Is the "Draft" status communicated clearly?
3. **Upgrade Path**: Is there a clear path to high-fidelity generation?
