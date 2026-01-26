# AI Development Rules: Inhaus Brain

This document defines the constraints and standards for **Antigravity** and **Jules** when contributing to this repository.

## 1. Core Mission & Context
- **Project**: Inhaus_Brain — A modular, agentic AI orchestration system built with Flutter.
- **Architecture**: Follows a strict separation between Orchestration Logic (`lib/features/chat/agents`) and Persona Definitions (`assets/prompts`).
- **Primary Directive**: Never modify the "Personality" of an agent (the `.md` files) and its "Logic" (the `.dart` files) in the same PR unless explicitly requested.

## 2. Technical Stack & Standards
- **Language**: Dart (Ensure `extra_pedantic` linting rules are followed).
- **Framework**: Flutter (Targeting Desktop/Web).
- **State Management**: Riverpod (Preferred for Agent dependency injection).
- **Testing**: Every new agent tool or utility must have a corresponding test in the `test/` directory. Use `flutter test` to verify.

## 3. Agent-Specific Constraints
Since this is an agentic system, builder agents (Jules/Antigravity) must respect the existing hierarchy:

### Component Rule for Builder Agents
- **Router Agent**: **PROTECTED**. Do not modify `router_agent.dart` unless the user provides a new routing logic diagram.
- **Persona Prompts**: Use Markdown headers. Do not include code snippets inside `.md` prompts unless they are "Example Outputs" for the AI.
- **Tooling**: New capabilities must be added as discrete "Tools" in `lib/core/tools` rather than bloating the Agent classes.

## 4. Workflow Rules for Jules
- **Branching**: Always create a feature branch (e.g., `jules/fix-issue-12`). Never push directly to `main`.
- **Scope**: Focus on one issue at a time. If Jules notices a second bug while fixing the first, it should mention it in the PR description rather than fixing it blindly.
- **Dependencies**: If adding a new `pubspec.yaml` package, provide a justification in the PR.

## 5. Workflow Rules for Antigravity
- **Validation**: Before marking a task as "Complete," use the Agentic Browser to verify that the UI still renders the Chat Interface correctly.
- **Documentation**: If an internal API or Agent function is changed, Antigravity must update the corresponding entry in `agents.md`.

## 6. Prohibited Actions
- **DO NOT** delete comments in `assets/prompts` as they are used for versioning persona iterations.
- **DO NOT** bypass the Router Agent to hardcode direct agent-to-agent communication. Everything must go through the "Brain" center.
- **DO NOT** use print() statements for debugging. Use `developer.log()` or the internal Logger utility.

> **Note to AI Builders**: If you are unsure about a specific architectural decision, pause and request a "System Architect Review" in the chat log.
