---
name: confidence_gates_skill
description: Enforces quality control by rejecting low-confidence AI generations.
---

# Confidence Gates Skill

## Purpose
To maintain high standards by preventing the user from seeing specific, low-quality, or hallucinated outputs.

## Application Rules
**Apply this skill when:**
- Generating factual research summaries.
- Proposing strategic directions.
- Executing code or complex logic.

## Core Guidelines

### 1. Thresholds
- **Critical (Code/Facts)**: Threshold **0.90**. If confidence < 0.90, reject or flag with strong warning.
- **Creative (Brainstorming)**: Threshold **0.75**. Allow broader ideas but flag "Wildcard" concepts.
- **General**: Threshold **0.85**. Default standard.

### 2. Evaluation Logic
- **Self-Correction**: If the agent doubts its answer, it must:
    1. Attempt to verify via tools (Search, Knowledge Base).
    2. If still low confidence, explicitly state: "I am not confident in this result because [Reason]."
- **Refusal**: It is better to refuse a task than to provide false information.

### 3. User Notification
- **Low Confidence**: "⚠️ Confidence Check: I found limited data on this. Here is what I suspect, but please verify."
- **Rejection**: "🛑 I cannot complete this task with sufficient reliability. Please clarify [X] or provide more data."

## Verification Steps
1. **Score Check**: Does the content meet the required confidence threshold?
2. **Source Check**: Are facts backed by citations?
3. **Safety Check**: Is the refusal polite and helpful (suggesting a fix)?
