# ProposalsLM — Cloud Functions Integration Guide

These Python Cloud Functions replace the Express + PostgreSQL + Anthropic backend
with a Firebase-native stack that uses the **Gemini API** (google-genai SDK).

> **Zero Replit dependencies.** No `AI_INTEGRATIONS_ANTHROPIC_*` env vars,
> no Neon PostgreSQL, no Replit-specific proxy URLs.

---

## Files

| File | Purpose |
|------|---------|
| `proposals_functions.py` | 3 AI endpoints (Gemini SDK) |
| `proposals_crud.py` | Firestore CRUD + document upload |

---

## Quick Setup

### 1. Copy into your `functions-python/` directory

```bash
cp cloud_functions/proposals_functions.py  /path/to/Inhaus_Brain/functions-python/
cp cloud_functions/proposals_crud.py       /path/to/Inhaus_Brain/functions-python/
```

### 2. Register in `main.py`

Add these imports to your existing `functions-python/main.py`:

```python
# --- proposalsLM ---
from proposals_functions import tune_proforma, import_packages, proposals_chat
from proposals_crud import quotes_api, packages_api, styles_api, upload_document
```

That's it — `firebase-functions` auto-discovers the decorated functions.

### 3. Dependencies

Already in your `requirements.txt`:
- `firebase-functions`
- `firebase-admin`
- `google-genai>=1.0.0`

**Optional** (for document upload):
```
pypdf>=4.0.0        # PDF text extraction
python-docx>=1.0.0  # DOCX text extraction
```

### 4. Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GOOGLE_API_KEY` | Dev only | AI Studio key for local testing |
| `MASTER_DELETE_KEY` | Yes | Master key for soft-deleting packages |
| `PROPOSALS_MODEL` | No | Override model (default: `gemini-3-flash-preview`) |

In production, Vertex AI uses ADC automatically — no API key needed.

---

## Firestore Collections

| Collection | Fields |
|------------|--------|
| `proposals_quotes` | client, date, discount, applyIva, items[], extraBlocks[], extraAmount, totalNote, logoVariant, styleId, createdAt |
| `proposals_packages` | slug, name, category, price, billing, sections[], isCustom, packageGroup, deletedAt, deletedBy, createdAt |
| `proposals_styles` | name, colors{}, referenceImages[], isDefault, createdAt |

---

## Endpoint Mapping (Express → Cloud Functions)

| Express Route | Cloud Function | Method |
|---------------|----------------|--------|
| `/api/quotes` | `quotes_api` | GET/POST/DELETE |
| `/api/packages` | `packages_api` | GET/POST/PUT/DELETE |
| `/api/packages/deleted` | `packages_api` | GET |
| `/api/packages/:slug/restore` | `packages_api` | POST |
| `/api/styles` | `styles_api` | GET/POST/PUT/DELETE |
| `/api/tune-proforma` | `tune_proforma` | POST |
| `/api/import-packages` | `import_packages` | POST |
| `/api/chat` | `proposals_chat` | POST |
| `/api/upload-document` | `upload_document` | POST |

---

## Flutter Service Update

Update the `baseUrl` in `ProposalsService` to point to your Cloud Functions:

```dart
final service = ProposalsService(
  baseUrl: 'https://us-central1-YOUR_PROJECT.cloudfunctions.net',
);
```

The JSON contract is identical — no changes needed to the Flutter models or views.

---

## Deploy

```bash
cd /path/to/Inhaus_Brain
firebase deploy --only functions:tune_proforma,functions:import_packages,functions:proposals_chat,functions:quotes_api,functions:packages_api,functions:styles_api,functions:upload_document
```
