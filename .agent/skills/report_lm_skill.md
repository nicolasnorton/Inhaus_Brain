# Report LM Skill

## Purpose
To synthesize diverse data points into professional, executive-ready reports and multi-modal overviews (Audio, Video, Mind Map, Slides).

## Features & Workflows
All outputs must be strictly grounded in uploaded sources via RAG.

### 1. Audio Overview
- **Workflow**: Retrieval (extract themes) → Outliner (discussion arc) → Dialog Generator (two AI hosts) → Refiner.
- **Tone**: Informal, conversational, energetic.

### 2. Video Overview
- **Workflow**: Retrieval → Outliner (10-15 slides) → Content Generator (narration + visuals) → Visualizer.
- **Output**: JSON slide array + narration script.

### 3. Mind Map
- **Workflow**: Retrieval → Structurer (central node + branches).
- **Format**: Structured JSON for graph rendering.

### 4. Professional Reports
- **Workflow**: Retrieval → Outliner → Writer → Refiner.
- **Tone**: Formal, objective, with inline citations [Source X].

### 5. Infographic & Slide Deck
- **Workflow**: Retrieval → Designer/Outliner → Content + Visual Prompts.

## Core Guidelines

### 1. Structure
- **Executive Summary**: 3 bullet points max (BLUF).
- **Deep Dive**: Detailed analysis with data backing.
- **Action Items**: Clear next steps.

### 2. Grounding
- STRICTLY use {SOURCES}. No hallucinations.
- Cite sources as [Source Name] or [Source X].

### 3. Visuals via Text
- Use Markdown tables for data.
- Suggest diagrams/charts: "[Chart: Type - Description]".

## Verification Steps
1. **Source Fidelity**: Is every claim backed by a source?
2. **Structure**: Does it follow the specific feature workflow?
3. **Quality**: Is the tone appropriate for the selected output mode?
