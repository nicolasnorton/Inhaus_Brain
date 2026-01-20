# Project Context: Inhaus Brain

## Overview
**Inhaus Brain** is an agentic workflow management application for a marketing agency. It coordinates tasks between human agents (Account Managers, Designers) and AI agents (Gemini, Vertex AI). The app automates the marketing lifecycle from research to publishing.

## Tech Stack
- **Frontend**: Flutter (Mobile + Web)
- **State Management**: Riverpod (Code Generation `flutter_riverpod` / `riverpod_annotation` preferred)
- **Routing**: GoRouter
- **Backend**: Firebase (Auth, Firestore, Storage) + Cloud Functions
## AI Architecture: Hybrid Multi-Modal Suite
The application coordinates several specialized models via the `EdgeAIService` and specialized **MCP Tools**:

### 1. Multi-Modal Suite
- **Gemma / Gemini (Pro/Flash)**: Primary reasoning engines for research, copywriting, and strategy auditing.
- **Imagen 3**: Triggers via `ImageGenerationTool` for conceptual visual assets.
- **Veo**: SOTA video generation interface via `VideoGenerationTool`.
- **Lyria**: Advanced music/soundtrack composition via `AudioGenerationTool`.
- **Nano Banana 🍌**: Agentic visual refinement and image editing.
- **External Providers**: Support for **OpenAI**, **Anthropic**, **xAI (Grok)**, **Runway**, **Midjourney**, and **Eleven Labs** via `EdgeAIService` routing.

### 2. Model Context Protocol (MCP) Standards
All agent capabilities are abstracted into the `AgentTool` (at `lib/core/mcp/`) class, providing a standardized input/output schema:
- **`WebSearchTool`**: Drives the Research Agent; returns structured market snippets and URLs.
- **`ImageGenerationTool`**: Interfaces with Imagen/Banana; returns generated asset URLs.
- **`VideoGenerationTool` / `AudioGenerationTool`**: Specialized tool interfaces for multi-modal expansion.

### 3. Agent Roster & Behavior
The Inhaus Brain features an 11-step specialized agency roster:
- **Trend Scout**: Analyzes real-time market signals and bolts.
- **Account Director**: Manages client expectations and campaign high-level strategy.
- **Strategist**: Synthesizes research into actionable concepts.
- **Creative Agent**: Generates visual prompts and moodboards.
- **Copywriter Agent**: Specialized text generation for social media and collateral.
- **Editorial Manager**: Plans content calendars and ensures brand consistency.
- **Media Buyer**: Optimizes ad spend and placement logic (Sensitive).
- **Performance Analyst**: Evaluates campaign data and metrics.
- **Developer Agent**: Generates code (Flutter/Gen UI).
- **Data Engineer Agent**: Manages schemas and data flow (Sensitive).
- **Security Agent**: Audits all pipeline inputs and final outputs.

### 4. Agent Development Kit (ADK)
- **`AdkService`**: Coordinates pipeline execution, tool invocation, and events.
- **`PipelineContext`**: Maintains a shared memory of `AdkArtifact`s across steps.
- **Streaming**: Full support for real-time token streaming and tool-usage feedback.
- **Visual Canvas**: `WorkflowCanvasScreen` provides a node-based editor for DAG pipelines.
- **Advanced Flow Logic**: Support for `IfElseNode`, `SwitchCaseNode`, `ForEachLoopNode`, and `WhileLoopNode` with nested execution.
- **Integrated Debug Tools**: 
    - **`VariableInspector`**: Real-time tree view of `PipelineContext` variables with live editing.
    - **`TestRunDialog`**: Sandbox for executing single nodes with custom inputs.
    - **`RunHistory`**: Persistent logs of execution paths and performance metrics.
- **User Input & Variables**: Persistent variable store in `PipelineContext` with dynamic resolution in `AdkService`.

### 5. Publishing & Deployment
The `PublishService` coordinates the deployment of workflows across multiple platforms:
- **Web Applications**: Branded storefronts for workflow/chatflow applications.
- **API Endpoints**: REST server with API key management and per-app rate limiting.
- **Embed Widgets**: Client-side chat widget and iframe generation.
- **MCP Server**: Exposure of workflows as tools via the Model Context Protocol.

### 6. Reports & Analytics
- **Reports Agent**: An autonomous analyst that synthesizes data from BigQuery, Drive, and Gmail.
- **Client-Centric Reporting**: A dedicated "Reports" tab within the Client Detail Screen provides high-level dashboards and active report cards.
- **Visual Dashboards**: Integrated dashboard widgets for real-time performance monitoring.

### 7. Workspace & Configuration
- **Model Providers**: Unified BYOK system for LLM, Embedding, Rerank, and Voice providers.
- **Streamlined Navigation**: The Client Detail Screen features a simplified tab structure (Overview includes Contacts, Integrations includes Commerce) for improved UX.
- **Plugins**: Modular extension system for integrating secondary AI services (e.g., LlamaCloud).
- **Responsive Dashboard**: `DashboardHome` uses `LayoutBuilder` for adaptive navigation widgets (4 cols desktop / 3 cols mobile).

## Authentication & Security
- **Auth Flow**: Uses `AuthService` with `FirebaseAuth` and `GoogleSignIn`. Includes a `MockAuthService` fallback.
- **Security Guardian**: Mandatory `SecurityAgent` audits on pipeline start and finish. Intercepts sensitive agents (Media Buyer, Data Eng).
- **Secrets Vault**: Uses `SecretVaultService` for secure on-device API key storage.
- **Master Prompts (Agent Brain)**: Managed via `SystemPromptsService`. Admin-only edits allow plumbing custom system instructions directly into each agent's execution flow.

## Coding Conventions
- **State Management**: Riverpod `StateNotifier` (e.g., `ChatNotifier`) coordinates agent logic.
- **Multi-Modal Flow**: Attachments in `ChatMessage` are used to render generated images/videos in the chat stream.
- **UI**: Premium dark-mode styling with Glassmorphism and micro-animations.

## Deployment & Infrastructure (Step #4)
- **Containerization**: Flutter Web is packaged into a multi-stage Docker image served by Nginx.
- **CI/CD**: `cloudbuild.yaml` coordinates the transition from GitHub to Google Artifact Registry and Cloud Run. Supports **dynamic version tagging** (Git SHA/Timestamp) for history and rollbacks.
- **IaC**: Terraform models the infrastructure for repeatable, scalable environments.
