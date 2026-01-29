
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/connected_account_model.dart';
import '../services/connected_accounts_service.dart';

// Provider for fetching accounts
final connectedAccountsStreamProvider = StreamProvider.autoDispose<List<ConnectedAccount>>((ref) {
  final service = ConnectedAccountsService(); // Simple instance for now
  return service.getAccounts('client_1'); // TODO: Use real client ID
});

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(connectedAccountsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Data Connections", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.surface,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: accountsAsync.when(
        data: (accounts) => _buildBody(context, ref, accounts),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<ConnectedAccount> connectedAccounts) {
    // Define all available platforms
    final platforms = [
      _PlatformDef(AdPlatform.googleAds, "Google Ads", FontAwesomeIcons.google, Colors.blue),
      _PlatformDef(AdPlatform.googleAnalytics, "Google Analytics 4", FontAwesomeIcons.chartLine, Colors.orange),
      _PlatformDef(AdPlatform.metaAds, "Meta Ads (FB/IG)", FontAwesomeIcons.meta, Colors.blueAccent),
      _PlatformDef(AdPlatform.tiktokAds, "TikTok Ads", FontAwesomeIcons.tiktok, Colors.pinkAccent),
      _PlatformDef(AdPlatform.twitterAds, "X Ads", FontAwesomeIcons.xTwitter, Colors.white),
      _PlatformDef(AdPlatform.linkedinAds, "LinkedIn Ads", FontAwesomeIcons.linkedin, Colors.blue),
      _PlatformDef(AdPlatform.pinterestAds, "Pinterest Ads", FontAwesomeIcons.pinterest, Colors.red),
      _PlatformDef(AdPlatform.appleSearchAds, "Apple Search Ads", FontAwesomeIcons.apple, Colors.grey),
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          "Connect Your Data",
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Link your ad accounts to ingest campaigns, performance metrics, and insights automatically.",
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 32),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: platforms.length,
          itemBuilder: (context, index) {
            final p = platforms[index];
            final existingAccount = connectedAccounts.where((a) => a.platform == p.type).firstOrNull;
            return _ConnectionCard(platform: p, connectedAccount: existingAccount);
          },
        ),
      ],
    );
  }
}

class _PlatformDef {
  final AdPlatform type;
  final String name;
  final IconData icon;
  final Color color;
  _PlatformDef(this.type, this.name, this.icon, this.color);
}

class _ConnectionCard extends ConsumerWidget {
  final _PlatformDef platform;
  final ConnectedAccount? connectedAccount;

  const _ConnectionCard({required this.platform, this.connectedAccount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = connectedAccount != null && connectedAccount!.status == AccountStatus.active;

    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isConnected ? AppTheme.primary.withOpacity(0.5) : Colors.transparent)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(platform.icon, color: platform.color, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(platform.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                if (isConnected)
                  const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
              ],
            ),
            const Spacer(),
            if (isConnected) ...[
              Text("Connected: ${connectedAccount!.accountName}", style: const TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _disconnect(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  child: const Text("Disconnect"),
                ),
              )
            ] else ...[
              const Text("Not connected", style: TextStyle(color: Colors.white30, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _connect(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: platform.color.withOpacity(0.2),
                    foregroundColor: platform.color,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  child: const Text("Connect"),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    // Mock OAuth Flow
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connecting to ${platform.name}..."))); // Feedback
    
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Create a new connected account
    final newAccount = ConnectedAccount(
      id: const Uuid().v4(),
      clientId: 'client_1',
      platform: platform.type,
      accountName: "${platform.name} Account",
      externalAccountId: "act_${const Uuid().v4().substring(0,8)}",
      updatedAt: DateTime.now(),
      status: AccountStatus.active,
    );

    try {
      final service = ConnectedAccountsService();
      await service.saveAccount(newAccount);
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connected successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    if (connectedAccount == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Disconnect?", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to disconnect ${platform.name}? This will stop data syncing.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Disconnect", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
       final service = ConnectedAccountsService();
       await service.deleteAccount(connectedAccount!.id);
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Disconnected.")));
       }
    }
  }
}
