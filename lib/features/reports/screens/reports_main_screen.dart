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


  Future<void> _createTestClient() async {
    try {
      await ref.read(clientProvider.notifier).addClient(
        name: "Test Client",
        clientType: ClientType.corporate,
        industry: "Technology",
        description: "Auto-generated test client for reports testing.",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Test Client Created & Selected!"), backgroundColor: Colors.green),
        );
        // Auto-select the new client
        final clients = ref.read(clientProvider).clients;
        if (clients.isNotEmpty) {
           ref.read(clientProvider.notifier).selectClient(clients.last.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create test client: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final selectedClient = ref.watch(selectedClientProvider);

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: isMobile 
          ? const Text("Analytics Hub", style: TextStyle(color: Colors.white, fontSize: 16))
          : Row(
              children: [
                const Text("Analytics Hub", style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(width: 24),
                // Client Selector Logic
                if (clientState.clients.isNotEmpty)
                  _buildClientSelector(selectedClient, clientState)
                else
                  TextButton.icon(
                    onPressed: _createTestClient,
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 16),
                    label: const Text("Seed Test Client", style: TextStyle(color: AppTheme.primary)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
        backgroundColor: AppTheme.surface,
        centerTitle: false,
        actions: [
            // ... (rest of actions)
           if (!isMobile)
             IconButton(
               icon: const Icon(Icons.help_outline, color: Colors.white70),
               onPressed: () => _showWalkthrough(context),
               tooltip: "User Guide",
             ),
           Padding(
             padding: const EdgeInsets.only(right: 8.0),
             child: OutlinedButton.icon(
               icon: const Icon(Icons.link, size: 14),
               label: Text(isMobile ? "Data" : "Data Connections", style: const TextStyle(fontSize: 12)),
               style: OutlinedButton.styleFrom(
                 foregroundColor: Colors.white, 
                 side: const BorderSide(color: Colors.white24),
                 padding: const EdgeInsets.symmetric(horizontal: 12),
               ),
               onPressed: () => context.go('/reports/connections'), 
             ),
           )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 100 : 48),
          child: Column(
            children: [
              if (isMobile && clientState.clients.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildClientSelector(selectedClient, clientState, isFullWidth: true),
                  ),
                ),
              TabBar(
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
            ],
          ),
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

  Widget _buildClientSelector(Client? selectedClient, dynamic clientState, {bool isFullWidth = false}) {
    return DropdownButton<String>(
      value: selectedClient?.id,
      hint: const Text('Select Client', style: TextStyle(color: Colors.white70)),
      dropdownColor: AppTheme.surface,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      underline: isFullWidth ? const SizedBox.shrink() : Container(height: 1, color: Colors.white24),
      isExpanded: isFullWidth,
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
    );
  }
}
