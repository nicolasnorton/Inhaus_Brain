import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../monitor/services/monitor_api_service.dart';
import '../../monitor/providers/monitor_provider.dart';
import '../../monitor/models/monitor_models.dart';

class SystemAnalyticsScreen extends ConsumerWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorService = ref.watch(monitorApiServiceProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: AppBar(
        title: const Text('System Analytics'),
        backgroundColor: const Color(0xFF0F1116),
        actions: [
          IconButton(icon: const Icon(Icons.download_outlined), onPressed: () {}, tooltip: 'Export Report'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Operational Overview'),
            const SizedBox(height: 16),
            FutureBuilder(
              future: monitorService.getMetricSummary('global'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
                final data = snapshot.data as MetricSummary;
                return GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildMetricCard('Total Messages', '${data.totalMessages}', Icons.message_outlined, Colors.blueAccent),
                    _buildMetricCard('Active Users', '${data.activeUsers}', Icons.people_outline, Colors.orangeAccent),
                    _buildMetricCard('Token Usage', '${(data.totalTokens / 1000).toStringAsFixed(1)}K', Icons.generating_tokens_outlined, Colors.purpleAccent),
                    _buildMetricCard('Est. Cost', '\$${data.estimatedCost.toStringAsFixed(2)}', Icons.monetization_on_outlined, Colors.greenAccent),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Traffic Trends (Last 7 Days)'),
            const SizedBox(height: 16),
            _buildChartPlaceholder(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildModelDistribution()),
                const SizedBox(width: 24),
                Expanded(child: _buildRecentActivityFeed()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Icon(icon, color: color.withOpacity(0.5), size: 18),
            ],
          ),
          Text(
            value, 
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(14, (index) {
          final height = 20 + (index * 5 % 70) + (index % 3 == 0 ? 30 : 0);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 12,
                height: height.toDouble(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blueAccent, Colors.blueAccent.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ).animate().scaleY(
                duration: Duration(milliseconds: 400 + (index * 50)),
                begin: 0,
                end: 1,
                curve: Curves.easeOutBack,
              ),
              const SizedBox(height: 8),
              Text('${8+index}', style: const TextStyle(color: Colors.white10, fontSize: 8)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildModelDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Model Distribution', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildPieRow('GPT-4o', 0.65, Colors.greenAccent),
          const SizedBox(height: 12),
          _buildPieRow('Claude 3.5', 0.25, Colors.orangeAccent),
          const SizedBox(height: 12),
          _buildPieRow('Gemini Pro', 0.10, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildPieRow(String name, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            Text('${(percent * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: Colors.white.withOpacity(0.05),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildRecentActivityFeed() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Alerts', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildAlertItem('High latency on Gemini endpoint', '2 min ago', Colors.orangeAccent),
          const Divider(color: Colors.white10, height: 24),
          _buildAlertItem('Successful deployment: build_v1.2.4', '15 min ago', Colors.greenAccent),
          const Divider(color: Colors.white10, height: 24),
          _buildAlertItem('Rate limit warning for user_942', '1 hour ago', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String time, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Text(time, style: const TextStyle(color: Colors.white10, fontSize: 10)),
      ],
    );
  }
}
