import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/core/auth/auth_service.dart';

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
            selectedIndex: _calculateSelectedIndex(context, ref),
            onDestinationSelected: (int index) => _onItemTapped(index, context, ref),
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
            destinations: [
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.gaugeHigh),
                label: Text('Dashboard'),
              ),
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.usersViewfinder),
                label: Text('Clients'),
              ),
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.bullhorn),
                label: Text('Campaigns'),
              ),
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.wandMagicSparkles), // Agent/Creative
                label: Text('Creative'),
              ),
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.chartLine),
                label: Text('Analytics'),
              ),
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.diagramProject),
                label: Text('Workflows'),
              ),
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.rocket),
                label: Text('Publish'),
              ),
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.bug),
                label: Text('Debug'),
              ),
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.book),
                label: Text('Knowledge'),
              ),
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.briefcase),
                label: Text('Workspace'),
              ),
              const NavigationRailDestination(
                icon: Icon(FontAwesomeIcons.gear),
                label: Text('Settings'),
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
                        onPressed: () => ref.read(authServiceProvider).signOut(),
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
    final user = ref.watch(authStateProvider).value;
    final roleName = user != null ? 'PRO' : 'GUEST';
    
    return Tooltip(
      message: 'Logged in as $roleName',
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
        onBackgroundImageError: user?.photoURL != null 
          ? (e, s) => debugPrint('Dashboard Avatar Error: $e') 
          : null,
        child: user?.photoURL == null 
          ? Text(
              (user?.displayName ?? user?.email ?? roleName)[0].toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            )
          : null,
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.toString();
    
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/campaigns')) return 2;
    if (location.startsWith('/creative')) return 3;
    if (location.startsWith('/analytics')) return 4;
    if (location.startsWith('/workflow-canvas')) return 5;
    if (location.startsWith('/publish')) return 6;
    if (location.startsWith('/debug')) return 7;
    if (location.startsWith('/knowledge')) return 8;
    if (location.startsWith('/workspace')) return 9;
    if (location.startsWith('/settings')) return 10;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/clients');
        break;
      case 2:
        context.go('/campaigns');
        break;
      case 3:
        context.go('/creative');
        break;
      case 4:
        context.go('/analytics');
        break;
      case 5:
        context.go('/workflow-canvas');
        break;
      case 6:
        context.go('/publish');
        break;
      case 7:
        context.go('/debug');
        break;
      case 8:
        context.go('/knowledge');
        break;
      case 9:
        context.go('/workspace/model-providers');
        break;
      case 10:
        context.go('/settings');
        break;
    }
  }
}

// Enhanced dashboard home with navigation widgets
class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final displayName = user?.displayName ?? 'Agent';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Text(
            'Welcome back, $displayName',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inhaus Brain is ready for your next campaign.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 32),

          // Quick access cards
          Text(
            'Quick Access',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Grid of navigation cards - responsive
          LayoutBuilder(
            builder: (context, constraints) {
              // Use 4 columns on desktop (>1200px), 3 on smaller screens
              final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 3;
              
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.usersViewfinder,
                    label: 'Clients',
                    description: 'Manage your clients',
                    onTap: () => context.go('/clients'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.bullhorn,
                    label: 'Campaigns',
                    description: 'Create campaigns',
                    onTap: () => context.go('/campaigns'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.wandMagicSparkles,
                    label: 'Creative',
                    description: 'Design content',
                    onTap: () => context.go('/creative'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.chartLine,
                    label: 'Analytics',
                    description: 'View insights',
                    onTap: () => context.go('/analytics'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.diagramProject,
                    label: 'Workflows',
                    description: 'Build workflows',
                    onTap: () => context.go('/workflow-canvas'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.rocket,
                    label: 'Publish',
                    description: 'Deploy your apps',
                    onTap: () => context.go('/publish'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.bug,
                    label: 'Debug',
                    description: 'Test & debug',
                    onTap: () => context.go('/debug'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.book,
                    label: 'Knowledge',
                    description: 'Manage knowledge',
                    onTap: () => context.go('/knowledge'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.briefcase,
                    label: 'Workspace',
                    description: 'Configure workspace',
                    onTap: () => context.go('/workspace/model-providers'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.gear,
                    label: 'Settings',
                    description: 'Personal settings',
                    onTap: () => context.go('/settings'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
