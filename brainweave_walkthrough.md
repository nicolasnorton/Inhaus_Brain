# BrainWeave Architecture Walkthrough

## WebMCP Support (Chrome 146+)
Inhaus Brain natively implements **Chrome WebMCP (Model Context Protocol)** for ephemeral, tab-bound communication with local and browser-integrated agents (like Claude Desktop, Cursor, or Gemini in Chrome).

### Live Tab Context & Agent Interactions
When the `webmcp_enabled` feature flag is toggled on, BrainWeave leverages JS Interop via `navigator.modelContext.registerTool()` to expose the following capabilities directly to the local AI agent:

- **Ephemeral Context:** The agent understands which tab is currently active (`brainweave_workspace_tab`), the active URL, and UI state.
- **Tools Exposed:**
  - `brainweave_graph_query`: Semantic search across the exact nodes currently active.
  - `brainweave_impact`: Analyze downstream or upstream nodes.
  - `brainweave_context`: Request deep content on a specific node.
  - `brainweave_meeting_sync`: Send meeting transcripts directly for knowledge extraction.
  - `brainweave_wiki`: Draft comprehensive markdown docs.

### Hybrid Mode & Fallback
WebMCP operates primarily as an ingestion and context-forwarding layer. 
- Read-heavy tasks are routed via the JS interop natively.
- Mutation or heavy API calls proxy seamlessly through the existing Cloud Run MCP client (`brainweave_mcp_client.dart`), meaning no double implementation. 
- If WebMCP is unavailable (non-Chrome browsers or early versions), the application falls back safely to traditional Server-Sent Events/REST APIs.

### Consent & Privacy
For WebMCP to active, explicit user consent is requested:
1. A **WebMCP Badge** shows local context tools are available.
2. A toggle lets the user manually allow or deny agent capabilities on the local tab. Disabling the toggle instantly prevents `registerTool` executions from advancing. 
