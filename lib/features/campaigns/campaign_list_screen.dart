import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'package:inhaus_brain/features/campaigns/providers/campaign_provider.dart';
import 'package:inhaus_brain/features/campaigns/models/campaign.dart';

class CampaignListScreen extends ConsumerWidget {
  const CampaignListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = ref.watch(campaignListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let background shine through
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.campaignsTitle),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: AppLocalizations.of(context)!.creativeStudio,
            onPressed: () => context.go('/creative'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: AppLocalizations.of(context)!.newCampaign,
            onPressed: () => context.go('/campaigns/create'),
          ),
        ],
      ),
      body: campaigns.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch, size: 64, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noActiveCampaigns),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/campaigns/create'),
                    child: Text(AppLocalizations.of(context)!.createNewCampaign),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: campaigns.length,
              itemBuilder: (context, index) {
                final campaign = campaigns[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(
                      campaign.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(campaign.clientName ?? AppLocalizations.of(context)!.noClient),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusBadge(context, campaign.status),
                            const Spacer(),
                            Text(
                              AppLocalizations.of(context)!.createdOn(campaign.createdAt.toString().split(' ')[0]),
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/campaigns/${campaign.id}'),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, CampaignStatus status) {
    Color color;
    String label;
    switch (status) {
      case CampaignStatus.researching:
        color = Colors.blue;
        label = AppLocalizations.of(context)!.statusResearching;
        break;
      case CampaignStatus.designing:
        color = Colors.purple;
        label = AppLocalizations.of(context)!.statusDesigning;
        break;
      case CampaignStatus.inProduction:
        color = Colors.orange;
        label = AppLocalizations.of(context)!.statusInProduction;
        break;
      case CampaignStatus.published:
        color = Colors.green;
        label = AppLocalizations.of(context)!.statusPublished;
        break;
      default:
        color = Colors.grey;
        label = status.toString().split('.').last;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
