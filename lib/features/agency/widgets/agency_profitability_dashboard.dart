import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/agency_service_model.dart';

class AgencyProfitabilityDashboard extends StatelessWidget {
  final List<AgencyService> services;

  const AgencyProfitabilityDashboard({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    // Filter services that have basePrice set (others are just catalog items)
    final analizableServices = services.where((s) => s.basePrice > 0).toList();

    if (analizableServices.isEmpty) {
      return const Center(child: Text("No services with price data to analyze", style: TextStyle(color: Colors.white54)));
    }

    final totalRevenue = analizableServices.fold<double>(0, (sum, s) => sum + s.basePrice);
    final totalCosts = analizableServices.fold<double>(0, (sum, s) => sum + s.deliveryCost);
    final totalProfit = totalRevenue - totalCosts;
    final avgMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            _buildStatCard("Total Portfolio Value", "\$${totalRevenue.toStringAsFixed(0)}", Icons.account_balance_wallet, Colors.blue),
            const SizedBox(width: 24),
            _buildStatCard("Total Delivery Costs", "\$${totalCosts.toStringAsFixed(0)}", Icons.money_off, Colors.red),
            const SizedBox(width: 24),
            _buildStatCard("Average Margin", "${avgMargin.toStringAsFixed(1)}%", Icons.trending_up, avgMargin >= 35 ? Colors.green : Colors.orange),
          ],
        ),
        const SizedBox(height: 32),
        const Text("SERVICE PROFITABILITY RANKING", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        _buildRankingTable(context, analizableServices),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingTable(BuildContext context, List<AgencyService> analizableServices) {
    // Helper to calculate margin for sorting
    double getMargin(AgencyService s) => s.basePrice > 0 ? ((s.basePrice - s.deliveryCost) / s.basePrice) * 100 : 0.0;
    
    final sortedServices = List<AgencyService>.from(analizableServices)
      ..sort((a, b) => getMargin(b).compareTo(getMargin(a)));

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text("SERVICE", style: TextStyle(color: Colors.white38))),
            DataColumn(label: Text("PRICE", style: TextStyle(color: Colors.white38))),
            DataColumn(label: Text("COST", style: TextStyle(color: Colors.white38))),
            DataColumn(label: Text("PROFIT", style: TextStyle(color: Colors.white38))),
            DataColumn(label: Text("MARGIN", style: TextStyle(color: Colors.white38))),
            DataColumn(label: Text("STATUS", style: TextStyle(color: Colors.white38))),
          ],
          rows: sortedServices.map((s) {
            final margin = getMargin(s);
            final profit = s.basePrice - s.deliveryCost;
            final isHealthy = margin >= s.targetMargin;
            
            return DataRow(
              cells: [
                DataCell(Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                DataCell(Text("\$${s.basePrice.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white))),
                DataCell(Text("\$${s.deliveryCost.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white70))),
                DataCell(Text("\$${profit.toStringAsFixed(0)}", style: const TextStyle(color: Colors.blue))),
                DataCell(Text("${margin.toStringAsFixed(1)}%", style: TextStyle(color: isHealthy ? Colors.green : Colors.orange, fontWeight: FontWeight.bold))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isHealthy ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isHealthy ? "OPTIMIZED" : "ATTENTION",
                      style: TextStyle(color: isHealthy ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
