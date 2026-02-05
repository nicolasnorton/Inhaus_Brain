import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inhaus_brain/core/mcp/agent_tool.dart';
import 'package:inhaus_brain/features/campaigns/models/campaign.dart';
import 'package:inhaus_brain/features/campaigns/providers/campaign_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:inhaus_brain/core/services/proposal_pdf_service.dart';
import 'package:inhaus_brain/features/campaigns/models/proposal_model.dart';

class CreateCampaignTool extends AgentTool {
  final CampaignListNotifier _notifier;

  CreateCampaignTool(this._notifier)
      : super(
          name: 'create_campaign',
          description: 'Create a new marketing campaign.',
          inputSchema: {
            'title': {
              'type': 'string',
              'description': 'The title of the campaign.',
            },
            'description': {
              'type': 'string',
              'description': 'A brief description of the campaign.',
            },
            'clientId': {
              'type': 'string',
              'description': 'Optional ID of the client this campaign belongs to.',
            },
            'clientName': {
              'type': 'string',
              'description': 'Optional name of the client.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final title = parameters['title'] as String?;
    final description = parameters['description'] as String? ?? '';
    final clientId = parameters['clientId'] as String?;
    final clientName = parameters['clientName'] as String?;

    if (title == null || title.isEmpty) {
      return ToolResult.failure('Missing required parameter: title');
    }

    try {
      final campaign = Campaign(
        id: 'camp-${const Uuid().v4().substring(0, 8)}',
        title: title,
        description: description,
        clientId: clientId,
        clientName: clientName,
        createdAt: DateTime.now(),
      );

      await _notifier.addCampaign(campaign);
      return ToolResult.success({
        'message': 'Campaign "$title" created successfully.',
        'campaignId': campaign.id,
      });
    } catch (e) {
      return ToolResult.failure('Failed to create campaign: $e');
    }
  }
}

class UpdateCampaignTool extends AgentTool {
  final CampaignListNotifier _notifier;
  final List<Campaign> _campaigns;

  UpdateCampaignTool(this._notifier, this._campaigns)
      : super(
          name: 'update_campaign',
          description: 'Update an existing campaign title, description, or status.',
          inputSchema: {
            'campaignId': {
              'type': 'string',
              'description': 'The ID of the campaign to update.',
            },
            'title': {
              'type': 'string',
              'description': 'New title for the campaign.',
            },
            'description': {
              'type': 'string',
              'description': 'New description for the campaign.',
            },
            'status': {
              'type': 'string',
              'description': 'New status (draft, researching, designing, inProduction, published, archived).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final campaignId = (parameters['campaignId'] ?? parameters['id']) as String?;
    if (campaignId == null) {
      return ToolResult.failure('Missing required parameter: campaignId');
    }

    try {
      final campaign = _campaigns.firstWhere(
        (c) => c.id == campaignId,
        orElse: () => throw Exception('Campaign with ID $campaignId not found.'),
      );

      CampaignStatus? newStatus;
      if (parameters['status'] != null) {
        newStatus = CampaignStatus.values.firstWhere(
          (e) => e.name == parameters['status'],
          orElse: () => campaign.status,
        );
      }

      final updatedCampaign = campaign.copyWith(
        title: parameters['title'] as String?,
        description: parameters['description'] as String?,
        status: newStatus,
      );

      await _notifier.updateCampaign(updatedCampaign);
      return ToolResult.success({'message': 'Campaign updated successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to update campaign: $e');
    }
  }
}

class DeleteCampaignTool extends AgentTool {
  final CampaignListNotifier _notifier;

  DeleteCampaignTool(this._notifier)
      : super(
          name: 'delete_campaign',
          description: 'Delete a campaign permanently.',
          inputSchema: {
            'campaignId': {
              'type': 'string',
              'description': 'The ID of the campaign to delete.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final campaignId = (parameters['campaignId'] ?? parameters['id']) as String?;
    if (campaignId == null) {
      return ToolResult.failure('Missing required parameter: campaignId');
    }

    try {
      await _notifier.deleteCampaign(campaignId);
      return ToolResult.success({'message': 'Campaign deleted successfully.'});
    } catch (e) {
      return ToolResult.failure('Failed to delete campaign: $e');
    }
  }
}

class ListCampaignsTool extends AgentTool {
  final List<Campaign> _campaigns;

  ListCampaignsTool(this._campaigns)
      : super(
          name: 'list_campaigns',
          description: 'List all marketing campaigns.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    return ToolResult.success({
      'campaigns': _campaigns.map((c) => {
        'id': c.id,
        'title': c.title,
        'status': c.status.name,
        'clientName': c.clientName ?? 'N/A',
      }).toList(),
    });
  }
}

class GenerateProposalTool extends AgentTool {
  final Ref _ref;

  GenerateProposalTool(this._ref)
      : super(
          name: 'generate_client_proposal',
          description: 'Generates a professional PDF proposal for a client. Use this for SEO plans, setup fees, and monthly maintenance proposals. Ensure the proposalJson follows the mandatory schema with title, client, cover, and sections.',
          inputSchema: {
            'clientName': {'type': 'string', 'description': 'The name of the client.'},
            'campaignId': {'type': 'string', 'description': 'Optional campaign ID.'},
            'proposalJson': {
              'type': 'string',
              'description': 'The structured JSON for the proposal (must include intro, services, pricing with setup/monthly, timeline, and cta).'
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final clientName = parameters['clientName'] as String?;
    final proposalJson = parameters['proposalJson'] as String?;
    
    if (clientName == null || proposalJson == null) {
      return ToolResult.failure('Missing clientName or proposalJson.');
    }

    try {
      // 1. Parse JSON
      final data = ProposalData.fromRawJson(proposalJson);
      
      // 2. Generate PDF
      final pdfBytes = await ProposalPdfService.generateProposalPdf(data);
      
      // 3. Save/Open (Mock)
      await ProposalPdfService.saveAndOpenPdf(pdfBytes, "Proposal_${clientName.replaceAll(' ', '_')}.pdf");

      return ToolResult.success({
        'message': 'Proposal PDF for $clientName has been generated and opened for review.',
        'status': 'success'
      });
    } catch (e) {
      return ToolResult.failure('Failed to generate proposal PDF: $e');
    }
  }
}

final campaignToolsProvider = Provider<List<AgentTool>>((ref) {
  final notifier = ref.read(campaignListProvider.notifier);
  final campaigns = ref.watch(campaignListProvider);
  
  return [
    CreateCampaignTool(notifier),
    UpdateCampaignTool(notifier, campaigns),
    DeleteCampaignTool(notifier),
    ListCampaignsTool(campaigns),
    GenerateProposalTool(ref),
  ];
});
