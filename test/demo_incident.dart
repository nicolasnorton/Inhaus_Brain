
import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/core/adk/services/adk_service.dart';
import 'package:inhaus_brain/lib/workflows/sre_incident_workflow.dart';
import 'package:inhaus_brain/features/knowledge/models/knowledge_source.dart';

void main() {
  test('SRE Incident Workflow Demo', () async {
    // 1. Setup Mock Service (Using basic AdkService provider simulation)
    // Note: In a real test, we would mock dependencies properly.
    // This is a conceptual demo script.
    
    final pipeline = sreIncidentWorkflow;
    
    print("🚀 Triggering Incident Workflow: ${pipeline.name}");
    
    // 2. Simulate Input (Flight Recorder Alert)
    final input = "ALERT: High latency detected on API Gateway (500ms avg). Error rate spike > 2%.";
    
    print("📝 Incident Report: $input");
    
    // 3. Execution Plan Trace
    print("\\n--- Workflow Execution Plan ---");
    for (var step in pipeline.steps) {
      print("[ ] Step: ${step.id} (${step.nodeType.name})");
      if (step.agentType != null) {
        print("    -> Agent: ${step.agentType!.name}");
      }
      if (step.requiresApproval) {
        print("    -> 🛑 WAITING FOR GAVEL APPROVAL (Human-in-the-loop)");
      }
    }
    
    print("\\n--- Simulation ---");
    print("1. [Intake] Received Alert.");
    print("2. [Analysis] SRE Agent querying logs...");
    print("   -> Tool: 'firebase_log_query' executed.");
    print("   -> Result: Found Error 'Null check operator' in AdkService.");
    
    print("3. [Hypothesis] SRE Agent formatting hypothesis...");
    print("   -> Hypothesis: Recent deployment introduced a regression in error handling.");
    
    print("4. [Mitigation] Proposed Fix: Revert last commit or apply hotfix patch-123.");
    
    print("5. [Approval] 🛑 BLOCKED. Waiting for User 'Gavel'...");
    // Simulate Approval
    print("   -> USER ACTION: APPROVED.");
    
    print("6. [Execution] Applying patch 'patch-123'...");
    print("   -> Tool: 'patch_simulation' executed.");
    print("   -> Result: Success. Latency standardizing.");
    
    print("7. [Postmortem] Generating Report...");
    print("   -> Artifact: POSTMORTEM.md generated.");
    
    print("\\n✅ Workflow Completed Successfully.");
  });
}
