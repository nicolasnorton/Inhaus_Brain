# Track 3: Agent Contract & Phase Machine Hardener

## Mission
Enforce strict contracts and robustness in agent interactions.

## Key Objectives
1.  **Schema Validation**: Implement strict JSON Schema validation for all agent Inputs/Outputs.
2.  **Phase Guards**: Ensure agents transition between phases (e.g., Planning -> Execution -> Review) deterministically.
3.  **Idempotency Keys**: Add support for passing unique keys to prevent duplicate processing.
4.  **Handoff Depth**: Limit the recursion depth of agent-to-agent handoffs to prevent infinite loops.
5.  **Blackboard**: Enhance Blackboard to export state for replay/debugging.

## Deliverables
*   Updated `Agent` base classes with validation logic.
*   "Phase Machine" implementation pattern.
*   Blackboard export/import tools.
