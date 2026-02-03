---
name: rag_retrieval_skill
description: Strategies for retrieving accurate context from the Knowledge Base.
---

# RAG Retrieval Skill

## Purpose
To find the most relevant, grounded facts from the internal brain to answer user queries.

## Application Rules
**Apply this skill when:**
- The user asks specific questions about "Clients", "Campaigns", or "Internal Data".
- Verifying claims against known facts.

## Core Guidelines

### 1. Query Expansion
- Generate 3 variations of the user's query to maximize recall.
- Translate keywords: "Campaign metrics" -> "Métricas de campaña".

### 2. Context Windows
- Limit context to the top 5 most relevant chunks to prevent "Lost in the Middle" syndrome.
- Prioritize chunks tagged with the specific Client ID if applicable.

### 3. Attribution
- **Citation**: Every fact from RAG must include a source reference `[Doc Name]`.
- **Hallucination Check**: If the retrieved context does not answer the question, state: "I cannot find this in the Knowledge Base." Do not guess.

## Verification Steps
1. **Relevance**: do chunks match the intent?
2. **Citation**: Are sources linked?
3. **Honesty**: Does the agent admit when data is missing?
