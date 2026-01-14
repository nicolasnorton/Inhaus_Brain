import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        title: const Text('Campaigns'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Creative Studio',
            onPressed: () => context.go('/creative'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Campaign',
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
                  const Text('No Active Campaigns'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/campaigns/create'),
                    child: const Text('Create New Campaign'),
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
                        Text(campaign.clientName ?? 'No Client'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusBadge(campaign.status),
                            const Spacer(),
                            Text(
                              'Created: ${campaign.createdAt.toString().split(' ')[0]}',
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

  Widget _buildStatusBadge(CampaignStatus status) {
    Color color;
    switch (status) {
      case CampaignStatus.researching:
        color = Colors.blue;
        break;
      case CampaignStatus.designing:
        color = Colors.purple;
        break;
      case CampaignStatus.inProduction:
        color = Colors.orange;
        break;
      case CampaignStatus.published:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
