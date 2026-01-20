import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
// Note: In a real app we'd import fl_chart or similar. For now, we mock visual containers.

class ReportsVisualView extends ConsumerWidget {
  const ReportsVisualView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Live Dashboard", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text("Data Source: ", style: TextStyle(color: Colors.white54)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: const Text("BigQuery", style: TextStyle(color: Colors.blue, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              const Text("Last Updated: Just now", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 32),
          
          // Scorecards Row
          Row(
            children: [
              Expanded(child: _buildScorecard("Total Spend", "\$45,230", "+5%")),
              const SizedBox(width: 16),
              Expanded(child: _buildScorecard("Impressions", "2.1M", "+12%")),
              const SizedBox(width: 16),
              Expanded(child: _buildScorecard("CPC", "\$0.45", "-2%")),
              const SizedBox(width: 16),
              Expanded(child: _buildScorecard("ROAS", "3.2x", "+0.1")),
            ],
          ),
          const SizedBox(height: 24),
          
          // Charts Row 1
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildChartPlaceholder("Engagement Over Time", Icons.show_chart),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _buildChartPlaceholder("Audience Demographics", Icons.pie_chart),
              ),
            ],
          ),
          const SizedBox(height: 24),
           
          // Charts Row 2
          Row(
            children: [
              Expanded(
                child: _buildChartPlaceholder("Funnel Analysis", Icons.bar_chart),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildChartPlaceholder("Regional Performance", Icons.map),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScorecard(String title, String value, String trend) {
    final isPositive = !trend.startsWith('-');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? Colors.green : Colors.red, size: 14),
              const SizedBox(width: 4),
              Text(trend, style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Text("vs last 30 days", style: TextStyle(color: Colors.white30, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(String title, IconData icon) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 Icon(Icons.more_horiz, color: Colors.white54),
               ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: Colors.white10),
                  const SizedBox(height: 12),
                  const Text("Chart Visualization", style: TextStyle(color: Colors.white24)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
