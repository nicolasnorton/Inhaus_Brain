# InhausBrain GenUI Guide (v1.5 - Flawless Export Upgrade)

## Overview
This document outlines the expanded suite of Generative UI components available in InhausBrain. These components allow the AI Assistant to render rich, interactive interfaces directly in the chat stream, enhancing the user's ability to visualize data, plan workflows, and execute tasks.

## Available Component Types

### 1. High-Value Interactive Components (New in v1.4)

| Component Type | Usage | Package Used |
| :--- | :--- | :--- |
| **`dynamic_form`** | Brief intake forms, surveys, data entry | `flutter_form_builder` |
| **`kanban_board`** | Task tracking, workflow status, agent management | Custom / `kanban_board_widget` |
| **`mind_map`** | Brainstorming, concept mapping, flow diagrams | `graphview` (BuchheimWalker Tree) |
| **`carousel`** | Asset previews (image/video), portfolio review | `carousel_slider` |
| **`interactive_table`** | Service catalogs, data grids, sortable lists | `syncfusion_flutter_datagrid` |
| **`radial_gauge`** | KPI tracking, health scores, performance metrics | `syncfusion_flutter_gauges` |
| **`accordion`** | FAQ sections, long summary reports, expanding details | Native `ExpansionTile` |
| **`stepper`** | Guided workflows, multi-step processes, tutorials | `im_stepper` |
| **`word_cloud`** | Keyword analysis, sentiment visualization, tag clouds | Custom `Wrap` (Weighted) |
| **`calendar`** | Content schedules, editorial calendars, event timelines | `table_calendar` |
| **`code_viewer`** | Syntax-highlighted code snippets with copy action | Custom / `SelectableText` |
| **`video_player`** | Video playback with captions and autoplay | `video_player` wrapper |
| **`deep_analysis`** | Strictly structured research reports with PDF export | Custom / `deep_analysis_report_widget` |

---

### 2. Standard Reporting Components (Legacy v1.0)

| Component Type | Usage |
| :--- | :--- |
| **`strategy_board`** | High-level strategic pillars and initiatives |
| **`budget_chart`** | Financial breakdowns and allocation |
| **`trend_report`** | Market analysis, competitor research |
| **`recipe_card`** | Step-by-step instructions (SOPs) |
| **`analysis_report`** | Deep dive data analysis with mixed content |

---

## JSON Schema & Examples

The `gen_ui_component` tool accepts a `data` object. The structure of this object varies by `component_type`.

### Dynamic Form (`dynamic_form`)
Use for collecting structured input from the user.
```json
{
  "title": "Creative Brief Intake",
  "fields": [
    {"name": "project_name", "type": "text", "label": "Project Name", "required": true},
    {"name": "budget", "type": "number", "label": "Budget ($)", "min": 1000},
    {"name": "channels", "type": "checkbox_group", "label": "Channels", "options": ["Social", "Email", "Web"]}
  ],
  "submit_label": "Start Project"
}
```

### Mind Map (`mind_map`)
Use for visualizing relationships or hierarchies.
```json
{
  "title": "Campaign Structure",
  "nodes": [
    {"id": 1, "label": "Core Idea", "color": "#FF5733"},
    {"id": 2, "label": "Channel Strategy"},
    {"id": 3, "label": "Content Plan"}
  ],
  "edges": [
    {"source": 1, "target": 2},
    {"source": 1, "target": 3}
  ]
}
```

### Media Carousel (`carousel`)
Use for showcasing generated assets or mood boards.
```json
{
  "title": "Visual Directions",
  "items": [
    {"type": "image", "url": "https://example.com/img1.jpg", "caption": "Option A: Minimalist"},
    {"type": "video", "url": "https://example.com/vid1.mp4", "caption": "Motion Test"}
  ],
  "aspect_ratio": 1.77
}
```

### Interactive Table (`interactive_table`)
Use for dense data display.
```json
{
  "title": "Service Catalog",
  "columns": [
    {"name": "service", "label": "Service Name"},
    {"name": "price", "label": "Price", "numeric": true},
    {"name": "status", "label": "Availability"}
  ],
  "rows": [
    {"service": "SEO Audit", "price": 1500, "status": "Available"},
    {"service": "Content Pack", "price": 800, "status": "Waitlist"}
  ]
}
```

### Radial Gauge (`radial_gauge`)
Use for single-metric KPIs.
```json
{
  "title": "Campaign Health Score",
  "value": 85,
  "min": 0,
  "max": 100,
  "ranges": [
    {"start": 0, "end": 50, "color": "red"},
    {"start": 50, "end": 80, "color": "orange"},
    {"start": 80, "end": 100, "color": "green"}
  ],
  "annotation": "Excellent"
}
```

### Stepper Wizard (`stepper`)
Use for guiding users through a process.
```json
{
  "title": "Launch Sequence",
  "steps": [
    {"title": "Preparation", "content": "Gather assets.", "icon": 57353}, // Icons.check_circle code point
    {"title": "Review", "content": "Approve drafts.", "state": "active"},
    {"title": "Launch", "content": "Go live."}
  ],
  "current_step_index": 1
}
```
*Note: Icon codes are optional integer code points for Material Icons.*

### Code Viewer (`code_viewer`)
Use for displaying syntax-highlighted code.
```json
{
  "title": "Example Function",
  "language": "dart",
  "code": "void main() {\n  print('Hello World');\n}"
}
```

### Video Player (`video_player`)
Use for embedding video content.
```json
{
  "title": "Product Demo",
  "url": "https://example.com/demo.mp4",
  "caption": "Walkthrough of new features",
  "autoplay": false
}
```

### Deep Analysis Report (`deep_analysis`)
Strictly structured report with metrics and markdown content.
```json
{
  "title": "Market Trends 2026",
  "executive_summary": "Sustainable luxury is dominating high-end retail...",
  "metrics": [
    {"name": "Growth", "value": "12.4%", "trend": "up"},
    {"name": "Market Cap", "value": "$4.2B", "trend": "flat"}
  ],
  "key_insights": [
    "Digital twins are becoming standard",
    "Circular economy is a key driver"
  ],
  "strategic_recommendations": [
    "Invest in recycled material R&D",
    "Partner with green supply chains"
  ],
  "detailed_analysis": "# Sector Overview\nDetailed markdown content goes here..."
}
```

---

## Implementation Notes
- All components are rendered in `AiAssistantOverlay` via `_buildGenUI`.
- Styles automatically adapt to Dark Mode (InhausBrain default).
- For `carousel` and `mind_map`, ensure external URLs are valid/whitelisted if using strict CSP (though InhausBrain is loose on this currently).
### 3D Dialogue Scene (`dialogue_scene`)
Immersive character interactions with environment and camera control.
```json
{
  "personas": [
    {"id": "agent_a", "name": "Strategist", "avatar_url": "https://models.readyplayer.me/avatar1.glb"},
    {"id": "agent_b", "name": "Creative", "avatar_url": "https://models.readyplayer.me/avatar2.glb"}
  ],
  "text": "Let's review the campaign concept.",
  "environment_id": "office", // "office", "zen_garden", "stage"
  "camera_anchor": "presenter" // "default", "presenter", "audience", "orbit"
}
```

### Director Tool (`direct_scene`)
Used by the assistant to update a scene in real-time.
```json
{
  "action": "set_camera",
  "params": {"anchor": "orbit"}
}
```

### Live Multimodal Session (`live_multimodal_session`)
Real-time, bidirectional voice and audio interaction with Gemini 2.0 Flash (Preview).
```json
{
  "objective": "Analyze the live brief and provide feedback.",
  "stream_url": null // Optional URL for external stream
}
```

---

### Default State
- **Desktop**: The side canvas now defaults to a **closed (dismissed)** state on application load.
- **Mobile**: Functionality remains unchanged (modal/drawer).

### Auto-Open Logic
The canvas will **automatically open** when:
1. A GenUI component is generated by the Assistant.
2. An image or video asset is generated.
3. The user explicitly clicks "View in Canvas" or a similar action.
4. `CanvasNotifier.show[Content]` methods are invoked programmatically.

This ensures a clean initial interface while maintaining immediate access to rich content when it becomes available.
