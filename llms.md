# Project Context: Inhaus Brain

## Overview
**Inhaus Brain** is an agentic workflow management application for a marketing agency. It coordinates tasks between human agents (Account Managers, Designers) and AI agents (Gemini, Vertex AI). The app automates the marketing lifecycle from research to publishing.

## Tech Stack
- **Frontend**: Flutter (Mobile + Web)
- **State Management**: Riverpod (Code Generation `flutter_riverpod` / `riverpod_annotation` preferred)
- **Routing**: GoRouter
- **Backend**: Firebase (Auth, Firestore, Storage) + Cloud Functions
- **AI Integration**: Google Vertex AI (Gemini Pro/Flash, Imagen, Veo)
- **Styling**: Custom "Premium" Dark Theme (Glassmorphism, Google Fonts 'Outfit')

## Key Directories
- `lib/core`: Shared utilities, theme, router.
- `lib/features`: Feature-based architecture (e.g., `dashboard`, `campaigns`, `auth`).
- `functions`: Firebase Cloud Functions (Node.js/Python).

## Coding Conventions
- **Files**: Snake case (e.g., `campaign_list_screen.dart`).
- **Widgets**: PascalCase.
- **State**: Use `ConsumerWidget` or `ConsumerStatefulWidget` for Riverpod.
- **Async**: Use `FutureBuilder` or Riverpod's `AsyncValue` for data fetching.
- **UI**: Prioritize "WOW" factor — animations, gradients, glassmorphism.

## Agents
The system uses "Agents" to perform tasks.
- **ResearchAgent**: Google Search/Trends.
- **CreativeAgent**: Image/Video generation.
- **AnalyticsAgent**: Performance monitoring.
