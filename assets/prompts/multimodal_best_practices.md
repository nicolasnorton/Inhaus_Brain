# Multimodal Best Practices (Inhaus Brain)

## Image Generation (Imagen / Veo / Midjourney)
**Goal**: Photorealistic, high-end commercial aesthetic.
**Defaults**: 
- Aspect Ratio: `16:9` (Cinematic) or `4:5` (Social).
- Lighting: `Cinematic lighting`, `Golden hour`, `Studio lighting`.
- Quality: `8k`, `UHD`, `Masterpiece`.

### Golden Prompt Structure (Golden Prompt)
> [Subject] + [Action/Context] + [Art Style] + [Lighting/Cam Angle] + [Technical Specs] + [Negative Prompt]

### Example (Ecuador Banking)
*Positive*: 
"A modern professional Latina woman paying with a smartphone at a chic cafe in Quito, Cumbayá district. Digital holographic overlay of a banking app success screen. Warm sunset lighting, depth of field, 85mm lens, photorealistic, 8k resolution, elegant, cyberpunk accents."

*Negative*:
"blurry, distorted hands, low quality, oversaturated, text watermark, ugly, deformed."

## Video Generation (Veo)
**Goal**: Short, coherent clips (5-10s) for B-Roll.
**Constraints**:
- Low motion complexity (avoid confused physics).
- Focus on atmosphere.

### Golden Prompt Example
"Drone shot: sweeping view of the Amazon rainforest canopy at sunrise, transitioning to a modern eco-lodge. High detail, slow smooth motion, 4k."

## Generative UI (GenUI)
**Goal**: Interactive Flutter Widgets via JSON payload.
**Rules**:
1. Never output raw Dart code unless requested. Use `gen_ui_component` tool.
2. Structure data clearly for `strategy_board` or `budget_chart`.

### Example Payload
```json
{
  "tool_call": {
    "name": "gen_ui_component",
    "args": {
      "component_type": "kanban_board",
      "data": {
        "columns": [
          {"id": "todo", "title": "To Do", "tasks": ["Research Competitors"]},
          {"id": "done", "title": "Done", "tasks": ["Kickoff Meeting"]}
        ]
      }
    }
  }
}
```
