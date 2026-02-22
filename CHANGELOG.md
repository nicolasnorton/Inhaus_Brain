## [1.2.1+28] - 2026-02-21

### Fixed
- **Model Registry Alignment**: Corrected "futuristic" model IDs (`gemini-2.5-pro`, `gemini-3-pro-preview`) that caused `400 Bad Request` in Vertex AI. 
- **Tiered Mapping**: Mapped ModelTiers to real, stable Vertex AI IDs:
  - `pro` → `gemini-1.5-pro-002`
  - `flash` → `gemini-1.5-flash-002`
  - `frontier` → `gemini-2.0-pro-exp-02-05`
  - `research` → `gemini-2.0-flash-thinking-exp-1219`
- **Frontend/Backend Synchronization**: Updated both `ModelRegistry.dart` (Flutter) and `gemini_client.py` (Cloud Functions) for consistent routing.

## [1.2.1+27] - 2026-02-21

### Fixed
- **GenUI/A2UI Logic**: Resolved "UNEXPECTED_TOOL_CALL" error by enforcing strict Vertex AI schema compliance.
- **JSON Robustness**: Enhanced `JsonParserService` with robust fallback for Gemini's native `<tool_code>` artifacts.
- **Workflow Stabilization**: Improved agent reliability for Research and Strategy tasks with multi-modal output support.

## [1.2.1-clean-fix] - 2026-02-09

### Fixed
- **CopilotKit Stabilization**: Resolved `400 Bad Request` by aligning with v1.x protocol (missing `method` field).
- **Vertex AI Proxy Hardening**: Fixed ignored generation parameters for Imagen/Veo and improved error logging/regional fallbacks.
- **Project ID Detection**: Improved resilience in Cloud Functions for custom project environments.

## [1.1.8] - 2026-02-06

### Fixed
- **Major Routing Fix**: Resolved 404 error when navigating to individual proposals.
- **Navigation Resilience**: Added redirect aliases for legacy `/sales` and `/proposals` paths.
- **Back Button Navigation**: Fixed "Back" button in Proposal Detail screen to return to Sales Hub.


## [1.1.7] - 2026-02-05

### Added
- **ProposalsLM Module**: A standalone module for professional proposal generation.
- **Sales Hub Integration**: New "Proposals" tab in Sales Hub (Sales & CRM).
- **Agentic Workflow**: Retrieval → Outliner → Generator → PDF flow for proposals.
- **Proposal Detail Screen**: 3-column studio layout (Sources | Chat | Studio).

### Changed
- Refactored proposal logic out of the campaigns module.
- Updated UI to mirror ReportsLM design language.
- Improved PDF generation with INHAUS branding.

### Fixed
- Cache busting issues in web deployment.
- Compilation errors related to the migration.
- Redundant service instances.
