import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'reports_dashboard_screen.dart';
import 'dashboards_grid.dart';
import '../../clients/providers/client_provider.dart';
import '../../clients/models/client_model.dart';

class ReportsMainScreen extends ConsumerStatefulWidget {
  const ReportsMainScreen({super.key});

  @override
  ConsumerState<ReportsMainScreen> createState() => _ReportsMainScreenState();
}

class _ReportsMainScreenState extends ConsumerState<ReportsMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showWalkthrough(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Analytics Hub Guide", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStep("1. Data Connections", "Link your Google Ads, Meta, or TikTok accounts via the 'Data Connections' button."),
                _buildStep("2. Create a Report", "Go to the 'Reports' tab and click 'New Report'."),
                _buildStep("3. Add Sources", "Inside your report, add Files, Web URLs, or Paste Text for analysis."),
                _buildStep("4. Generate Insights", "Use the Studio panel to create Audio podcasts, Video previews, or Mind Maps."),
                _buildStep("5. Dashboards", "Monitor live performance in the 'Dashboards' tab."),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!")),
        ],
      ),
    );
  }

  Widget _buildStep(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final selectedClient = ref.watch(selectedClientProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Analytics Hub", style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(width: 24),
            // Client Selector Logic
            if (clientState.clients.isNotEmpty)
              DropdownButton<String>(
                value: selectedClient?.id,
                hint: const Text('Select Client', style: TextStyle(color: Colors.white70)),
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: Colors.white),
                underline: Container(height: 1, color: Colors.white24),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    ref.read(clientProvider.notifier).selectClient(newValue);
                  }
                },
                items: clientState.clients.map<DropdownMenuItem<String>>((Client client) {
                  return DropdownMenuItem<String>(
                    value: client.id,
                    child: Text(client.name),
                  );
                }).toList(),
              ),
          ],
        ),
        backgroundColor: AppTheme.surface,
        centerTitle: false,
        actions: [

           IconButton(
             icon: const Icon(Icons.help_outline, color: Colors.white70),
             onPressed: () => _showWalkthrough(context),
             tooltip: "User Guide",
           ),
           Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: OutlinedButton.icon(
               icon: const Icon(Icons.link, size: 16),
               label: const Text("Data Connections"),
               style: OutlinedButton.styleFrom(
                 foregroundColor: Colors.white, 
                 side: const BorderSide(color: Colors.white24)
               ),
               onPressed: () => context.go('/reports/connections'), 
             ),
           )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Reports"),
            Tab(text: "Dashboards"),
          ],
        ),
      ),
      body: selectedClient == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.domain_disabled, size: 64, color: Colors.white24),
                   const SizedBox(height: 16),
                   const Text("No Client Selected", style: TextStyle(color: Colors.white54, fontSize: 20)),
                   const SizedBox(height: 8),
                   const Text("Please select a client from the top bar to view reports.", style: TextStyle(color: Colors.white24)),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: const [
                ReportsDashboardScreen(),
                DashboardsGrid(),
              ],
            ),
    );
  }
}
