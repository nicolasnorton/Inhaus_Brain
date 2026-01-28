# Security & Compliance Checklist - Inhaus Brain

## 1. Prompt & Agent Safety
- [x] **PII Redaction**: All specialist agents have explicit instructions to redact emails, phone numbers, and real names.
- [x] **Orchestrator Intervention**: `OrchestratorService` now implements Regex-based PII redaction and prompt injection detection.
- [x] **Cultural Sensitivity**: Guidelines for LatAm/Ecuador regionalisms and inclusive language added to `brian.md` and specialists.
- [x] **Intent Shield**: `AssistantService` routes requests through a filtered path to prevent system prompt leakage.

## 2. Infrastructure & Data
- [x] **Firestore Rules**: Implemented `firestore.rules` for authenticated, owner-only access.
- [x] **Storage Rules**: Implemented `storage.rules` to protect user-uploaded images and generated assets.
- [x] **App Check**: (Existing) Prevent unauthorized API calls from non-app clients.
- [x] **Vault / Secure Storage**: All API keys managed via `FlutterSecureStorage`.

## 3. Monitoring & Auditing
- [x] **Cloud Logging**: All orchestrator interventions are logged to GCP (Structured logging via `logger`).
- [x] **Sentry Integration**: Real-time crash and error reporting (Dependencies added).
- [x] **Flight Recorder**: Real-time event auditing via the ADK Blackboard.

## 4. Input/Output Validation
- [x] **Regex Filtering**: Emails and Phone numbers auto-redacted in `OrchestratorService`.
- [x] **Forbidden Terms**: Competitive brand protection active.
- [x] **Arbiter Review**: User arbitration phase triggers if AI confidence < 0.7 (Logic in `AssistantService`).

---
*Last Updated: 2026-01-28*
