---
name: gemini-live-api-dev
description: Use this skill when building real-time, bidirectional streaming applications with the Gemini Live API. Covers WebSocket-based audio/video/text streaming, voice activity detection (VAD), native audio features, function calling, session management, ephemeral tokens for client-side auth.
---

## Overview
The Live API enables **low-latency, real-time voice and video interactions** with Gemini over WebSockets. It processes continuous streams of audio, video, or text to deliver immediate, human-like spoken responses.

Key capabilities:
- **Bidirectional audio streaming** — real-time mic-to-speaker conversations
- **Video streaming** — send camera/screen frames alongside audio
- **Voice Activity Detection (VAD)** — automatic interruption handling

## Models
- `gemini-3.1-flash-live-preview` — Optimized for low-latency, real-time dialogue. Native audio output, thinking (via `thinkingLevel`). 128k context window. **This is the recommended model for all Live API use cases.**

## Connecting to the Live API
#### Python
```python
from google import genai
from google.genai import types

client = genai.Client(api_key="YOUR_API_KEY")

config = types.LiveConnectConfig(
    response_modalities=[types.Modality.AUDIO],
    system_instruction=types.Content(
        parts=[types.Part(text="You are a helpful assistant.")]
    )
)

async with client.aio.live.connect(model="gemini-3.1-flash-live-preview", config=config) as session:
    pass  # Session is active
```

### Sending Audio
```python
await session.send_realtime_input(
    audio=types.Blob(data=chunk, mime_type="audio/pcm;rate=16000")
)
```

### Receiving Audio and Text
> [!IMPORTANT]
> A single server event can contain **multiple content parts simultaneously** (e.g., audio chunks and transcript). Always process **all** parts in each event to avoid missing content.

```python
async for response in session.receive():
    content = response.server_content
    if content:
        # Audio — process ALL parts in each event
        if content.model_turn:
            for part in content.model_turn.parts:
                if part.inline_data:
                    audio_data = part.inline_data.data
        # Interruption
        if content.interrupted is True:
            pass  # Stop playback, clear audio queue
```
