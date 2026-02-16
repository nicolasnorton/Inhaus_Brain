# Task: ReportsLM → NotebookLM Engineering Plan — COMPLETED

## All Phases Implemented ✅

### Phase 1: Foundation — Source Intelligence ✅
- [x] 1.1 Automatic Source Chunking + Embedding
  - `chunk_and_embed` endpoint in `main.py`
  - `embed_content` method in `gemini_client.py`
  - `indexSource` method in `ReportsLMService`
- [x] 1.2 RAG-First Generation
  - `_retrieveRelevantContext` replaces `_buildContextFromSources` in all generation methods
  - Graceful fallback to raw text if RAG is empty or fails
- [x] 1.3 Source Processing Upgrade
  - Page-by-page PDF extraction with `[Page X]` markers
  - Enhanced file type routing (PDF, DOCX, CSV, XLSX, HTML, TXT, MD, JSON, XML)

### Phase 2: Citation Engine ✅
- [x] 2.1 Citation-Aware Prompts (`_citationInstruction` constant added to all prompts)
- [x] 2.2 Citation Model (`Citation` class in `report_model.dart`, `_parseCitations` in service)
- [x] 2.3 Citation UI (Interactive chips in Result Dialog with source linking)

### Phase 3: Multi-Pass Generation Pipelines ✅
- [x] 3.1 Universal Pipeline Architecture (Retrieval → Outline → Draft → Review → Output)
- [x] 3.3 Report Pipeline (`_reviewAndRefine` critique + refine pass)
- [x] 3.4 Structured Output Enforcement (`outputMode: 'json'` for MindMap, Video)

### Phase 4: Review & Hallucination Prevention ✅
- [x] 4.1 Source Verification Agent (`verify_output` endpoint in `main.py`)
  - Claim extraction, status marking (SUPPORTED/UNSUPPORTED/PARTIALLY_SUPPORTED)
  - JSON structured output with `response_mime_type`
- [x] 4.2 Confidence Scoring (`overall_score`, `citation_coverage`, `hallucination_count`)
- [x] `verifyOutput` client method in `ReportsLMService`

### Phase 5: Output Quality Polish ✅
- [x] 5.1 Model Tier Upgrade
  - Previews: `gemma2n` → `geminiFlash`
  - Report Writer: `geminiFlash` → `geminiPro`
  - Mind Map: `geminiFlash` → `geminiPro`
  - Review Agent: `geminiFlash` (fast critique)
  - Audio Script: `geminiPro` (highest quality)
- [x] 5.2 Audio Synthesis Upgrade
  - `synthesize_audio` endpoint with Cloud TTS multi-speaker support
  - `en-US-Journey-D` (Host 1) + `en-US-Journey-F` (Host 2)
  - SSML markup for natural pacing
  - `generateAudioWithTTS` client method in `ReportsLMService`
  - `google-cloud-texttospeech` added to `requirements.txt`
- [x] 5.3 Chat-with-Report Upgrade
  - Query understanding (classify: factual_lookup, comparison, synthesis, opinion)
  - Multi-query decomposition for complex questions
  - Streaming response with citation-aware system instruction
  - Follow-up suggestions based on context

### Phase 6: Source Types & Connectors ✅
- [x] 6.1 Enhanced Source Processing in `KnowledgeApiService`
  - PDF: Page-by-page with markers
  - DOCX: XML extraction with server-side fallback
  - CSV: Structured key-value pairs with row labels
  - XLSX/XLS: Acknowledged with server-side fallback
  - HTML/HTM: Tag stripping for article extraction
  - TXT/MD/JSON/XML: Direct UTF-8 decode
- [x] `createDocumentFromUrl` method for web/YouTube sources
- [x] Helper methods: `_extractPdf`, `_extractDocx`, `_extractCsv`, `_extractSpreadsheet`, `_stripHtml`, `_stripXmlTags`

## Files Modified

| File | Changes |
|------|---------|
| `functions-python/main.py` | Added `chunk_and_embed`, `verify_output`, `synthesize_audio` endpoints |
| `functions-python/gemini_client.py` | Added `embed_content` method |
| `functions-python/requirements.txt` | Added `google-cloud-texttospeech>=2.16.0` |
| `lib/core/services/reports_lm_service.dart` | RAG-first generation, citations, review agent, chat upgrade, audio TTS, verification |
| `lib/features/reports/models/report_model.dart` | Added `Citation` model, updated `ReportOutput` |
| `lib/features/reports/screens/report_detail_screen.dart` | Auto-KB creation, source indexing, citation UI |
| `lib/features/knowledge/services/knowledge_api_service.dart` | Enhanced source processing (PDF, DOCX, CSV, HTML, URL) |

## Build Status
✅ `flutter build web --no-tree-shake-icons` — **PASSED** (exit code 0)
