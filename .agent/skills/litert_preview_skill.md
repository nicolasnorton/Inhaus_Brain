---
name: litert_preview_skill
description: Logic for generating fast, on-device previews using LiteRT models before cloud generation.
---

# LiteRT Preview Skill

## Purpose
To provide instantaneous feedback (images/video/text) using on-device models, allowing users to iterate quickly before committing to expensive/slow cloud generations.

## Application Rules
**Apply this skill when:**
- The user requests visual generation (Image/Video).
- The user needs a "draft" or "sketch".
- Network connectivity is low or latency is critical.

## Core Guidelines

### 1. Routing Logic
- **Preview First**: ALWAYS attempt generation with LiteRT (e.g., Gemini Nano, Veo Fast On-Device) first.
- **Cloud Second**: If the user approves the preview or requests "Final Quality", route to Vertex AI/Cloud.

### 2. Performance constraints
- **Time Limit**: Previews must generate in < 5 seconds.
- **Resolution**: Lower resolution is acceptable (e.g., 360p video, 512x512 image).
- **Format**: Return visible artifacts immediately (do not wait for cloud upload).

### 3. User Expectation Management
- **Labeling**: Clearly label outputs as "⚡ LiteRT Preview" or "Draft".
- **Upsell**: Provide a clear "Render Final" action for the high-quality version.

## Verification Steps
1. **Speed Check**: Did generation start immediately?
2. **Fallback Check**: If LiteRT fails, is the cloud fallback transparent?
3. **UI Feedback**: Is the "Preview" badge visible?
