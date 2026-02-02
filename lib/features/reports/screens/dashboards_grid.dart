import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/dashboard_model.dart';
import '../services/dashboards_service.dart';
import '../../clients/providers/client_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class DashboardsGrid extends ConsumerWidget {
  const DashboardsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardsAsync = ref.watch(dashboardsStreamProvider);

    return CustomScrollView(
      slivers: [
        // Header
        SliverPadding(
          padding: const EdgeInsets.all(32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dashboards",
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Visual insights and real-time monitoring.",
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          ),
        ),

        // Permanent Looker Studio Section
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Key Metrics", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 16 / 5,
                  child: Row(
                    children: [
                      Expanded(child: _buildLookerPlaceholder("Campaign Performance", Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildLookerPlaceholder("User Engagement", Colors.purple)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildLookerPlaceholder("ROI Analysis", Colors.green)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),

        // Custom Dashboards Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          sliver: SliverToBoxAdapter(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text("Custom Dashboards", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 16),
               ],
             ),
          ),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          sliver: dashboardsAsync.when(
            data: (dashboards) => SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) return _buildNewDashboardCard(context, ref);
                  final dashboard = dashboards[index - 1];
                  return _buildDashboardCard(dashboard);
                },
                childCount: dashboards.length + 1, 
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
            error: (err, stack) => SliverToBoxAdapter(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
          ),
        ),
        
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  Widget _buildLookerPlaceholder(String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.chartSimple, color: color, size: 32),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Looker Studio Widget", style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildNewDashboardCard(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24, style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: () => _showCreateDashboardDialog(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white10,
              child: Icon(Icons.add, color: AppTheme.primary, size: 32),
            ),
            SizedBox(height: 16),
            Text("New Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showCreateDashboardDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Create New Dashboard", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(
               controller: nameController,
               decoration: const InputDecoration(
                 hintText: "Dashboard Name",
                 hintStyle: TextStyle(color: Colors.white30),
                 enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
               ),
               style: const TextStyle(color: Colors.white),
             ),
             const SizedBox(height: 24),
             const Text("Generative AI can build your dashboard layout automatically.", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (nameController.text.isNotEmpty) {
                 final clientState = ref.read(clientProvider); // Get current state
                 final String clientId = clientState.selectedClientId ?? 'unknown';

                 final newDash = Dashboard.create(title: nameController.text, clientId: clientId);
                 await ref.read(dashboardsServiceProvider).createDashboard(newDash);
                 
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text("Created '${newDash.title}'"), backgroundColor: AppTheme.primary),
                   );
                 }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(Dashboard dashboard) {
    return Card(
      color: AppTheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                     child: const Icon(FontAwesomeIcons.chartPie, color: Colors.teal, size: 16),
                  ),
                  const Icon(Icons.more_horiz, color: Colors.white30),
                ],
              ),
              const Spacer(),
              Text(
                dashboard.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              const Text(
                "Custom Layout",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                "Updated ${timeago.format(dashboard.updatedAt)}",
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
