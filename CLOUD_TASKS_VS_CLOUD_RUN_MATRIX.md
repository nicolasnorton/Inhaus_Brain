# Decision Matrix: Cloud Tasks vs. Cloud Run

*To be filled by Cloud Run Orchestration Prototype Agent (Track 2)*

## Overview
Evaluating the best architecture for long-running agents in InhausBrain: breaking down into Cloud Tasks chains (Serverless Functions) vs. containerized Cloud Run execution.

## Comparison Criteria

| Criteria | Cloud Tasks (Chained Functions) | Cloud Run (Containerized Monolith) | Preference |
| :--- | :--- | :--- | :--- |
| **Timeout Limits** | 9 min (gen1) / 60 min (gen2) per task | 60 min (default) / up to 24h (beta/config) | **Cloud Tasks** (Granular) |
| **State Management** | **Required** per step (Firestore/Blackboard). Robust. | In-memory possible, but risky on failure. | **Cloud Tasks** (Safety) |
| **Complexity** | High (serialization, splitting logic) | **Low** (standard async/await flow) | **Cloud Run** (DX) |
| **Cold Starts** | Frequent (per function invocation) | Less Frequent (if instances kept alive/min instances) | **Cloud Run** |
| **Observability** | Distributed traces, harder to stitch | Unified log stream per container | **Cloud Run** |
| **Cost** | Pay per invocation active time | Pay per instance time (CPU/Memory) even when idle/awaiting | **Cloud Tasks** (Efficiency) |
| **Idempotency** | Critical (retries are automatic per step) | Critical (restarts lose progress) | **Cloud Tasks** |
| **Developer Exp** | Requires breakdown thinking | familiar node.js flow | **Cloud Run** |

## Recommendation
**Use Cloud Tasks (Chained Functions) for Production Reliability.**

While Cloud Run offers a simpler developer experience (writing standard async code), the risk of losing progress in long-running jobs (10-40 mins) due to a single failure or preemption is too high. Cloud Tasks forces a checkpoint-based architecture (saving state after each step), which is inherently more robust for complex, multi-stage agent workflows.

**Strategy:**
1.  Use **Cloud Tasks** for the main orchestration backbone (Research -> Strategy -> Creative).
2.  Use **Cloud Run** only if a *single atomic step* requires >9 mins of continuous CPU/GPU processing (unlikely for LLM orchestration which is mostly I/O waiting).
