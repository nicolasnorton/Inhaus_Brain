import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/features/auth/models/user_model.dart';
import 'package:inhaus_brain/features/auth/providers/auth_provider.dart';

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
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
              child: Image.asset(
                'assets/images/logo.png',
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) => 
                    Icon(FontAwesomeIcons.brain, color: Theme.of(context).primaryColor, size: 32),
              ),
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
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildUserAvatar(ref),
                      const SizedBox(height: 16),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white54),
                        onPressed: () => ref.read(authProvider.notifier).logout(),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  Widget _buildUserAvatar(WidgetRef ref) {
    final user = ref.watch(authProvider);
    final roleName = user?.role.name.toUpperCase() ?? 'USER';
    
    return Tooltip(
      message: 'Logged in as $roleName',
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white10,
        child: Text(
          roleName[0],
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
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
class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final roleName = _formatRoleName(user?.role);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome back, $roleName',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Inhaus Brain is ready for your next campaign.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  String _formatRoleName(UserRole? role) {
    if (role == null) return 'Agent';
    final name = role.name;
    return name[0].toUpperCase() + name.substring(1).replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}');
  }
}
