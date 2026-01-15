import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.analyticsMonitor, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.campaignPerformance,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(),
          const SizedBox(height: 32),
          _buildChartsSection(),
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

  Widget _buildChartsSection() {
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
          Text(AppLocalizations.of(context)!.conversionOverTime, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Center(
             child: Icon(FontAwesomeIcons.chartLine, size: 48, color: Colors.blueAccent.withValues(alpha: 0.2)),
          ),
          const Spacer(),
          Text(AppLocalizations.of(context)!.historicalDataAggregated, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    );
  }
}
