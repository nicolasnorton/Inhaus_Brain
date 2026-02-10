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
