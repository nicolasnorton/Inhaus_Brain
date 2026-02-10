# InhausBrain GenUI Architecture Walkthrough

## Overview
This document visualizes the advanced Generative UI (GenUI) system v1.4, which enables the AI Assistant to render rich, interactive Flutter widgets directly in the chat stream based on user intent.

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
