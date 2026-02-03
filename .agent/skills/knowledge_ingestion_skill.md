---
name: knowledge_ingestion_skill
description: Processes and structures raw data (PDF, Text, Web) for the Knowledge Base vector store.
---

# Knowledge Ingestion Skill

## Purpose
To transform unstructured inputs into clean, semantic chunks optimized for RAG retrieval.

## Application Rules
**Apply this skill when:**
- The user uploads files (PDF, CSV, TXT).
- Ingesting web content via `web_search`.
- Creating new knowledge nodes.

## Core Guidelines

### 1. Pre-processing
- **Clean**: Remove headers, footers, and erratic whitespace.
- **Metadata**: Attach tags (Source, Date, Author, Category).
- **Chunking**: Split by semantic sections (headers) rather than arbitrary token counts.

### 2. Privacy Scrubber
- Run `privacy_compliance_skill` BEFORE embedding.
- If PII is found, redact it in the raw text before vectorization.

### 3. Cultural Context
- Tag content with region (e.g., "Ecuador", "LatAm") if detectable to aid regional retrieval.

## Verification Steps
1. **Sanitization**: Is PII removed?
2. **Metadata**: Are source tags present?
3. **Format**: Is the text clean JSON/Markdown?
