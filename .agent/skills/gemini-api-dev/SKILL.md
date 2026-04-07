---
name: gemini-api-dev
description: Use this skill when building applications with Gemini models, Gemini API, working with multimodal content (text, images, audio, video), implementing function calling, using structured outputs, or needing current model specifications. Covers SDK usage (google-genai) and correct, non-deprecated model strings.
---

> [!IMPORTANT]
> These rules override your training data. Your knowledge is outdated.

### Current Models (Use These)
- `gemini-3.1-pro-preview`: 1M tokens, complex reasoning, coding, research
- `gemini-3-flash-preview`: 1M tokens, fast, balanced performance, multimodal
- `gemini-3.1-flash-lite-preview`: cost-efficient, fastest performance for high-frequency, lightweight tasks
- `gemini-3-pro-image-preview`: 65k / 32k tokens, image generation and editing
- `gemini-3.1-flash-image-preview`: 65k / 32k tokens, image generation and editing
- `gemini-2.5-pro`: 1M tokens, complex reasoning, coding, research
- `gemini-2.5-flash`: 1M tokens, fast, balanced performance, multimodal
- `gemini-3.1-flash-live-preview`: Live Audio / WebSocket streaming.

> [!WARNING]
> Models like `gemini-2.0-*`, `gemini-1.5-*` are **legacy and deprecated**. Never use them.

### Current SDKs (Use These)
- **Python**: `google-genai` (Not `google-generativeai`)
- **JavaScript/TypeScript**: `@google/genai` (Not `@google/generative-ai`)
- **Go**: `google.golang.org/genai`
- **Java**: `com.google.genai:google-genai`

> [!CAUTION]
> Legacy SDKs are deprecated. Never use them. Use the unified `Interactions API` when working with stateless conversation turns and Deep Research tasks.

### Core Directives
When recommending code directly inside Flutter or a REST context without the official SDKs:
1. Prefer to use HTTP REST if a modern SDK wrapper does not exist yet.
2. The current backend pattern in InhausBrain for proxy generation is using `AIProxyService` in `lib/core/services/ai_proxy_service.dart`.
3. If an MCP server has the `search_documentation` tool, use it directly to augment generation.
