
# Telemetry Event Spec & Data Dictionary

## 1. Events

### `ai_feedback`
Triggered when a user clicks Thumbs Up / Thumbs Down.

| Parameter | Type | Description |
|-----------|------|-------------|
| `message_id` | String | UUID of the message being rated. |
| `rating` | String | 'positive' or 'negative'. |
| `model_name` | String | Model used (e.g., 'gemini-1.5-flash', 'gpt-4o'). |
| `content_length` | Int | Length of the output text. |
| `confidence` | Double | (Optional) Confidence score 0.0-1.0 from the LLM. |

### `agent_interaction`
Triggered when an agent completes a task or tool call.

| Parameter | Type | Description |
|-----------|------|-------------|
| `agent` | String | Name of the agent (e.g., 'ResearchAgent', 'CreativeAgent'). |
| `action` | String | Action performed (e.g., 'web_search', 'generate_image'). |
| `duration_ms` | Double | Execution time in milliseconds. |
| `success` | Int | 1 for success, 0 for failure. |

## 2. BigQuery Export Schema
Firebase Analytics exports automatically to `events_YYYYMMDD`.
Custom parameters are nested in `event_params`.

## 3. Privacy & Safety
- **No PII**: Message content is NOT logged, only length or hash.
- **No User IDs in Custom Params**: `user_id` is handled by standard Firebase Analytics fields.
- **Retention**: Data retained for 14 months (standard Analytics setting).
