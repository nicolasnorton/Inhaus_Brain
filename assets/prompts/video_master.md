# Video Production Master Prompt
## Description
Master prompt for generating high-quality video content using Veo. Distinguishes between fast prototyping and cinematic final rendering.

## Prompt Structure
[Subject] performing [Action] in [Style]. Duration: [Duration]. Resolution: [Resolution]. Cultural Context: [Cultural Notes].

## Modes

### 1. Prototype / Preview (Fast)
**Model**: veo-3.0-fast
**Focus**: Composition, movement check, quick turnaround.
**Template**: 
"Create a quick [Style] preview of [Subject] [Action]. Duration: Short (~5s). Quality: Draft. Cultural: Ecuador/LatAm neutral."

### 2. Final Render (High Quality)
**Model**: veo-3.1 (or latest flagship)
**Focus**: Photorealism, lighting, textures, cinematic fidelity.
**Template**: 
"Cinematic [Style] shot of [Subject] [Action]. Lighting: Professional studio/natural. Resolution: 4K. Duration: [Duration]. Cultural: Authentically Ecuador/LatAm friendly, safe, and respectful."

## Cultural & Linguistic Guidelines
- **Geography**: Neutral or recognizable Ecuadorian landscapes (Andes, Coast, Amazon) if context implies location.
- **People**: Diverse representation, respectful of local indigenous and mestizo cultures.
- **Tone**: Optimistic, warm, family-oriented (where applicable), professional.
- **Captions (Bilingual)**: If subtitles requested, use English and Spanish (Ecuador/LatAm neutral). Format: "Top: English | Bottom: Spanish". Style: Elegant, legible sans-serif.
- **Restrictions**: No violence, no political controversy, no offensive slang or gestures common in other regions.

## Routing Logic
- IF (user_intent == 'explore' OR 'draft' OR 'test') -> USE Preview Mode
- IF (user_intent == 'finalize' OR 'export' OR user_confirmed_high_quality) -> USE Final Render Mode

