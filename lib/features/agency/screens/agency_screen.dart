import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AgencyScreen extends ConsumerWidget {
  const AgencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Headquarters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildNavigationGrid(context),
            const SizedBox(height: 32),
            _buildQuickStats(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Director.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your agency operations, sales, and team from one central hub.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildNavigationGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 1 : 3;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildNavCard(
              context,
              title: 'Sales & CRM',
              subtitle: 'Manage leads, proposals, and marketing.',
              icon: FontAwesomeIcons.bullseye,
              color: Colors.blueAccent,
              onTap: () => context.go('/agency/sales'),
            ),
            _buildNavCard(
              context,
              title: 'Finances',
              subtitle: 'Track revenue, expenses, and profit.',
              icon: FontAwesomeIcons.chartPie,
              color: Colors.green,
              onTap: () => context.go('/agency/finances'),
            ),
            _buildNavCard(
              context,
              title: 'HR & Team',
              subtitle: 'Manage agents and employees.',
              icon: FontAwesomeIcons.peopleGroup,
              color: Colors.orange,
              onTap: () => context.go('/agency/hr'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'At a Glance',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                label: 'This Month Revenue',
                value: '\$142,500',
                trend: '+12%',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Active Leads',
                value: '24',
                trend: '+4',
                isPositive: true,
              ),
            ),
             if (MediaQuery.of(context).size.width > 600) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    label: 'Team Utilization',
                    value: '87%',
                    trend: '-2%',
                    isPositive: false,
                  ),
                ),
             ]
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required String trend,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
