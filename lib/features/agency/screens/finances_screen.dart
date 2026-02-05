import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/features/agency/models/agency_models.dart';
// import 'package:fl_chart/fl_chart.dart'; // Ensure this package is added or use custom painter/mock

class FinancesScreen extends StatelessWidget {
  const FinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Overview')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsGrid(context),
            const SizedBox(height: 32),
            _buildRevenueChart(context),
            const SizedBox(height: 32),
            _buildExpensesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final metrics = [
      FinanceMetric(
        label: 'Total Revenue',
        value: 142500,
        percentChange: 12.5,
        isPositiveTrend: true,
        icon: Icons.attach_money,
        color: Colors.green,
      ),
      FinanceMetric(
        label: 'Expenses',
        value: 45200,
        percentChange: 5.2,
        isPositiveTrend: false, // Expenses going up is bad, usually red, but here false means "bad trend"
        icon: Icons.money_off,
        color: Colors.red,
      ),
      FinanceMetric(
        label: 'Net Profit',
        value: 97300,
        percentChange: 15.8,
        isPositiveTrend: true,
        icon: FontAwesomeIcons.wallet,
        color: Colors.blue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 1 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) => _buildMetricCard(context, metrics[index]),
        );
      },
    );
  }

  Widget _buildMetricCard(BuildContext context, FinanceMetric metric) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(metric.icon, color: metric.color),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                     color: (metric.isPositiveTrend ? Colors.green : Colors.red).withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        metric.isPositiveTrend ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: metric.isPositiveTrend ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${metric.percentChange}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: metric.isPositiveTrend ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   metric.label, 
                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   '\$${metric.value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                 ),
               ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    // Placeholder chart container
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue Overview (Last 6 Months)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                 child: Text(
                   'Chart Visualization Area\n(Requires fl_chart implementation)',
                   textAlign: TextAlign.center,
                   style: TextStyle(color: Colors.grey[400]),
                 ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context) {
    final expenses = [
       {'category': 'Team Payroll', 'amount': 25000, 'date': 'Feb 01, 2026'},
       {'category': 'Software Subscriptions', 'amount': 3200, 'date': 'Feb 03, 2026'},
       {'category': 'Office Rent', 'amount': 4500, 'date': 'Feb 01, 2026'},
       {'category': 'Marketing Ad Spend', 'amount': 8500, 'date': 'Feb 04, 2026'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final exp = expenses[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  child: const Icon(Icons.receipt_long, color: Colors.red, size: 20),
                ),
                title: Text(exp['category'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(exp['date'] as String),
                trailing: Text(
                  '-\$${(exp['amount'] as int).toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
