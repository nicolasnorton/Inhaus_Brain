# Phase 5: Stitch MCP Integration – Implementation Plan

> **Project**: Inhaus Brain  
> **Current Branch**: `gemini-gemma-vertex-overhaul-staging-2026`  
> **New Feature Branch**: `feature/stitch-mcp-integration-2026`  
> **Date**: 2026-02-12  
> **Target**: Staging only (`inhausbrain-beta.web.app`)  
> **Status**: 🟡 PLANNING → Awaiting Approval

---

## 1. Executive Summary

Integrate Google Stitch (Labs/experimental AI design tool) via its official MCP (Model Context Protocol) server into Inhaus Brain. This enables Brian and agents to generate UI designs, campaign screens, app flows, and production-ready code (HTML/React) directly from conversation prompts, with full Blackboard persistence and GenUI rendering.

### Key Outcomes
- Users link Stitch accounts via Google Cloud ADC or API key
- Brian can trigger `generate_screen_from_text`, `create_project`, `get_screen_code`, and more
- Stitch outputs (design previews, code exports) render as GenUI components
- Iteration loops: refine designs through follow-up prompts
- Campaign context flows from Blackboard → Stitch prompt → Stitch output → Blackboard

---

## 2. Current Branch Confirmation

```
✅ Current Branch: gemini-gemma-vertex-overhaul-staging-2026
✅ Phases 1-4 Complete: Gemini 2.5 + Gemma, agent tiering, model strategies,
   semantic cache, telemetry, session-aware Blackboard persistence
```

---

## 3. Branch Strategy

### Git Commands (Exact)
```bash
# 1. Ensure we're on the correct base branch and up to date
cd /Users/nicolasnorton/AudioTherapy/audio_therapy_app/InhausBrain
git checkout gemini-gemma-vertex-overhaul-staging-2026
git pull origin gemini-gemma-vertex-overhaul-staging-2026

# 2. Create the feature branch
git checkout -b feature/stitch-mcp-integration-2026

# 3. Push empty branch to remote for tracking
git push -u origin feature/stitch-mcp-integration-2026
```

### Commit Convention
All commits prefixed with `[stitch-mcp]`:
```
[stitch-mcp] Add feature flag for Stitch integration
[stitch-mcp] Add Stitch proxy Cloud Function
[stitch-mcp] Add StitchService and agent tools
[stitch-mcp] Add stitch_design_preview GenUI component
[stitch-mcp] Add Blackboard Stitch state persistence
[stitch-mcp] Add telemetry for Stitch operations
```

---

## 4. Stitch MCP Research Summary

### 4.1 Stitch Platform Overview
Google Stitch is an AI-powered UI/UX design tool from Google Labs that converts text prompts into comprehensive UI designs and production-ready code. It uses Gemini models (2.5 Pro/Flash, Gemini 3) to generate mobile and web app interfaces.

### 4.2 MCP Tools Available (via `@_davideast/stitch-mcp`)

| Tool | Description | Input | Output |
|------|-------------|-------|--------|
| `create_project` | Create new workspace/project folder | `{ name, description }` | Project metadata |
| `list_projects` | List all Stitch projects | `{}` | Project list |
| `get_project` | Get project details | `{ projectId }` | Project metadata |
| `generate_screen_from_text` | Generate UI screen from text prompt | `{ projectId, prompt, model? }` | Screen metadata |
| `list_screens` | List screens in a project | `{ projectId }` | Screen list |
| `get_screen` | Get screen metadata | `{ projectId, screenId }` | Screen details |
| `get_screen_code` / `fetch_screen_code` | Retrieve generated HTML/frontend code | `{ projectId, screenId }` | HTML/React code |
| `get_screen_image` / `fetch_screen_image` | Get screen screenshot (base64) | `{ projectId, screenId }` | Base64 image |
| `extract_design_context` | Extract "Design DNA" (fonts, colors, layout) | `{ projectId, screenId }` | Design tokens |
| `build_site` | Construct website by mapping screens to routes | `{ projectId, routes }` | Site bundle |

### 4.3 Authentication Methods

| Method | Mechanism | Best For |
|--------|-----------|----------|
| **Application Default Credentials (ADC)** | `gcloud auth application-default login` + GCP Project + IAM | Server-side / Cloud Functions ✅ |
| **API Key** | Generated from Stitch settings | Quick setup / Personal use |

**Our approach**: Backend proxy (Cloud Function) using ADC. No client-side credentials.

### 4.4 Key Architecture Decision: Backend Proxy Pattern

The Stitch MCP protocol communicates via JSON-RPC over HTTP. We will **NOT** expose the MCP server directly to the Flutter client. Instead:

1. Flutter client → Cloud Function proxy (authenticated via Firebase Auth ID Token)
2. Cloud Function → Stitch MCP server (authenticated via GCP ADC / service account)
3. Responses cached and stored → returned to client

This is consistent with the existing `proxyVertexAI` pattern in `functions/index.js`.

---

## 5. Architecture Diagram

```mermaid
graph TB
    subgraph "Flutter Client (Web/Mobile)"
        A[Brian Chat / Agent UI] --> B[StitchService<br/>lib/core/services/stitch_service.dart]
        B --> C[AIProxyService<br/>HTTP calls]
        B --> D[SemanticCacheService]
        B --> E[TelemetryService]
        F[StitchDesignPreview Widget<br/>GenUI Component] --> G[CanvasHost]
        H[StitchCodeViewer Widget<br/>GenUI Component] --> G
        I[StitchProjectBrowser Widget<br/>GenUI Component] --> G
    end

    subgraph "Tool Registry"
        J[StitchCreateProjectTool] --> B
        K[StitchGenerateScreenTool] --> B
        L[StitchGetScreenCodeTool] --> B
        M[StitchListProjectsTool] --> B
        N[StitchGetDesignContextTool] --> B
    end

    subgraph "Cloud Functions (Backend Proxy)"
        C --> O[proxyStitch<br/>functions/stitch-proxy.js]
        O --> P{Auth Check<br/>Firebase Token}
        P -->|Valid| Q[ADC / SA Token]
        Q --> R[Stitch MCP Server<br/>stitch.googleapis.com]
        P -->|Invalid| S[401 Unauthorized]
    end

    subgraph "Stitch MCP Server (Google)"
        R --> T[create_project]
        R --> U[generate_screen_from_text]
        R --> V[get_screen_code]
        R --> W[get_screen_image]
        R --> X[extract_design_context]
        R --> Y[build_site]
    end

    subgraph "Persistence Layer"
        B --> Z[BlackboardNotifier<br/>postFact('stitch_*')]
        Z --> AA[BlackboardPersistenceService<br/>Firestore sessions]
        B --> BB[Knowledge Module<br/>Stitch outputs → chunks/embeddings]
    end

    subgraph "Config & Gates"
        CC[FeatureFlags.enableStitch] --> B
        CC --> O
        DD[AppConfig.isStaging] --> CC
    end
```

---

## 6. Sub-Phase Breakdown

### Sub-Phase 5.1: Feature Flags & Configuration
**Effort**: S (2hrs) | **Risk**: Low | **Dependencies**: None

- Add `enableStitch` to `AppConfig` (staging-only default)
- Add `enableStitch` to `FeatureFlags` (Firestore override support)
- Add Stitch-related entries to `ModelRegistry` (not a model, but config namespace)

**Files Modified**:
- `lib/core/config/app_environment.dart`
- `lib/core/config/feature_flags.dart`

---

### Sub-Phase 5.2: Cloud Function Proxy (`proxyStitch`)
**Effort**: M (4-6hrs) | **Risk**: Medium | **Dependencies**: 5.1

Create a new Cloud Function `proxyStitch` in `functions/index.js` (or a separate `functions/stitch-proxy.js` module) that:

1. Validates Firebase Auth ID Token (same pattern as `proxyVertexAI`)
2. Authenticates to Stitch API via GCP ADC / service account
3. Forwards JSON-RPC calls to the Stitch MCP server
4. Handles rate limiting, retries, and error wrapping
5. Caches screen images in Firebase Storage (to avoid re-fetching)

**Key Endpoints Proxied**:
- `POST /stitch/create-project`
- `POST /stitch/generate-screen`
- `GET /stitch/screen-code/:projectId/:screenId`
- `GET /stitch/screen-image/:projectId/:screenId`
- `GET /stitch/projects`
- `POST /stitch/extract-design-context`
- `POST /stitch/build-site`

**Files Created**:
- `functions/stitch-proxy.js` (module)

**Files Modified**:
- `functions/index.js` (export new function)
- `functions/package.json` (if new deps needed)

**Security**:
- All requests require valid Firebase Auth ID Token
- Stitch credentials stored in Cloud Secret Manager, never exposed to client
- Rate limiting: max 20 Stitch calls per user per hour (configurable)

---

### Sub-Phase 5.3: Dart StitchService
**Effort**: M (4-6hrs) | **Risk**: Medium | **Dependencies**: 5.1, 5.2

Create `StitchService` that wraps HTTP calls to the `proxyStitch` Cloud Function and integrates with existing services:

```dart
class StitchService {
  // Project Management
  Future<StitchProject> createProject({required String name, String? description});
  Future<List<StitchProject>> listProjects();
  Future<StitchProject> getProject(String projectId);
  
  // Screen Generation
  Future<StitchScreen> generateScreen({
    required String projectId,
    required String prompt,
    String? model,  // gemini-3-pro, gemini-3-flash
  });
  Future<List<StitchScreen>> listScreens(String projectId);
  Future<StitchScreen> getScreen(String projectId, String screenId);
  
  // Code & Assets
  Future<String> getScreenCode(String projectId, String screenId);
  Future<Uint8List> getScreenImage(String projectId, String screenId);
  
  // Design Intelligence
  Future<DesignContext> extractDesignContext(String projectId, String screenId);
  
  // Site Building
  Future<SiteBuild> buildSite(String projectId, Map<String, String> routes);
}
```

**Integration Points**:
- Uses `AIProxyService` pattern for HTTP calls (Firebase Auth token injection)
- Checks `FeatureFlags.enableStitch` before every call
- Logs every operation via `TelemetryService.logStitchGeneration()`
- Caches repeated lookups via `SemanticCacheService`
- Posts results to Blackboard via `BlackboardNotifier.postFact('stitch_*', ...)`

**Files Created**:
- `lib/core/services/stitch_service.dart`
- `lib/core/models/stitch_models.dart` (StitchProject, StitchScreen, DesignContext, SiteBuild)

---

### Sub-Phase 5.4: Agent Tool Integration
**Effort**: M (4-6hrs) | **Risk**: Low | **Dependencies**: 5.3

Create new `AgentTool` subclasses for Stitch operations, following the existing pattern (`ImageGenerationTool`, `VideoGenerationTool`):

| Tool Class | AgentTool Name | Description |
|------------|----------------|-------------|
| `StitchCreateProjectTool` | `stitch_create_project` | Create a new Stitch project |
| `StitchGenerateScreenTool` | `stitch_generate_screen` | Generate UI screen from text |
| `StitchGetScreenCodeTool` | `stitch_get_screen_code` | Retrieve generated HTML/React code |
| `StitchGetDesignContextTool` | `stitch_extract_design` | Extract Design DNA from a screen |
| `StitchListProjectsTool` | `stitch_list_projects` | Show user's Stitch projects |
| `StitchBuildSiteTool` | `stitch_build_site` | Build a multi-page site from screens |

**Prompt Refinement** (via Gemma/Gemini):
Before sending a user's raw prompt to Stitch, use Gemma (fast tier) to:
1. Enrich the prompt with UI keywords (spacing, typography, color scheme)
2. Inject campaign context from Blackboard facts
3. Translate to English if needed (Stitch works best in English)

**Files Created**:
- `lib/core/mcp/tools/stitch_tools.dart` (all 6 tools in one file)

**Files Modified**:
- `lib/features/assistant/services/assistant_tool_registry.dart` (register tools)
- `lib/core/tools/gen_ui_tools.dart` (add `stitch_design_preview` to enum)

---

### Sub-Phase 5.5: GenUI Enhancement – Design Components
**Effort**: L (6-8hrs) | **Risk**: Medium | **Dependencies**: 5.3, 5.4

Create three new GenUI components for Stitch outputs:

#### 5.5.1 `StitchDesignPreview` Widget
- Displays the generated screen image (base64 or cached URL)
- "View Code" button to toggle code view
- "Refine" button to open follow-up prompt input
- "Export" dropdown (HTML, React, Flutter)
- Metadata: model used, generation time, prompt

#### 5.5.2 `StitchDesignCarousel` Widget
- Carousel of multiple generated screens (for multi-screen projects)
- Swipe/arrow navigation
- Selected screen details panel
- "Add Screen" floating action button

#### 5.5.3 `StitchCodeExportViewer` Widget
- Enhanced code viewer (extends existing `code_viewer_widget.dart`)
- Syntax highlighting for HTML/React/CSS
- Copy to clipboard
- Download as file
- "Apply to Blackboard" action

**Files Created**:
- `lib/features/assistant/presentation/widgets/gen_ui/stitch_design_preview_widget.dart`
- `lib/features/assistant/presentation/widgets/gen_ui/stitch_design_carousel_widget.dart`
- `lib/features/assistant/presentation/widgets/gen_ui/stitch_code_export_widget.dart`

**Files Modified**:
- `lib/core/tools/gen_ui_tools.dart` (add component types to enum)
- GenUI factory/router (if exists) to register new components

---

### Sub-Phase 5.6: Blackboard & Knowledge Persistence
**Effort**: M (3-4hrs) | **Risk**: Low | **Dependencies**: 5.3, 5.5

Persist Stitch outputs across sessions:

1. **Blackboard Facts** (ephemeral session state):
   - `stitch_active_project` → Current project ID and name
   - `stitch_last_screen` → Last generated screen metadata
   - `stitch_design_context` → Extracted Design DNA
   - `stitch_campaign_context` → Campaign brief injected into Stitch

2. **Knowledge Module** (long-term persistence):
   - Store Stitch design outputs as `KnowledgeSource` chunks
   - Generate embeddings for design descriptions (for future RAG retrieval)
   - Tag with `source: 'stitch'` and `campaign_id`

3. **Firebase Storage** (binary assets):
   - Cache screen images in `users/{uid}/stitch/{projectId}/{screenId}.png`
   - Cache exported code in `users/{uid}/stitch/{projectId}/{screenId}.html`

**Files Modified**:
- `lib/core/services/stitch_service.dart` (add persistence hooks)
- Potentially `lib/features/knowledge/services/` (if chunking Stitch outputs)

---

### Sub-Phase 5.7: Telemetry & Observability
**Effort**: S (2-3hrs) | **Risk**: Low | **Dependencies**: 5.3

Add Stitch-specific telemetry events:

```dart
// In TelemetryService:
Future<void> logStitchGeneration({
  required String toolName,        // e.g., 'generate_screen_from_text'
  required double latencyMs,
  required bool success,
  String? projectId,
  String? screenId,
  String? model,                   // Stitch's internal model
  bool isCacheHit = false,
  String? errorReason,
});
```

**Firebase Analytics Events**:
- `stitch_generation` — screen generation attempts
- `stitch_code_export` — code export actions
- `stitch_project_created` — new project creations
- `stitch_design_refined` — iteration/refinement actions
- `stitch_error` — failure tracking

**Files Modified**:
- `lib/core/services/telemetry_service.dart`

---

### Sub-Phase 5.8: Error Handling & Graceful Degradation
**Effort**: S (2hrs) | **Risk**: Low | **Dependencies**: 5.2, 5.3

Since Stitch is experimental (Labs), implement robust fallbacks:

1. **Feature flag guard**: All Stitch tools check `FeatureFlags.enableStitch`
2. **Rate limit awareness**: Track calls per hour, warn at 80% capacity
3. **Timeout handling**: 30s timeout for generation, 15s for retrieval
4. **Fallback messages**: If Stitch is unavailable:
   ```
   "Stitch design generation is temporarily unavailable. 
    Your prompt has been saved and will be retried. 
    In the meantime, I can help create a design brief for manual Stitch use."
   ```
5. **Retry logic**: Exponential backoff (1s, 2s, 4s) with max 3 retries
6. **Circuit breaker**: After 5 consecutive failures, disable Stitch for 5 minutes

---

### Sub-Phase 5.9: Testing & Validation
**Effort**: M (4hrs) | **Risk**: Low | **Dependencies**: 5.1-5.8

1. **Unit Tests**:
   - `StitchService` mock tests (HTTP responses)
   - `StitchTools` execute() with mocked service
   - Feature flag gating tests

2. **Integration Tests**:
   - Cloud Function proxy → mock Stitch server
   - End-to-end tool execution → GenUI rendering

3. **Manual Test Scenarios**:
   - Brian prompt: *"Genera una landing page para campaña de turismo en Ecuador usando Stitch"*
   - Verify: Design appears in GenUI → Blackboard persists → Reload → Design still visible
   - Brian prompt: *"Show me the code for the last Stitch design"*
   - Verify: Code viewer component renders with HTML/React
   - Brian prompt: *"Refine the design: make the header bolder and add a hero image"*
   - Verify: New screen generated, carousel updates

---

## 7. Backlog Table

| # | Task | Sub-Phase | Effort | Priority | Dependencies | Risk | Status |
|---|------|-----------|--------|----------|--------------|------|--------|
| 1 | Feature flags (`enableStitch`) | 5.1 | S (2h) | P0 | None | Low | ⬜ |
| 2 | Cloud Function: `proxyStitch` | 5.2 | M (5h) | P0 | #1 | Med | ⬜ |
| 3 | Stitch data models (Dart) | 5.3 | S (1h) | P0 | None | Low | ⬜ |
| 4 | `StitchService` (Dart) | 5.3 | M (5h) | P0 | #1, #2, #3 | Med | ⬜ |
| 5 | Agent tools (6 tools) | 5.4 | M (4h) | P0 | #4 | Low | ⬜ |
| 6 | Tool registry registration | 5.4 | S (1h) | P0 | #5 | Low | ⬜ |
| 7 | Prompt refinement (Gemma) | 5.4 | S (2h) | P1 | #5 | Low | ⬜ |
| 8 | GenUI: StitchDesignPreview | 5.5 | M (3h) | P0 | #4 | Med | ⬜ |
| 9 | GenUI: StitchDesignCarousel | 5.5 | M (3h) | P1 | #8 | Med | ⬜ |
| 10 | GenUI: StitchCodeExport | 5.5 | S (2h) | P1 | #8 | Low | ⬜ |
| 11 | GenUI tool schema update | 5.5 | S (1h) | P0 | #8 | Low | ⬜ |
| 12 | Blackboard fact posting | 5.6 | S (2h) | P0 | #4 | Low | ⬜ |
| 13 | Knowledge module chunks | 5.6 | M (3h) | P2 | #4 | Med | ⬜ |
| 14 | Firebase Storage caching | 5.6 | S (2h) | P1 | #4 | Low | ⬜ |
| 15 | Telemetry events | 5.7 | S (2h) | P0 | #4 | Low | ⬜ |
| 16 | Error handling / fallbacks | 5.8 | S (2h) | P0 | #2, #4 | Low | ⬜ |
| 17 | Unit tests | 5.9 | M (3h) | P1 | #4, #5 | Low | ⬜ |
| 18 | Integration tests | 5.9 | M (3h) | P1 | All | Med | ⬜ |
| 19 | Manual QA / staging deploy | 5.9 | S (2h) | P0 | All | Low | ⬜ |

**Total Estimated Effort**: ~48-55 hours  
**Critical Path**: #1 → #2 → #3/#4 → #5 → #8 → #11 → #19

---

## 8. Security Model

### 8.1 Token Flow
```
User Login (Firebase Auth)
  → Flutter gets Firebase ID Token
  → Flutter sends to proxyStitch Cloud Function
  → Cloud Function verifies ID Token
  → Cloud Function uses ADC/Service Account to authenticate with Stitch API
  → Response returned to Flutter (no Stitch credentials exposed)
```

### 8.2 Credential Storage
| Secret | Storage Location | Access |
|--------|-----------------|--------|
| GCP Service Account Key | Cloud Secret Manager | Cloud Functions only |
| Stitch API Key (if needed) | Cloud Secret Manager | Cloud Functions only |
| Firebase Auth ID Token | Client-side (short-lived) | Per-request |
| User's Stitch Project IDs | Firestore `users/{uid}/stitch_config` | User-scoped |

### 8.3 Rate Limiting
- **Per-user**: 20 generation calls/hour, 100 read calls/hour
- **Global**: 200 generation calls/hour (across all users)
- Tracked in Firestore `rate_limits/{uid}/stitch`
- Enforced in Cloud Function before forwarding to Stitch

### 8.4 Data Privacy
- Stitch outputs cached in user-scoped Firebase Storage paths
- No cross-user data leakage (all queries scoped by `uid`)
- Screen images marked as private (no public URLs without signed tokens)

---

## 9. Cost Control

| Strategy | Implementation | Expected Savings |
|----------|---------------|-----------------|
| Semantic Cache | Hash prompt + config → lookup before Stitch call | 30-50% reduction |
| Image Caching | Store screen images in Firebase Storage | Avoid re-fetching |
| Code Caching | Store generated code in Firestore | Avoid re-generation |
| Prompt Dedup | Normalize prompts (lowercase, trim, remove filler) before hashing | 10-20% additional cache hits |
| Rate Limits | Cap per-user generation calls | Prevent abuse |

---

## 10. Deployment Plan

### Step 1: Deploy Cloud Function
```bash
cd /Users/nicolasnorton/AudioTherapy/audio_therapy_app/InhausBrain/functions
npm install
firebase deploy --only functions:proxyStitch --project inhausbrain
```

### Step 2: Set Stitch API Configuration
```bash
# Enable Stitch API in GCP
gcloud services enable stitch.googleapis.com --project=inhausbrain

# Set Stitch config in Firestore (staging only)
# Document: staging_config/feature_flags
# Field: enableStitch = true
```

### Step 3: Deploy Flutter Web to Staging
Use existing `/deploy_staging` workflow.

### Step 4: Verify
1. Navigate to `inhausbrain-beta.web.app`
2. Sign in
3. Open Brian chat
4. Test prompt: "Genera una landing page para campaña de turismo en Ecuador usando Stitch"
5. Verify design preview appears in GenUI
6. Verify Blackboard facts persist across page reload

---

## 11. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Stitch API changes (experimental) | High | High | Version pin, graceful degradation, fallback messages |
| Stitch API rate limits hit | Medium | Medium | Semantic cache, per-user limits, backoff |
| ADC auth issues in Cloud Functions | Low | High | Test early, fallback to API key auth |
| Large screen images impact performance | Medium | Medium | Compress/resize before caching, lazy load |
| CORS issues with Stitch endpoints | Low | Low | Fully proxied through Cloud Functions |
| Stitch unavailable/deprecated | Medium | High | Feature flag kill switch, no hard dependencies |

---

## 12. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Stitch generation success rate | > 90% | Telemetry (`stitch_generation` events) |
| Average generation latency | < 15s | Telemetry (P50/P95) |
| Cache hit rate | > 30% | Semantic cache logs |
| User engagement (Stitch tools) | > 5 uses/week/user | Firebase Analytics |
| Error rate | < 5% | Error telemetry |
| Feature flag adoption | 100% staging users | FeatureFlags doc |

---

## 13. Files to Create (Full List)

### New Files
| File | Description |
|------|-------------|
| `functions/stitch-proxy.js` | Cloud Function proxy for Stitch MCP |
| `lib/core/services/stitch_service.dart` | Dart service wrapping Stitch proxy calls |
| `lib/core/models/stitch_models.dart` | Data models (StitchProject, StitchScreen, etc.) |
| `lib/core/mcp/tools/stitch_tools.dart` | 6 AgentTool subclasses for Stitch operations |
| `lib/features/assistant/presentation/widgets/gen_ui/stitch_design_preview_widget.dart` | GenUI: Design preview |
| `lib/features/assistant/presentation/widgets/gen_ui/stitch_design_carousel_widget.dart` | GenUI: Multi-screen carousel |
| `lib/features/assistant/presentation/widgets/gen_ui/stitch_code_export_widget.dart` | GenUI: Code export viewer |
| `test/core/stitch_service_test.dart` | Unit tests for StitchService |
| `test/core/stitch_tools_test.dart` | Unit tests for Stitch tools |

### Modified Files
| File | Change |
|------|--------|
| `lib/core/config/app_environment.dart` | Add `enableStitch` flag |
| `lib/core/config/feature_flags.dart` | Add `enableStitch` accessor |
| `lib/features/assistant/services/assistant_tool_registry.dart` | Register Stitch tools |
| `lib/core/tools/gen_ui_tools.dart` | Add stitch component types to enum |
| `lib/core/services/telemetry_service.dart` | Add `logStitchGeneration()` |
| `functions/index.js` | Export `proxyStitch` |
| `functions/package.json` | Add any new dependencies |

---

## 14. Execution Sequence (After Approval)

```
Phase 5.1  Feature Flags ──────────────────► COMMIT
     │
Phase 5.2  Cloud Function Proxy ───────────► COMMIT + DEPLOY FUNCTION
     │
Phase 5.3  Data Models + StitchService ────► COMMIT
     │
Phase 5.4  Agent Tools + Registry ─────────► COMMIT
     │
Phase 5.5  GenUI Components ───────────────► COMMIT
     │
Phase 5.6  Blackboard + Knowledge ─────────► COMMIT
     │
Phase 5.7  Telemetry ─────────────────────► COMMIT
     │
Phase 5.8  Error Handling ─────────────────► COMMIT
     │
Phase 5.9  Tests + Manual QA ─────────────► COMMIT
     │
     └──► DEPLOY TO STAGING (/deploy_staging)
          └──► MANUAL VERIFICATION
               └──► PR for review
```

---

## 15. Test Prompts for Brian (Post-Deploy)

### Spanish (Primary use case)
1. *"Genera una landing page para una campaña de turismo en Ecuador usando Stitch"*
2. *"Crea un diseño de app móvil para gestión de citas médicas"*
3. *"Muéstrame el código HTML del último diseño de Stitch"*
4. *"Refina el diseño: hazlo más moderno con colores oscuros y tipografía Inter"*
5. *"Lista todos mis proyectos de Stitch"*

### English
1. *"Use Stitch to design a marketing dashboard for social media analytics"*
2. *"Generate a mobile checkout flow for an e-commerce app"*
3. *"Extract the design DNA from my last Stitch screen"*
4. *"Build a 3-page website from my Stitch project screens"*

---

## ✅ Approval Checkpoint

**Before proceeding to the Execution Phase, please confirm:**

- [ ] Architecture approach approved (backend proxy pattern)
- [ ] Sub-phase breakdown acceptable
- [ ] Security model reviewed
- [ ] Feature flag strategy approved (staging-only via `enableStitch`)
- [ ] Branch strategy accepted (`feature/stitch-mcp-integration-2026`)
- [ ] Ready to create the feature branch and begin implementation

**Awaiting your approval to proceed. 🚀**
