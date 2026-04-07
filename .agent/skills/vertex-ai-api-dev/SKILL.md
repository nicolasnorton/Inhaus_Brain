---
name: vertex-ai-api-dev
description: Guides the usage of Gemini API on Google Cloud Vertex AI with the Gen AI SDK. Use when the user asks about using Gemini in an enterprise environment or explicitly mentions Vertex AI. Covers SDK usage (Python, JS/TS, Go, Java, C#), capabilities like Live API, tools, multimedia generation, caching, and batch prediction.
---

Access Google's most advanced AI models built for enterprise use cases using the Gemini API in Vertex AI.

Provide these key capabilities:
- **Text generation** - Chat, completion, summarization
- **Multimodal understanding** - Process images, audio, video, and documents
- **Function calling** - Let the model invoke your functions
- **Structured output** - Generate valid JSON matching your schema
- **Context caching** - Cache large contexts for efficiency
- **Live Realtime API** - Bidirectional streaming for low latency Voice and Video interactions

## Core Directives
- **Unified SDK**: ALWAYS use the Gen AI SDK (`google-genai` for Python, `@google/genai` for JS/TS).
- **Legacy SDKs**: DO NOT use `google-cloud-aiplatform` or `google-generativeai`.

## Authentication & Configuration
Prefer environment variables over hard-coding parameters when creating the client. Initialize the client without parameters to automatically pick up these values.

Set these variables for standard Google Cloud authentication:
```bash
export GOOGLE_CLOUD_PROJECT='your-project-id'
export GOOGLE_CLOUD_LOCATION='global'
export GOOGLE_GENAI_USE_VERTEXAI=true
```

## Initialization
Initialize the client without arguments to pick up environment variables:
```python
from google import genai
client = genai.Client()
```

## API spec & Documentation (source of truth)
When implementing or debugging API integration for Vertex AI, refer to the official Google Cloud Vertex AI documentation.
The Gen AI SDK on Vertex AI uses the `v1beta1` or `v1` REST API endpoints (e.g., `https://{LOCATION}-aiplatform.googleapis.com/v1beta1/projects/{PROJECT}/locations/{LOCATION}/publishers/google/models/{MODEL}:generateContent`).
