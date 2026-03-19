# InhausBrain Agent Protocols: User & Test Guide

Welcome to the modernized InhausBrain Agent Protocol suite. This guide helps you test and verify the implementation of **AG-UI**, **UCP**, **AP2**, and **A2A**.

## 🚀 1. AG-UI: Streaming Interaction
The system now uses the standard **AG-UI (Agent-User Interaction)** protocol for Server-Sent Events (SSE). This ensures smoother text streaming and visible tool-calling states.

### Test Prompt:
> "Brain, please research the current state of consumer electronics in 2026 and then generate a high-priority marketing strategy draft for a new folding phone."

**What to look for:**
- Incremental text rendering (no long pauses for the whole block).
- UI indicators when tools are running (e.g., "Using research...").
- Cleanly formatted text with any nested A2UI widgets appearing at the end.

---

## 🛒 2. UCP: Universal Commerce Protocol
We have implemented the **UCP** REST headers. The agent can now discover businesses and initiate checkout flows using standardized schemas.

### Test Prompt:
> "Discover a tech store using UCP and initiate a checkout for a high-end laptop."

**Verification:**
- Open the Browser Inspector (Network Tab).
- Confirm requests to `$_baseUcpPlatformUrl/discover` include the `UCP-Agent: InhausBrain/2.1` header.
- Confirm the `CheckoutCapability` is parsed into the Business object.

---

## 🔐 3. AP2: Agent Payments Protocol
Autonomous spending is now protected by **AP2** cryptographic mandates. Every high-stakes intent requires a signed `IntentMandate`.

### Test Prompt:
> "Sign a payments and shipping mandate for my user ID and show me the signature."

**Verification:**
- The agent should return a message indicating a signature was generated.
- Internally, this uses the `AP2CryptoService` which simulates a secure enclave using SHA-256 HMAC (persisted in secure storage).

---

## 🔍 4. A2A: Agent-to-Agent Discovery
Agents can now verify each other's identities using the `/.well-known/agent-card.json` standard.

### Live URL:
Check the live discovery card at:
[https://inhausbrain-beta.web.app/.well-known/agent-card.json](https://inhausbrain-beta.web.app/.well-known/agent-card.json) (Pending DNS/Routing)

### Test Prompt:
> "Verify the Inhaus Core Agent card and describe its capabilities."

**Verification:**
- The system will attempt to fetch the discovery JSON from the well-known path.
- It validates the `agent_id` (URN-based) and `public_key`.

---

## ✅ Deployment Status
- **Backend**: Python functions deployed (including `agent_card` and `generate_content_stream`).
- **Frontend**: Flutter Web (Staging) updated with new protocol parsers.
- **Link**: [https://inhausbrain-beta.web.app/](https://inhausbrain-beta.web.app/)
