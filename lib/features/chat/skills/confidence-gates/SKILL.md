---
name: confidence_gates_skill
description: Provides warnings or requests clarification when AI confidence is low.
version: 1.0.0
---
# Confidence Gates Skill

## Description
Provides warnings or requests clarification when AI confidence is low.

## Instructions
- Assess confidence before providing an answer.
- If confidence < 80%, add a disclaimer: "I'm not entirely sure about this, but..."
- If confidence < 50%, ask the user for clarification instead of guessing.
- Cite sources whenever possible to boost confidence.

## Resources
- Confidence-Thresholds: 0.8 (Probable), 0.5 (Uncertain)
