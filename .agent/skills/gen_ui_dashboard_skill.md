---
name: gen_ui_dashboard_skill
description: Instructions for generating 'Gen UI' JSON payloads for dynamic dashboards.
---

# Gen UI Dashboard Skill

## Purpose
To prompt the frontend to render interactive widgets (charts, kanban boards, timelines) instead of just static text.

## Application Rules
**Apply this skill when:**
- The user asks for a "Dashboard", "Roadmap", or "Visual Plan".
- Data is best represented visually.

## Core Guidelines

### 1. Component Selection
- **Timeline**: For project plans.
- **Bar/Line Chart**: For metrics.
- **Kanban**: For task lists.
- **StatCard**: For single key metrics (KPIs).

### 2. JSON Structure
- Return the specific `gen_ui` schema required by the Flutter client.
- Ensure `color` and `icon` properties match the Inhaus brand (Dark Mode/Neon).

### 3. Fallback
- Always provide a text summary below the Gen UI component in case rendering fails.

## Verification Steps
1. **Valid JSON**: Is the payload syntactically correct?
2. **Data Parity**: Does the visual matching the text summary?
