# Knowledge Module: Current State Report
**Date:** 2026-01-29
**Module:** `lib/features/knowledge`

## Executive Summary
The Knowledge Module is a centralized intelligence hub designed for autonomous ingestion, organization, and retrieval of multi-source data. It serves as the "brain" for AI agents, providing context-aware retrieval (RAG) through integrated Vertex AI and LlamaCloud services.

---

## 1. Directory Structure & Key Files
The module is organized according to the project's feature-first architecture:

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| `models/` | Data structures | `knowledge_source.dart`, `knowledge_api_models.dart`, `external_knowledge_models.dart` |
| `services/` | Logic & APIs | `knowledge_api_service.dart`, `knowledge_ingestion_service.dart`, `external_knowledge_service.dart` |
| `providers/` | State Management | `knowledge_provider.dart`, `external_knowledge_provider.dart` |
| `screens/` | Main Views | `knowledge_management_screen.dart`, `external_knowledge_screen.dart` |
| `widgets/` | UI Components | `knowledge_library_widget.dart` |

---

## 2. Core Agents
The module's intelligence is augmented by specialized agents:

### **Knowledge Librarian Agent**
*   **File:** `lib/features/chat/agents/knowledge_librarian_agent.dart`
*   **Role:** Monitors, updates, enriches, and organizes knowledge.
*   **Tasks:**
    *   Summarizing long documents.
    *   Identifying outdated/redundant info.
    *   Suggesting categorizations (Datasets).
    *   Cross-referencing related docs.

---

## 3. Connections & Integrations

### **Internal Module Connections**
*   **Clients/Projects**: The `KnowledgeIngestionService` automatically scrapes data from the Clients module (Client profiles, Project descriptions, Task statuses) to build client-specific intelligence.
*   **Copilot**: Processes screencaps and chat history into "Learnings" via the ingestion pipeline.
*   **Chat/Agents**: All agents (Creative, Research, Video) utilize the Knowledge Module for retrieval-augmented generation (RAG).

### **External Platform Integrations**
The `ConnectedAccounts` module defines a wide range of supported platforms:
*   **Google Stack**: Ads, Analytics, Search Console, Trends, Maps, Business Profile.
*   **Meta Stack**: Meta Ads, Facebook Organic, Instagram Organic.
*   **Video/Social**: TikTok (Ads/Organic), YouTube (Source ingestion), Pinterest.
*   **Other**: Twitter/X, Apple Search Ads.

### **Cloud & Data Connectors**
*   **Native Storage**: Firestore (Metadata) + Vertex AI (Vector Embeddings/Search).
*   **External RAG**: LlamaCloud integration for high-performance document parsing and retrieval.
*   **Source Types**: URL, Text, PDF, Google Drive, Image, Audio, YouTube.

---

## 4. Analytics & Insight Flow
Knowledge flows into the **Analytics Module** (`lib/features/analytics`):
*   **Orchestration**: `AnalyticsOrchestratorService` coordinates a multi-agent team:
    1.  **Performance Analyst**: Initial data processing.
    2.  **Data Scientist**: Deep insight extraction.
    3.  **Digital Strategist**: Actionable recommendations.
    4.  **Dashboard Agent**: Generates dynamic Gen-UI visualizations.

---

## 5. Current Implementation Details (Technical)
*   **Embedding Model**: `text-embedding-004` (Google).
*   **Vector Search**: Native Firestore with vector field support (fallback to Gemini API if Vertex OAuth is unavailable).
*   **Ingestion Logic**: Chunks are typically 500 characters; metadata includes word counts, token estimates, and keyword mapping.
