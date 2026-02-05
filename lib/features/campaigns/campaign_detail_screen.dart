import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'models/campaign.dart';
import 'providers/campaign_provider.dart';
import '../creative/providers/creative_provider.dart';
import '../clients/providers/client_provider.dart';
import '../../core/widgets/ai_status_badge.dart';
import '../chat/agents/agency_agents.dart';
import 'models/proposal_model.dart';
import '../../core/services/proposal_pdf_service.dart';
import 'package:inhaus_brain/features/knowledge/providers/knowledge_provider.dart';
import 'package:inhaus_brain/features/knowledge/models/knowledge_source.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignListProvider);
    final campaign = campaigns.where((c) => c.id == campaignId).firstOrNull;

    if (campaign == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.loading ?? 'Loading...'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(campaign.title),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, campaign),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.agentResearchInsights,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.reviewApproveInsights,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            ...campaign.insights.map((insight) => _buildInsightCard(context, ref, campaign, insight)),
            const SizedBox(height: 32),
            if (campaign.insights.every((i) => i.isApproved) && campaign.status == CampaignStatus.researching)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final updatedCampaign = campaign.copyWith(status: CampaignStatus.designing);
                    await ref.read(campaignListProvider.notifier).updateCampaign(updatedCampaign);
                    
                    // Trigger Creative Agent to propose a concept
                    await ref.read(creativeProvider.notifier).generateConceptForCampaign(campaign);
                  },
                  child: Text(AppLocalizations.of(context)!.proceedToDesignPlan),
                ),
              ),
            if (campaign.status == CampaignStatus.designing)
              _buildDesignPlanPlaceholder(context, ref, campaign),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Campaign campaign) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_outline, color: Colors.blueAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.campaignStrategyBrief,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.business, size: 14, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(
                          campaign.clientName ?? AppLocalizations.of(context)!.notAvailable,
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                        if (campaign.industry != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.category, size: 14, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text(
                            campaign.industry!,
                            style: const TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const AIStatusBadge(),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          MarkdownBody(
            data: campaign.description,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.6, fontSize: 15),
              h1: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
              h2: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              h3: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
              strong: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              blockquote: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
              blockquoteDecoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.blueAccent, width: 4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, WidgetRef ref, Campaign campaign, ResearchInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2329), // Distinct card color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: insight.isApproved ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          width: insight.isApproved ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MarkdownBody(
                    data: insight.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white),
                      strong: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                      listBullet: const TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (insight.isApproved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.approved,
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      final updatedInsights = campaign.insights.map((i) {
                        if (i.id == insight.id) return i.copyWith(isApproved: true);
                        return i;
                      }).toList();
                      ref.read(campaignListProvider.notifier).updateCampaign(
                            campaign.copyWith(insights: updatedInsights),
                          );
                    },
                    icon: const Icon(Icons.thumb_up_outlined, size: 16),
                    label: Text(AppLocalizations.of(context)!.approveInsight),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignPlanPlaceholder(BuildContext context, WidgetRef ref, Campaign campaign) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette, color: Colors.purpleAccent),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.designPhaseActive,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.creativeProposedDirections),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/creative'),
              icon: const Icon(Icons.auto_awesome),
              label: Text(AppLocalizations.of(context)!.openCreativeStudio),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purpleAccent,
                side: const BorderSide(color: Colors.purpleAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // REPORTS LM TRIGGER
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (campaign.clientId != null) {
                  ref.read(clientProvider.notifier).selectClient(campaign.clientId!);
                }
                context.push('/reports');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activating ReportsLM Agent Suite... Synthesizing Mind Map & Infographics.')));
              },
              icon: const Icon(Icons.assessment, color: Colors.white),
              label: const Text("Generate Full ReportsLM Suite"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.withValues(alpha: 0.2),
                foregroundColor: Colors.tealAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // PROPOSAL TRIGGER
          _buildProposalControl(context, ref, campaign),
        ],
      ),
    );
  }

  Widget _buildProposalControl(BuildContext context, WidgetRef ref, Campaign campaign) {
    final isLoading = ref.watch(proposalLoadingProvider(campaign.id));

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => _onGenerateProposal(context, ref, campaign),
            icon: isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.description, color: Colors.white),
            label: Text(isLoading ? "Generating Proposal..." : "Generate Client Proposal (PDF)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
              foregroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (campaign.proposals.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...campaign.proposals.map((url) => ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            title: const Text("Client Proposal (PDF)", style: TextStyle(color: Colors.white70, fontSize: 13)),
            trailing: IconButton(
              icon: const Icon(Icons.download, color: Colors.blueAccent),
              onPressed: () {
                 // In a real app, this would download the URL. 
                 // For demo, we might just re-trigger or show a success message.
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Proposal...')));
              },
            ),
          )),
        ],
      ],
    );
  }

  Future<void> _onGenerateProposal(BuildContext context, WidgetRef ref, Campaign campaign) async {
    ref.read(proposalLoadingProvider(campaign.id).notifier).state = true;
    try {
      // 1. Trigger Agent
      final agent = ProposalSpecialistAgent();
      final userBrief = "Generate a proposal for ${campaign.clientName} based on the campaign: ${campaign.title}. Description: ${campaign.description}";
      
      // Pull services from knowledge if available
      final knowledge = ref.read(knowledgeProvider);
      
      final result = await agent.execute(
        userPrompt: userBrief,
        context: knowledge,
        ref: ref,
      );

      // 2. Parse Result
      final proposalData = ProposalData.fromRawJson(result);

      // 3. Generate PDF
      final pdfBytes = await ProposalPdfService.generateProposalPdf(proposalData);

      // 4. "Save" (Mocking for now, in prod upload to Firebase Storage)
      final mockUrl = "proposals/proposal_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final updatedCampaign = campaign.copyWith(
        proposals: [...campaign.proposals, mockUrl]
      );
      
      await ref.read(campaignListProvider.notifier).updateCampaign(updatedCampaign);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal Generated Successfully!')));
        // Auto-Open for demo?
        await ProposalPdfService.saveAndOpenPdf(pdfBytes, "Inhaus_Proposal_${campaign.clientName}.pdf");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate proposal: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      ref.read(proposalLoadingProvider(campaign.id).notifier).state = false;
    }
  }
}

// Simple state provider for loading
final proposalLoadingProvider = StateProvider.family<bool, String>((ref, id) => false);
