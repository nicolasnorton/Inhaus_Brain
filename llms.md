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

### 2. Model Context Protocol (MCP) Standards
All agent capabilities are abstracted into the `AgentTool` (at `lib/core/mcp/`) class, providing a standardized input/output schema:
- **`WebSearchTool`**: Drives the Research Agent; returns structured market snippets and URLs.
- **`ImageGenerationTool`**: Interfaces with Imagen/Banana; returns generated asset URLs.
- **`VideoGenerationTool` / `AudioGenerationTool`**: Specialized tool interfaces for multi-modal expansion.

### 3. Agent Roster & Behavior
- **ResearchAgent**: Uses `WebSearchTool` and Knowledge Context to analyze trends.
- **CreativeAgent**: Generates visual prompts and moodboards. Triggered via A2A handoff.
- **CopywritingAgent**: Specialized text generation for social media and blogs.
- **DeveloperAgent**: Code generation (Flutter/Gen UI).
- **OrchestratorAgent**: Audits all responses for brand safety and strategic alignment before displaying to the user.

## Authentication & Security
- **Auth Flow**: Uses `AuthService` with `FirebaseAuth` and `GoogleSignIn`. Includes a `MockAuthService` fallback with a persistent `MockUser` for offline/web prototyping.
- **Secrets Vault**: Uses `flutter_secure_storage` via `SecretVaultService` to keep BYO-API keys local and secure.
- **Master Prompts**: Managed via `SystemPromptsService` (`shared_preferences`), allowing user-defined overrides for every agent's system instruction.

## Coding Conventions
- **State Management**: Riverpod `StateNotifier` (e.g., `ChatNotifier`) coordinates agent logic.
- **Multi-Modal Flow**: Attachments in `ChatMessage` are used to render generated images/videos in the chat stream.
- **UI**: Premium dark-mode styling with Glassmorphism and micro-animations.
