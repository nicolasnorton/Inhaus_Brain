# System Agents & Personas

This document outlines the active agents and personas within the Inhaus Brain system.

## System Agents
These are code-based agents located in `lib/features/chat/agents`. They handle specific logic, tool execution, and orchestration.

- **Router Agent** (`router_agent.dart`): The central nervous system that analyzes user intent (Creative, Research, Management, etc.) and routes requests to the appropriate sub-agent or toolset.
- **Management Agent** (`management_agent.dart`): Handles administrative tasks, client management, and campaign orchestration.
- **Knowledge Librarian** (`knowledge_librarian_agent.dart`): Manages the ingestion, retrieval, and organization of knowledge sources.
- **Agency Agents** (`agency_agents.dart`): Implementation of specific agency roles (Strategist, Creative, etc.).
- **Utility Agents** (`utility_agents.dart`): specialized agents for specific discrete tasks.
- **Core Agents** (`core_agents.dart`): Foundational agent implementations.

## Persona Prompts
These are role-based system prompts located in `assets/prompts`. They define the personality, capabilities, and constraints for specific agent roles.

### Leadership & Strategy
- **Account Director** (`account_director.md`): specialized in client relations, strategy, and high-level account management.
- **Strategist** (`strategist.md`): Focuses on campaign strategy, market positioning, and long-term planning.
- **Orchestrator** (`orchestrator.md`): High-level coordination of multi-agent workflows.

### Creative & Content
- **Creative** (`creative.md`): Concept generation, visual direction, and mood boarding.
- **Copywriter** (`copywriter.md`): Text generation, tone adaptation, and content writing.
- **Editorial Manager** (`editorial_manager.md`): Review, editing, and content quality assurance.

### Analysis & Performance
- **Media Buyer** (`media_buyer.md`): Ad placement strategies and budget optimization.
- **Performance Analyst** (`performance_analyst.md`): Data analysis, reporting, and KPI tracking.
- **Trend Scout** (`trend_scout.md`): Researching emerging trends and market signals.
- **Research** (`research.md`): Deep-dive information gathering and fact-checking.

### Technical & Operations
- **Developer** (`developer.md`): Code generation, debugging, and technical architecture.
- **Data Engineer** (`data_engineer.md`): Data pipeline management and structural integrity.
- **Security** (`security.md`): Ensuring compliance, safety, and data protection.

---

## AI Development Rules
All agents (Antigravity, Jules) must adhere to the rules defined in `agentrules.md`. These rules enforce architectural integrity, state management standards, and workflow consistency.

## Live Deployment
- **Live URL**: [https://brain.inhauscorp.com](https://brain.inhauscorp.com)
- **Functions Host**: `us-central1-inhausbrain.cloudfunctions.net`
- **Environment**: Managed by Google Cloud Run & Firebase.
