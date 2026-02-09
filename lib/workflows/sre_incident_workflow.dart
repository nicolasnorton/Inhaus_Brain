import '../core/adk/models/pipeline_models.dart';
import '../features/chat/models/chat_models.dart';

// SRE Incident Response Workflow
final sreIncidentWorkflow = Pipeline(
  id: 'sre-incident-workflow',
  name: 'SRE Incident Response',
  description: 'Google SRE-style incident management with SRE Orchestrator Agent.',
  steps: [
    // 1. Intake: Receive Incident
    PipelineStep(
      id: 'intake',
      nodeType: WorkflowNodeType.trigger,
      instruction: 'Wait for Incident Report',
      uiPosition: {'x': 100, 'y': 100},
      config: {
        'triggerType': 'event', 
        'event': 'INCIDENT_REPORTED'
      }
    ),

    // 2. Analysis: SRE Agent Analyzes Telemetry
    PipelineStep(
      id: 'analysis',
      nodeType: WorkflowNodeType.agent,
      agentType: MessageSender.sreOrchestratorAgent,
      instruction: 'Analyze logs and metrics to identify symptoms.',
      dependencies: ['intake'],
      uiPosition: {'x': 300, 'y': 100},
      config: {
        'systemPrompt': 'You are the SRE Orchestrator. An incident has been reported. Check available logs and metrics to identify symptoms. Be precise.',
      }
    ),

    // 3. Hypothesis: Generate Hypothesis
    PipelineStep(
      id: 'hypothesis',
      nodeType: WorkflowNodeType.agent, 
      agentType: MessageSender.sreOrchestratorAgent,
      instruction: 'Formulate a hypothesis for the root cause.',
      dependencies: ['analysis'],
      uiPosition: {'x': 500, 'y': 100},
      config: {
        'systemPrompt': 'Based on the analysis, formulate a hypothesis for the root cause. List potential factors.',
      }
    ),

    // 4. Mitigation Proposal
    PipelineStep(
      id: 'mitigation_proposal',
      nodeType: WorkflowNodeType.agent,
      agentType: MessageSender.sreOrchestratorAgent,
      instruction: 'Propose a mitigation plan.',
      dependencies: ['hypothesis'],
      uiPosition: {'x': 700, 'y': 100},
      config: {
        'systemPrompt': 'Propose a safe mitigation plan. Identify risks. Recommend a specific patch or action.',
      }
    ),

    // 5. Approval: Human-in-the-loop (Gavel)
    PipelineStep(
      id: 'mitigation_approval',
      nodeType: WorkflowNodeType.userInput, 
      instruction: 'Wait for Approval (Gavel)',
      requiresApproval: true, 
      dependencies: ['mitigation_proposal'],
      uiPosition: {'x': 900, 'y': 100},
      config: {
        'inputType': 'approval',
        'message': 'Review the proposed mitigation plan. Approve to execute?'
      }
    ),

    // 6. Execution: Apply Mitigation
    PipelineStep(
      id: 'mitigation_execution',
      nodeType: WorkflowNodeType.agent,
      agentType: MessageSender.sreOrchestratorAgent,
      instruction: 'Execute approved mitigation.',
      dependencies: ['mitigation_approval'],
      uiPosition: {'x': 1100, 'y': 100},
      config: {
        'systemPrompt': 'Execute the approved mitigation plan now. Use available tools (e.g., patch simulator).',
      }
    ),

    // 7. Verify & Root Cause
    PipelineStep(
      id: 'root_cause_analysis',
      nodeType: WorkflowNodeType.agent,
      agentType: MessageSender.sreOrchestratorAgent,
      instruction: 'Verify fix and determine final root cause.',
      dependencies: ['mitigation_execution'],
      uiPosition: {'x': 1300, 'y': 100},
      config: {
        'systemPrompt': 'Verify system health. Perform deep-dive root cause analysis. What was the underlying issue?',
      }
    ),

    // 8. Postmortem
    PipelineStep(
      id: 'postmortem',
      nodeType: WorkflowNodeType.agent,
      agentType: MessageSender.postmortemAgent,
      instruction: 'Generate Postmortem Report.',
      dependencies: ['root_cause_analysis'],
      uiPosition: {'x': 1500, 'y': 100},
      config: {
        'template': 'sre_postmortem_v1',
        'systemPrompt': 'Generate a formal Postmortem Report in Markdown based on the incident timeline and root cause Analysis.'
      }
    ),
  ],
);
