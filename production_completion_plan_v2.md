# Inhaus_Brain Production Completion Implementation Plan (v2.0)

This plan outlines the final steps to bring Inhaus_Brain to full production-grade quality, focusing on everything except the core output quality and Knowledge Module v2.0 (which are handled separately).

## 1. Safety & Guidelines
- **Branch**: `feature/production-completion-everything-else-v2.0-safe`
- **Gavel Gates**: Every track start, every major code write, every dependency change, and every merge requires explicit approval from Nicolas/Gavel.
- **Backward Compatibility**: All changes must avoid breaking existing workflows unless explicitly approved.
- **Technology**: Use 2026 standards (Gemini 2.0/3.0, Live API, Cloud Tasks, Terraform, BigQuery).

## 2. Tracks & Detailed Tasks

### Track 1: Scalability & Concurrency
- [ ] **Rate Limiting**: Implement Redis-based (or Firestore/Memory) rate limiting for all API endpoints and AI calls. (Basic Memory Limiter Done)
- [ ] **Backpressure**: Implement task queuing for agents using Google Cloud Tasks to handle spikes. (TaskQueueService Skeleton Done)
- [x] **Firestore Optimization**: Review and optimize every Firestore query for performance.
- [ ] **Concurrency Control**: Use Firestore transactions/atomic updates.

### Track 2: Security, Privacy & Compliance
- [x] **Audit Logging**: Create a dedicated `audit_logs` collection. Log all critical actions. (Done: `AuditLogService`)
- [x] **Deep RBAC**: Implement a robust Permission Manager that checks fine-grained scopes. (Done: `PermissionManager`)
- [ ] **Data Privacy**: Build the user-facing "Compliance Dashboard" (Ecuador/GDPR).
- [ ] **Client Isolation**: Implement security rules and logic for multi-tenancy.

### Track 3: Reliability & Observability
- [x] **Resilience Patterns**: Apply Circuit Breakers to external service wrappers. (Done: `CircuitBreaker` in `AIProxyService`)
- [ ] **Global Error Handler**: Standardize Flutter error reporting and Cloud Function logging.
- [ ] **Analytics (BigQuery)**: Sync "Flight Recorder" logs to BigQuery.
- [ ] **Proactive Monitoring**: Set up Cloud Ops (Stackdriver) alerts.

### Track 4: Deployment & CI/CD
- [ ] **Full IaC (Terraform)**: Script the creation of Firebase projects, Cloud Run services, Cloud Tasks queues, and BigQuery datasets.
- [ ] **Multi-stage Pipeline**: Configure GitHub Actions to deploy to `staging` automatically and `production` after manual approval.
- [ ] **Canary/Blue-Green**: Implement traffic splitting on Cloud Run to allow testing new versions on a subset of users.
- [ ] **Secret Management**: Move all `.env` secrets to Google Cloud Secret Manager.

### Track 5: Collaboration & UX
- [ ] **Dual-Pane UI**: Standardize the Agent/Canvas interface across all features.
- [ ] **Real-time Collaboration**: Implement (or harden) presence and co-editing indicators using Firebase Realtime DB or Firestore.
- [ ] **Social Features**: Add @-mentions in chat that notify users and threaded comments on Canvas widgets.
- [ ] **Asset Versioning**: Track and display history of changes for generated assets (proposals, images, videos).
- [ ] **Onboarding**: Build a "Welcome/Tour" widget for first-time users.

### Track 6: Integrations & Extensibility
- [ ] **OAuth Hardening**: Implement a centralized `IntegrationService` that manages tokens, refreshes, and health checks.
- [ ] **Unified Webhooks**: Provide a UI for users to register webhooks for campaign events.
- [ ] **Agent Marketplace**: Create a registry for Agent Templates that users can "install" into their workspace.

### Track 7: Testing & Documentation
- [ ] **Automated Testing Suite**: E2E tests for the core "Campaign Workflow" from start to finish.
- [ ] **Performance Benchmarking**: Run load tests on Cloud Run and Firestore.
- [ ] **Accessibility (A11y)**: Standardize semantic HTML/Flutter semantics and screen reader support.
- [ ] **Documentation**: Generate API documentation and a "User Manual" in the `docs/` folder.

### Track 8: Master Integration & Demo
- [ ] **Integration Sprints**: Weekly merges of all tracks into the main feature branch.
- [ ] **Full Production Demo**: A scripted walk-through showing a multi-user, multi-agent campaign creation with monitoring and audit logs.
- [ ] **Final Report**: Generate `PRODUCTION_COMPLETION_REPORT_v2.0.md`.

## 3. Immediate Next Steps (Post-Gavel)
1. Initialize the `AuditLogService` (Security).
2. Set up `Cloud Tasks` integration for `AssistantService` (Scalability).
3. Refactor the `SplitPaneLayout` to be the primary view (UX).

## 4. Gavel Gate #1: Initial Plan Review
Please review this high-level plan. Once approved, I will begin Track 1 & 2 in parallel.
