
# Inhaus Brain - Changelog

## [1.1.6] - 2026-02-05
### Added
- **Proposal Template System**: Comprehensive templating for PDF proposals
  - Support for one-pager and multi-page PDF layouts
  - Brian Premium Gold/Dark template as default
  - Template configuration for colors, typography, layout, and branding
  - Multiple pre-built templates (Brian, Classic, Minimal)
  - Template provider with state management
  - Templated PDF generator with dynamic styling
- **Cache Busting**: Enhanced cache control for forced updates
  - Service worker auto-unregistration
  - Cache API clearing on load
  - Version tracking in manifest and meta tags

### Fixed
- **PDF Generation**: Resolved `PdfColor.withOpacity()` compatibility issues
  - Added custom `_withOpacity()` helper function across all PDF generators
  - Fixed opacity handling in proposal_pdf_generator.dart
  - Fixed opacity handling in proposal_slides_generator.dart
  - Fixed opacity handling in templated_proposal_pdf_generator.dart
- **Build System**: Corrected import paths for ProposalData and ProposalSection classes

### Changed
- **ProposalService**: Updated to support optional template parameter in PDF generation
- **Version**: Bumped to 1.1.6+6


## [1.0.6] - 2026-02-04
### Added
- **Knowledge Module**: Full **Google Drive Integration** (browse, select, and import Docs/Sheets/PDFs).
- **Embeddings**: Implemented **automatic batching** for large documents (respecting Vertex AI limits).
- **Authentication**: Enhanced **token refresh** logic for seamless AI operations.

### Fixed
- **Vertex AI**: Resolved `400 INVALID_ARGUMENT` errors for documents over 250 chunks.
- **Security**: Hardened token provider to prioritize fresh Google OAuth credentials.
- **Stability**: Fixed Secret Vault crash related to dynamic environment keys.

## [1.0.5] - 2026-02-04

## [1.0.0] - 2026-01-28
### Added
- **Onboarding Experience**: New welcome screen and campaign setup wizard for first-time users.
- **Multimodal Quality Gates**: Confidence checks for Image (0.90) and UI (0.92) generation.
- **Telemetry**: Firebase Analytics integration for user feedback (Thumbs Up/Down).
- **Error Recovery**: Robust `ErrorHandlingService` with friendly messages and retry logic.
- **Context Compression**: Smart compression for long-running conversations to maintain agency.
- **Adversarial Hardening**: 20+ stress tests passed for regional safety and stability.

### Changed
- **Orchestrator**: Enhanced PII redaction and cultural filters for Ecuador/LatAm region.
- **UI**: Added progress indicators and quality feedback loops.
- **Core**: Replaced Gemini SDK with direct Firebase/Vertex AI secure proxy integration.

### Fixed
- **Connection Issues**: Resolved `net::ERR_CONNECTION_REFUSED` for emulators.
- **Web Support**: Fixed "Operation ID must be a Long" error in video generation.
- **Security**: Closed open prompt injection vectors.

---
## [0.9.1] - 2026-01-28
### Added
- TelemetryService and MultimodalScorer.
- Unit tests for long-context handling.

## [0.9.0] - 2026-01-27
### Added
- Initial Firebase AI Migration.
- Semantic Cache (Persistent).
