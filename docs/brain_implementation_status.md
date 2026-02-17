# Inhaus Brain Implementation Status

This document details how the Agentic Architecture was realized in the Inhaus Brain codebase and identifies what remains to be done.

## 1. Workspace Pattern (Phase 1)
**Goal:** Move identity/memory from static assets to a Firestore-driven workspace.

### Implemented
- **Schema:** Adopted `/workspaces/{userId}/` structure in Firestore.
- **Dart Service:** `WorkspaceService` (lib/features/workspace/services/workspace_service.dart) handles CRUD for identity, soul, and user profiles.
- **Python Builder:** `WorkspaceContextBuilder` (functions-python/workspace_context_builder.py) assembles system prompts dynamically from Firestore docs.
- **Initialization:** `workspaceInitProvider` (lib/main.dart) ensures a default workspace exists on app launch.

### ⚠️ Missing / Next Steps
- **UI Editor:** No interface in the app to edit `identity` or `soul` documents yet. Currently, they must be edited in the Firestore console or via future admin tools.

## 2. Dynamic Router & Registry (Phase 2)
**Goal:** Replace hardcoded router logic with a dynamic registry.

### Implemented
- **Registry Service:** `AgentRegistryService` (lib/features/workspace/services/agent_registry_service.dart) replaces `RouterIntent` enum.
- **Seeding:** The service automatically seeds the registry from `assets/prompts/*.md` on first run.
- **Dynamic Router:** `DynamicRouter` class (functions-python/dynamic_router.py) builds the routing prompt from Firestore data.
- **Lazy Loading:** `AgentRegistryService.getAgentPrompt(name)` fetches full prompt content only when needed.

### ⚠️ Missing / Next Steps
- **Data Migration:** The seeding logic assumes `assets/prompts/{name}.md` exists for every agent. If filenames don't match registry names exactly, those prompts won't load. A manual audit of `assets/prompts/` vs. registry entries is recommended.

## 3. Unified Memory System (Phase 3)
**Goal:** Persistent memory across sessions.

### Implemented
- **Service:** `MemoryFirestoreService` (lib/features/chat/services/memory_firestore_service.dart) handles long-term memory and daily notes.
- **Tools:** Python functions `update_memory`, `log_activity`, `read_memory` allow the agent to self-manage memory.
- **Browser Verification:** Confirmed that the agent can remember facts ("My name is BetaTester") and retrieve them.

### ⚠️ Missing / Next Steps
- **Vector Search:** Currently uses keyword/recent-notes retrieval. Future enhancement could add semantic search over memory.

## 4. Runtime Skills (Phase 4)
**Goal:** Extensible skills via Firestore.

### Implemented
- **Service:** `SkillsFirestoreService` (lib/features/workspace/services/skills_firestore_service.dart) for CRUD operations on skills.
- **Tools:** Python functions `create_skill` and `read_skill` enable runtime skill creation and execution.
- **Schema:** Adopted the `SKILL.md` frontmatter + body pattern in Firestore documents.

### ⚠️ Missing / Next Steps
- **Meta-Skill:** The "Skill Creator" meta-skill (teaching the agent *how* to use `create_skill` effectively) is implemented as a tool but needs a system prompt instruction to be fully autonomous.

## 5. Heartbeat / Proactive Tasks (Phase 5)
**Goal:** Periodic background tasks.

### Implemented
- **Runner:** `HeartbeatRunner` (functions-python/heartbeat_runner.py) checks a `HEARTBEAT.md` document for tasks.
- **Endpoint:** `run_heartbeat_endpoint` Cloud Function exposes this logic.
- **Documentation:** `docs/heartbeat-scheduler-setup.md` provides keys to automation.

### ⚠️ Missing / Next Steps
- **Automation:** The Cloud Scheduler job must be manually created using the provided `gcloud` command. It is not automated in the deploy script to avoid unexpected costs.

## 6. Session Summarization (Phase 6)
**Goal:** Manage context window limits.

### Implemented
- **Summarizer:** `SessionSummarizer` (functions-python/session_summarizer.py) compresses history when it exceeds the token threshold.
- **Integration:** Hooked into `generate_content` in `main.py` so it happens automatically on the backend.

## Summary

| Feature | Implemented? | Notes |
| :--- | :---: | :--- |
| **Workspace Schema** | ✅ | Fully operational backend-to-frontend |
| **Dynamic Router** | ✅ | Replaced hardcoded enums |
| **Memory System** | ✅ | Persistent & Verified |
| **Runtime Skills** | ✅ | Tooling exists; Agent instruction pending |
| **Heartbeat** | ✅ | Endpoint ready; Scheduler manual |
| **Summarization** | ✅ | Automatic on backend |

The core Agentic architecture is now the **engine** of Inhaus Brain. The remaining work is primarily **content** (migrating prompt text) and **UI** (building administrative views for these new Firestore collections).
