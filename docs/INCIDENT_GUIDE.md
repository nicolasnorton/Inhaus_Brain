# SRE Incident Response Workflow Guide

## Overview
This workflow implements Google's Gemini CLI outage resolution process as a dedicated Agent Development Kit (ADK) pipeline.

## Capabilities
- **Intake**: Automatically detects incidents via `INCIDENT_REPORTED` event.
- **Analysis**: SRE Orchestrator analyzes logs using `firebase_log_query`.
- **Mitigation**: Proposes safe fixes and uses `patch_simulation` to verify.
- **Approval**: Requires explicit human approval (Gavel) before execution.
- **Postmortem**: Auto-generates Markdown reports using `PostmortemAgent`.

## Agents
1. **SRE Orchestrator Agent**: Handles triage, hypothesis, and execution.
2. **Postmortem Agent**: Synthesizes event data into reports.

## Tools
- `github_commit_fetch`: Retrieves recent commits to correlate with incidents.
- `firebase_log_query`: Fetches error logs and metrics.
- `patch_simulation`: dry-runs patches in a staging environment.

## Usage
1. Trigger the workflow via ADK Canvas or Event Bus:
   ```dart
   eventBus.publish(AdkEvent(type: AdkEventType.trigger, source: 'user', message: 'INCIDENT_REPORTED'));
   ```
2. The SRE Agent will analyze and propose a plan.
3. Review the plan in the Chat UI.
4. Click "Approve" to authorize the fix.
5. Receive the Postmortem report upon completion.

## Safety
- **Read-Only First**: Agents start in analysis mode.
- **Human-in-the-Loop**: Critical actions are gated.
- **Audit**: All actions are logged to Blackboard/Flight Recorder.
