# InhausBrain GenUI Architecture Walkthrough

## Overview
This document visualizes the advanced Generative UI (GenUI) system v1.4, which enables the AI Assistant to render rich, interactive Flutter widgets directly in the chat stream based on user intent.

### Update (V3.7): Cutting-Edge Gemini 3 Upgrade

- **Model Advancement**: Upgraded the entire system from Gemini 1.5 to **Gemini 3 Flash & Pro Preview**.
- **Tool-Call Stability**: Verified that Gemini 3 maintains the function-calling stability established in the 1.5 downgrade, resolving the 400 errors seen in 2.5.
- **Improved Reasoning**: Agents now leverage 3.0 intelligence for research, strategy, and asset generation.
- **Mass Sweep**: Completed a codebase-wide replacement of model IDs in Flutter (frontend), Python (backend), and legacy Node.js services.

#### Verified Features
- [x] **Image Generation**: "create image of cats in space" successfully triggers the `generate_image` tool via Gemini 3 Flash.
- [x] **Context Awareness**: 1M+ token context support maintained for complex agency workflows.
- [x] **Production Deployment**: All Cloud Functions and Web Hosting updated to use the new model stack.

Rendered at: [inhausbrain-beta.web.app](https://inhausbrain-beta.web.app)

## 1. High-Level Flow
The following sequence diagram illustrates how a user request flows through the AI engine, tool execution, and final UI rendering.

```mermaid
sequenceDiagram
    participant User
    participant AssistantService
    participant LLM as AI Engine (Gemini)
    participant Tool as GenUI Tool
    participant UI as AiAssistantOverlay

    User->>AssistantService: "Create a campaign mind map"
    AssistantService->>LLM: Send Prompt + Tools
    LLM->>LLM: Decide to use `gen_ui_component`
    LLM-->>AssistantService: Tool Call (component_type: "mind_map", data: {...})
    
    AssistantService->>Tool: Execute `gen_ui_component`
    Tool-->>AssistantService: Return structured JSON payload
    
    AssistantService->>UI: Add Message with `uiPayload`
    UI->>UI: Match type "mind_map" in `_buildGenUI`
    UI-->>User: Render `MindMapWidget`
```

## 2. Component Hierarchy
The GenUI system is built on a modular widget architecture. The `AiAssistantOverlay` acts as the central router, dispatching data to specific widget implementations.

```mermaid
classDiagram
    class AiAssistantOverlay {
        +build(context)
        -_buildGenUI(payload)
    }

    class GenUIWidget {
        <<interface>>
        +Map data
    }

    AiAssistantOverlay ..> DynamicFormWidget : renders
    AiAssistantOverlay ..> MindMapWidget : renders
    AiAssistantOverlay ..> MediaCarouselWidget : renders
    AiAssistantOverlay ..> InteractiveTableWidget : renders
    AiAssistantOverlay ..> RadialGaugeWidget : renders
    AiAssistantOverlay ..> StepperWizardWidget : renders
    AiAssistantOverlay ..> AccordionWidget : renders
    AiAssistantOverlay ..> WordCloudWidget : renders
    AiAssistantOverlay ..> CalendarWidget : renders

    class DynamicFormWidget {
        +flutter_form_builder
    }
    class MindMapWidget {
        +graphview
    }
    class MediaCarouselWidget {
        +carousel_slider
    }
    class InteractiveTableWidget {
        +syncfusion_flutter_datagrid
    }
```

## 3. Data Flow Example: Mind Map
When the AI generates a mind map, it constructs a JSON object that `MindMapWidget` parses into a graph structure.

```mermaid
flowchart LR
    A[LLM JSON Output] --> B[Assistant Message]
    B --> C[AiAssistantOverlay]
    C --> D{Check Component Type}
    D -- "mind_map" --> E[MindMapWidget]
    
    E --> F[Parse Nodes & Edges]
    F --> G[GraphView Layout Engine]
    G --> H[Render Interactive Canvas]
```

## 4. Key Packages
- **Dynamic Forms**: `flutter_form_builder`
- **Charts & Gauges**: `syncfusion_flutter_gauges`
- **Data Grids**: `syncfusion_flutter_datagrid`
- **Graphs**: `graphview`
- **Carousels**: `carousel_slider`
