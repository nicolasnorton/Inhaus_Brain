import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/campaign.dart';
import 'providers/campaign_provider.dart';
import '../creative/providers/creative_provider.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignListProvider).firstWhere(
          (c) => c.id == campaignId,
          orElse: () => throw Exception('Campaign not found'),
        );

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
              'Agent Research Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review and approve insights gathered by the Research Agent.',
              style: TextStyle(color: Colors.white70),
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
                    await ref.read(creativeProvider.notifier).generateConceptForCampaign(
                      campaign.id,
                      campaign.title,
                    );
                  },
                  child: const Text('Proceed to Design Plan'),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Campaign Strategy Brief',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(campaign.description, style: const TextStyle(color: Colors.white),),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Client:', style: TextStyle(color: Colors.white54),),
              const SizedBox(width: 8),
              Text(campaign.clientName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold),),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, WidgetRef ref, Campaign campaign, ResearchInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(insight.content, style: const TextStyle(fontSize: 15),),
            ),
            const SizedBox(width: 16),
            if (insight.isApproved)
              const Icon(Icons.check_circle, color: Colors.green)
            else
              TextButton(
                onPressed: () {
                  final updatedInsights = campaign.insights.map((i) {
                    if (i.id == insight.id) return i.copyWith(isApproved: true);
                    return i;
                  }).toList();
                  ref.read(campaignListProvider.notifier).updateCampaign(
                        campaign.copyWith(insights: updatedInsights),
                      );
                },
                child: const Text('Approve'),
              ),
          ],
        ),
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
                'Design Phase Active',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('The Creative Agent has proposed visual directions for this campaign.'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/creative'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Open Creative Studio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purpleAccent,
                side: const BorderSide(color: Colors.purpleAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
