# Track 2: Cloud Run Orchestration Prototype Agent

## Mission
Design and prototype a Cloud Run based alternative for orchestration to compare against Cloud Tasks.

## Key Objectives
1.  **Prototype**: Build a small proof-of-concept (PoC) using Cloud Run to orchestrate a long multi-step agent flow (e.g., a mock reporting flow).
2.  **Evaluate**:
    *   Complexity of managing state in a container vs. serverless functions.
    *   Cold start impact on user experience.
    *   Cost analysis for sporadic vs. continuous usage.
    *   Timeout handling (Cloud Run has higher default timeouts, but still limits).
3.  **Output**: Produce a detailed decision matrix comparing Cloud Tasks vs. Cloud Run.

## Deliverables
*   `CLOUD_TASKS_VS_CLOUD_RUN_MATRIX.md` (filled out).
*   PoC code in `experiment/cloud_run_poc/` (or similar isolated path).
