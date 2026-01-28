# Implementation Plan - Production Architecture Upgrade

This plan outlines the implementation of the 4-step architecture described in the First Principles Audit. The goal is to transform Inhaus_Brain from a serial prototype into a robust, parallelized, production-grade system.

## 1. Audit Validation & Critique

### Validation
*   **The Blackboard Pattern** is highly effective for decoupling agents. It allows for "opportunistic" agent execution where sub-agents can contribute as soon as their required data is available.
*   **Tiered Context** is necessary to prevent "context collapse" where LLMs ignore instructions due to sheer token volume.
*   **Evals** are the only way to measure regression in non-deterministic systems.

### Critique & Risks
*   **Blackboard Complexity**: Managing race conditions (e.g., two agents trying to "solve" a task simultaneously) requires an event-driven locking mechanism or a strict "Task Ownership" state.
*   **GenUI Latency**: While GenUI masks "processing" latency, loading complex widgets can introduce "rendering" jank if not optimized (using `const` and avoiding unnecessary rebuilds).
*   **Router Feedback Loop**: The audit suggests the router should "learn." This technically requires a persistence layer for "Corrections" and possibly dynamic few-shot prompting, which increases token overhead.

---

## 2. Implementation Phases

### Phase 1: Tiered Context (The Memory Fix)
**Objective**: Replace `List<Message>` with a structured `AgentMemory` object.
*   [ ] Define `GlobalContextModel`: Long-term goals, project constraints.
*   [ ] Define `WorkingMemoryModel`: Short-term task state, active agent buffers.
*   [ ] Implement `EpisodicMemoryService`: Local vector search/summarization using `gemini-2.0-flash`.
*   [ ] Update `AssistantService` to assemble prompts from these tiers.

### Phase 2: Blackboard Pattern (Parallel Orchestration)
**Objective**: Move from serial execution to a Riverpod-based event bus.
*   [ ] Create `BlackboardNotifier`: A central state container for the current "Campaign Workflow."
*   [ ] Implement `WorkflowEvent` system: `NeedsStrategy`, `TrendsAvailable`, `BudgetCalculated`.
*   [ ] Refactor `RouterAgent`: Instead of direct calling, it should "post" requirements to the Blackboard.
*   [ ] Refactor Sub-Agents: They "subscribe" to certain event types on the Blackboard.

### Phase 3: Generative UI (GenUI)
**Objective**: Enhance the chat interface to render structured objects instead of just text.
*   [ ] Create `GenUIResolver`: Maps Agent JSON outputs to Flutter Widgets.
*   [ ] Implement `StrategyBoardWidget`: Visualizes milestones and objectives.
*   [ ] Implement `BudgetBreakdownWidget`: Renders charts for media buying.
*   [ ] Implement `OptimisticResponseService`: Shows "The Strategist is analyzing trends..." in a dedicated UI slot before the content is ready.

### Phase 4: Evals as Unit Tests
**Objective**: Create a verifiable quality benchmark.
*   [ ] Setup `test/evals/` harness.
*   [ ] Create `GoldenInputs.json`: 50 diverse test cases.
*   [ ] Implement `llm_grader.dart`: Uses Gemini Flash to score agent outputs (accuracy, tone, format).
*   [ ] Integrate into `setup.sh` or a new `run_evals.sh`.

---

## 3. Immediate Next Steps (Task: ARCH-001)
1.  Initialize the `BlackboardState` model in `lib/core/architecture/blackboard.dart`.
2.  Define the `AgentMemory` structure in `lib/core/architecture/memory.dart`.
