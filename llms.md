# Project Context: Inhaus Brain

## Overview
**Inhaus Brain** is an agentic workflow management application for a marketing agency. It coordinates tasks between human agents (Account Managers, Designers) and AI agents (Gemini, Vertex AI). The app automates the marketing lifecycle from research to publishing.

## Tech Stack
- **Frontend**: Flutter (Mobile + Web)
- **State Management**: Riverpod (Code Generation `flutter_riverpod` / `riverpod_annotation` preferred)
- **Routing**: GoRouter
- **Backend**: Firebase (Auth, Firestore, Storage) + Cloud Functions
- **AI Architecture**: Hybrid Edge-Cloud.
  - **Edge**: Chrome Built-in AI (Javascript Interop) for fast, free drafting.
  - **Cloud**: Google Vertex AI (Gemini Pro/Flash - via BYO-Key Vault) for high-fidelity outputs.
  - **Tools**: Model Context Protocol (MCP) standards (`AgentTool` abstract class).
- **Styling**: Custom "Premium" Dark Theme (Glassmorphism, Google Fonts 'Outfit')

## Key Directories
- `lib/core/mcp`: Agent Tool definitions and standardize interfaces.
- `lib/core/services`: `EdgeAIService` (Hybrid Engine), `AuthService`, `SecretVaultService`.
- `lib/features/chat`: The core Agentic Workbench (Notifier, UI).
- `lib/features/knowledge`: Context Board and Source management.
- `lib/features/creative`: Creative Studio, design concepts, and moodboards.

## Coding Conventions
- **Files**: Snake case (e.g., `campaign_list_screen.dart`).
- **Widgets**: PascalCase.
- **State**: Use `ConsumerWidget` or `ConsumerStatefulWidget` for Riverpod.
- **Async**: Use `FutureBuilder` or Riverpod's `AsyncValue` for data fetching.
- **UI**: Prioritize "WOW" factor — animations, gradients, glassmorphism.

## Agents & Roles
The system is built on a "Multi-Agent" architecture:
- **ResearchAgent**: Uses `WebSearchTool` (MCP) and Knowledge Context to analyze trends.
- **CreativeAgent**: Generates visual prompts, copy, and moodboards. Triggered via A2A handoff.
- **OrchestratorAgent** (Planned): Audits and approves agent outputs.
- **CopywritingAgent** (Planned): Specialized content generation.
- **DeveloperAgent** (Planned): Gen UI and widget code generation.
