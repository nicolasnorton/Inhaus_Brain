import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/analytics_providers.dart';
import '../../monitor/screens/monitor_dashboard_screen.dart';

class AnalyticsMonitorScreen extends ConsumerStatefulWidget {
  final String appId;
  const AnalyticsMonitorScreen({super.key, required this.appId});

  @override
  ConsumerState<AnalyticsMonitorScreen> createState() => _AnalyticsMonitorScreenState();
}

class _AnalyticsMonitorScreenState extends ConsumerState<AnalyticsMonitorScreen> with SingleTickerProviderStateMixin {
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

  void _refreshDashboard() {
     ref.invalidate(dashboardDataProvider('default_analytics'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.analyticsMonitor, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _refreshDashboard,
            tooltip: 'Regenerate Insights',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white60,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.tabBusinessAnalytics),
            Tab(text: AppLocalizations.of(context)!.tabSystemMonitor),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBusinessAnalytics(),
          MonitorDashboardScreen(appId: widget.appId),
        ],
      ),
    );
  }

  Widget _buildBusinessAnalytics() {
    final dashboardAsync = ref.watch(dashboardDataProvider('default_analytics'));

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  data['title'] ?? AppLocalizations.of(context)!.campaignPerformance,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 8),
                const Text('AI GENERATED', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 24),
            ... (data['components'] as List? ?? []).map((c) => _buildComponent(c)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildComponent(Map<String, dynamic> config) {
    final String type = config['type'] ?? 'unknown';
    
    switch (type) {
      case 'kpi':
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: _buildStatCard(
            config['label'] ?? 'KPI',
            config['value'] ?? '0',
            config['trend'] ?? '',
            config['status'] == 'positive' ? Colors.greenAccent : Colors.redAccent,
          ),
        );
      case 'chart':
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: _buildChartsSection(config),
        );
      case 'insight':
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: _buildInsightCard(config['text'] ?? ''),
        );
      case 'media':
        return Padding(
           padding: const EdgeInsets.only(bottom: 24.0),
           child: _buildMediaCard(config),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInsightCard(String markdown) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blueAccent, size: 16),
              SizedBox(width: 8),
              Text('STRATEGIC INSIGHT', style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: markdown,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(Map<String, dynamic> config) {
     return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Image.network(
              config['url'] ?? 'https://via.placeholder.com/600x300',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200, 
                color: Colors.white12, 
                child: const Center(child: Icon(Icons.image, color: Colors.white24))
              ),
            ),
            if (config['caption'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).cardColor,
                width: double.infinity,
                child: Text(config['caption'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
          ],
        ),
     );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildStatCard(AppLocalizations.of(context)!.statROI, '3.2x', '+12%', Colors.greenAccent),
        _buildStatCard(AppLocalizations.of(context)!.statConversion, '4.8%', '+0.5%', Colors.blueAccent),
        _buildStatCard(AppLocalizations.of(context)!.statCPA, '\$12.50', '-5%', Colors.orangeAccent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String change, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8), fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(change, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(Map<String, dynamic> config) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(config['label'] ?? AppLocalizations.of(context)!.conversionOverTime, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Center(
             child: Column(
               children: [
                 Icon(FontAwesomeIcons.chartLine, size: 48, color: Colors.blueAccent.withValues(alpha: 0.2)),
                 const SizedBox(height: 8),
                 Text('DYNAMIC CHART: ${config['chartType'] ?? 'LINE'}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
               ],
             ),
          ),
          const Spacer(),
          Text(AppLocalizations.of(context)!.historicalDataAggregated, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    );
  }
}
