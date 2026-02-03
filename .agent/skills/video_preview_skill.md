---
name: video_preview_skill
description: Generates rapid, low-fidelity video previews using on-device or fast cloud models (Veo Fast).
---

# Video Preview Skill

## Purpose
To enable rapid iteration of video concepts by generating drafts in < 10 seconds before committing to high-quality rendering.

## Application Rules
**Apply this skill when:**
- The user asks for a "preview", "draft", or "sketch" of a video.
- Refining prompts or testing motion concepts.

## Core Guidelines

### 1. Model Selection
- **Primary**: `veo-3.0-fast` (Cloud/Edge Hybrid).
- **Secondary**: LiteRT On-Device (if available).

### 2. Constraints
- **Duration**: 5–8 seconds max.
- **Resolution**: 480p or 360p.
- **Framerate**: 24fps.

### 3. Output Handling
- **Immediate Return**: data-uri or direct GCS link.
- **Feedback Loop**: Ask: "Does this motion look right? Shall I render Final (HQ)?"

## Verification Steps
1. **Speed**: Generation time < 10s?
2. **Playability**: Is the returned binary/URI valid?
3. **Refine Option**: Is the "Refine" button visible?
