---
name: veo_final_skill
description: Orchestrates high-definition video generation using Veo 3 / Veo 3.1 via Vertex AI.
---

# Veo Final Skill

## Purpose
To produce broadcast-quality video assets after a concept has been validated via preview.

## Application Rules
**Apply this skill when:**
- The user requests "Final Render", "HQ", or "HD".
- A preview has been explicitly approved.
- Creating final campaign assets.

## Core Guidelines

### 1. Model Selection
- **Primary**: `veo-3.0-high-quality` (Vertex AI).

### 2. Parameters
- **Duration**: 10–60 seconds (as requested).
- **Resolution**: 1080p or 4K.
- **Aspect Ratio**: Match target channel (9:16 for Social, 16:9 for Web).

### 3. Operation Management
- **Polling**: Use robust polling (up to 180s) for LRO (Long Running Operations).
- **Fallback**: If Veo fails, fallback to `imagen-3.0-video` (last resort) and notify user.
- **Download**: Ensure the "Download" button is available for valid MP4s.

## Verification Steps
1. **Quality Check**: Resolution matches request?
2. **Artifact Check**: Is the MP4 downloadable?
3. **Download**: Verify the download button functions.
