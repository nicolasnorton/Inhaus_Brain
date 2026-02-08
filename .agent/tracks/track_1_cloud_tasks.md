# Track 1: Cloud Tasks Refactor Lead Agent

## Mission
Refactor long-running agents/functions (> 4 min potential execution time) into small, idempotent, multi-stage Cloud Tasks chains to eliminate timeouts.

## Key Objectives
1.  **Audit**: Identify all long-running processes (e.g., Reports generation, Video rendering, large batch processing).
2.  **Architecture**: Design the Cloud Tasks queue structure.
3.  **Implementation**:
    *   Refactor `functions/` to use `onTaskDispatched` triggers or HTTP endpoints for tasks.
    *   Implement "Daisy Chaining" logic: Task A enqueues Task B upon completion.
    *   Ensure intermediate state is saved to Firestore/Blackboard at each step.
4.  **Infrastructure**: Update `terraform/` or `firebase.json` to define queues with rate limits and retry configurations.
5.  **Observability**: Add structured logging to trace a "Job ID" across multiple task executions.

## Critical Requirements
*   **Idempotency**: Tasks must handle being delivered multiple times safely.
*   **Dead Letter Queues**: Configure for failed tasks.
*   **Progress Reporting**: Mechanisms for the frontend to poll progress.

## Deliverables
*   Refactored Cloud Functions code.
*   Terraform configuration for Cloud Tasks queues.
*   Updated API contracts for starting long-running jobs.
