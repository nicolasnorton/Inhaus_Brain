import 'package:flutter/material.dart';

/// A GenUI widget to display marketing intelligence and ad performance data.
class MarketingIntelligencePanel extends StatelessWidget {
  final Map<String, dynamic> data;

  const MarketingIntelligencePanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Expected data format from 'compare_platforms' or 'generate_marketing_report'
    final title = data['title'] as String? ?? 'Marketing Performance';
    final platformData = data['platformData'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A), // Dark Inhaus theme
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purpleAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.purpleAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (platformData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No performance data available.', style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: platformData.map((platform) {
                if (platform is! Map<String, dynamic>) return const SizedBox.shrink();
                
                final name = platform['platform']?.toString().toUpperCase() ?? 'UNKNOWN';
                final spend = platform['total_spend'] ?? platform['spend'] ?? 0;
                final roas = platform['roas'] ?? platform['purchase_roas'] ?? 0;
                final conversions = platform['total_conversions'] ?? platform['conversions'] ?? 0;

                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 12),
                      _buildMetricRow('Spend', '\$$spend'),
                      const SizedBox(height: 4),
                      _buildMetricRow('ROAS', '${roas}x'),
                      const SizedBox(height: 4),
                      _buildMetricRow('Conv.', '$conversions'),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
