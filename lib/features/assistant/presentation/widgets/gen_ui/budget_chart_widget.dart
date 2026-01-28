import 'package:flutter/material.dart';

class BudgetChartWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const BudgetChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Budget Breakdown';
    final totalBudget = data['total_budget'] is num ? (data['total_budget'] as num).toDouble() : 1.0;
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);

    // Calculate max amount for scaling if total not provided or to verify
    double calculatedTotal = 0;
    for (var i in items) {
      calculatedTotal += (i['amount'] as num?)?.toDouble() ?? 0;
    }
    final effectiveTotal = totalBudget > 0 ? totalBudget : (calculatedTotal > 0 ? calculatedTotal : 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128), // Dark surface
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('\$${effectiveTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final label = item['label'] ?? 'Unknown';
            final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
            final percentage = (amount / effectiveTotal).clamp(0.0, 1.0);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('\$${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent, // Could use item['color'] if parsed
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
