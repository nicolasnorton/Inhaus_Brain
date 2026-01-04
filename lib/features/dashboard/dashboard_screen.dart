import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  final Widget child; // For nested navigation if using ShellRoute, but simplifying for now
  
  const DashboardScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (Navigation Rail) - Visible on larger screens or always for this "agentic console" feel
          NavigationRail(
            backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.3),
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (int index) => _onItemTapped(index, context),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Icon(FontAwesomeIcons.brain, color: Theme.of(context).primaryColor, size: 32),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.gaugeHigh),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.bullhorn),
                label: Text('Campaigns'),
              ),
              NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.wandMagicSparkles), // Agent/Creative
                label: Text('Creative'),
              ),
              NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.chartLine),
                label: Text('Analytics'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/campaigns')) return 1;
    if (location.startsWith('/creative')) return 2;
    if (location.startsWith('/analytics')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/campaigns');
        break;
      case 2:
        context.go('/creative');
        break;
      case 3:
        context.go('/analytics');
        break;
    }
  }
}

// Simple placeholder for the home view
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to Inhaus Brain',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Agentic Workflow Manager',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
