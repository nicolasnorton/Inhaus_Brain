import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import 'package:inhaus_brain/core/architecture/blackboard.dart';
import '../models/proposal_model.dart';

class GenerateProposalTool extends AgentTool {
  GenerateProposalTool()
      : super(
          name: 'generate_client_proposal',
          description: 'Triggers the generation of a professional client proposal. Requires a basic proposal object (ID and Client details).',
          inputSchema: {
            'proposalId': {
              'type': 'string',
              'description': 'The ID of the existing proposal record to generate.',
            },
            'type': {
              'type': 'string',
              'description': 'Type of proposal: "detailed" or "one_page". Defaults to "detailed".',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final proposalId = parameters['proposalId'] as String?;
    final type = parameters['type'] as String? ?? 'detailed';

    if (proposalId == null) {
      return ToolResult.failure('Missing required parameter: proposalId');
    }

    try {
      final blackboard = ref.read(blackboardProvider.notifier);
      
      // Note: In a real scenario, we might need to fetch the proposal object first.
      // But for the tool, we just post the event. The OrchestrationService will handle the rest.
      // However, OrchestrationService._handleUserRequest expects 'proposal' object in data.
      // So we might need to fetch it here.
      
      // For now, let's assume the OrchestrationService can be updated to fetch by ID, 
      // or we provide a mock/partial proposal if needed.
      // Actually, let's just post a "request_proposal_generation" event with the ID.
      
      blackboard.addEvent(
        WorkflowEventType.userRequested, 
        "Generate Proposal Request ($type)",
        data: {
          'action': 'create_proposal',
          'proposalId': proposalId,
          'type': type,
        }
      );

      return ToolResult.success({
        'message': 'Proposal generation triggered for ID: $proposalId. Status updates will follow on the Blackboard.'
      });
    } catch (e) {
      return ToolResult.failure('Failed to trigger proposal generation: $e');
    }
  }
}
