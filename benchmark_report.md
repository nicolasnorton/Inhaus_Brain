# Performance Benchmark Report - v0.9.0

## Latency Summary (Simulated Low-End Device)
Tests conducted using `benchmark_helper.dart` simulating a network-constrained environment (250ms base latency).

| Component | Average Latency (ms) | Success Rate | Notes |
| :--- | :--- | :--- | :--- |
| **Intent Routing** | 450ms | 100% | Fast-path routing enabled. |
| **Agent Orchestration** | 1,200ms | 98% | Brian 2.0 parallel execution. |
| **Semantic Cache (Hit)** | 85ms | 100% | SharedPreferences lookups are sub-100ms. |
| **Semantic Cache (Miss)** | 1,800ms | 95% | Includes live Gemini 2.0 Flash call. |
| **Tool Execution (Web Search)** | 2,100ms | 92% | Dependent on external tool latency. |

## Optimization Wins
1. **Persistent Caching**: Lookups for repeated requests now take ~80ms instead of ~1.8s (95% reduction).
2. **Lazy Loading**: ADK Canvas widgets now use `ListView.builder` for heavy node lists (reduces initial render time by 40%).
3. **Regex Hardening**: Security audit in `OrchestratorService` adds negligible overhead (<5ms).

## Recommended Actions
- Enable **Impeller** for Flutter Web in the next build cycle to improve frame rates on animations.
- Increase cache limit from 100 to 500 entries for large-scale campaign planning.
