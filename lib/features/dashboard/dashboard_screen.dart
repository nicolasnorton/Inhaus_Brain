import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import '../../core/auth/auth_service.dart';
import '../../features/auth/models/user_model.dart';
import '../assistant/widgets/ai_assistant_button.dart';
import '../assistant/widgets/ai_assistant_overlay.dart';

class DashboardScreen extends ConsumerWidget {
  final Widget child;
  
  const DashboardScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
            // Custom Scrollable Sidebar
            Container(
              width: 80,
              color: Theme.of(context).brightness == Brightness.light 
                  ? Colors.black.withValues(alpha: 0.03) 
                  : Theme.of(context).cardColor.withValues(alpha: 0.3),
              child: Column(
                children: [
                   Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.light 
                        ? 'assets/images/logo_light.png' 
                        : 'assets/images/logo.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) => 
                          Icon(FontAwesomeIcons.brain, color: Theme.of(context).primaryColor, size: 32),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildNavItem(context, 0, FontAwesomeIcons.gaugeHigh, AppLocalizations.of(context)!.navDashboard, ref),
                          _buildNavItem(context, 1, FontAwesomeIcons.usersViewfinder, AppLocalizations.of(context)!.navClients, ref),
                          _buildNavItem(context, 2, FontAwesomeIcons.bullhorn, AppLocalizations.of(context)!.navCampaigns, ref),
                          _buildNavItem(context, 3, FontAwesomeIcons.chartLine, AppLocalizations.of(context)!.navAnalytics, ref),
                          _buildNavItem(context, 4, FontAwesomeIcons.diagramProject, AppLocalizations.of(context)!.navWorkflows, ref),
                          _buildNavItem(context, 5, FontAwesomeIcons.rocket, AppLocalizations.of(context)!.navPublish, ref),
                          _buildNavItem(context, 6, FontAwesomeIcons.book, AppLocalizations.of(context)!.navKnowledge, ref),
                          _buildNavItem(context, 10, FontAwesomeIcons.clipboardList, "Reports", ref), // Index 10 for Reports
                          _buildNavItem(context, 7, FontAwesomeIcons.gear, AppLocalizations.of(context)!.navSettings, ref),
                          _buildNavItem(context, 8, FontAwesomeIcons.bug, AppLocalizations.of(context)!.navDebug, ref),
                          
                          // Admin Nav Item (Conditional)
                          Consumer(
                            builder: (context, ref, _) {
                              final userAsync = ref.watch(appUserProvider);
                              return userAsync.when(
                                data: (user) {
                                  if (user == null || (user.role != UserRole.superAdmin && user.role != UserRole.admin)) {
                                    return const SizedBox.shrink();
                                  }
                                  return _buildNavItem(context, 9, FontAwesomeIcons.userShield, 'Admin', ref);
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                          const SizedBox(height: 20), // Spacing at the end of scroll
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUserAvatar(context, ref),
                        const SizedBox(height: 16),
                        IconButton(
                          icon: Icon(Icons.logout, color: Theme.of(context).brightness == Brightness.light ? Colors.black54 : Colors.white54),
                          onPressed: () => ref.read(authServiceProvider).signOut(),
                          tooltip: AppLocalizations.of(context)!.logout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
              const VerticalDivider(thickness: 1, width: 1),
              // Main Content Area
              Expanded(
                child: child,
              ),
            ],
          ),
          
          // AI Assistant Overlay (Global)
          const AiAssistantOverlay(),
        ],
      ),
      floatingActionButton: const AiAssistantButton(),
    );
  }

  Widget _buildUserAvatar(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final roleName = user != null ? 'PRO' : 'GUEST';
    
    return Tooltip(
      message: AppLocalizations.of(context)!.loggedInAs(roleName),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
        child: ClipOval(
          child: (user?.photoURL != null) 
            ? Image.network(
                user!.photoURL!,
                fit: BoxFit.cover,
                width: 36,
                height: 36,
                errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(user, roleName),
              )
            : _buildAvatarFallback(user, roleName),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(dynamic user, String roleName) {
    return Text(
      (user?.displayName ?? user?.email ?? roleName)[0].toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
    );
  }

  int _calculateSelectedIndex(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.toString();
    
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/campaigns') || location.startsWith('/creative')) return 2;
    if (location.startsWith('/analytics') || location.startsWith('/monitor')) return 3;
    if (location.startsWith('/workflows') || location.startsWith('/workflow-canvas') || location.startsWith('/pipelines')) return 4;
    if (location.startsWith('/publish')) return 5;
    if (location.startsWith('/knowledge')) return 6;
    if (location.startsWith('/settings') || location.startsWith('/workspace')) return 7;
    if (location.startsWith('/debug')) return 8;
    if (location.startsWith('/admin')) return 9;
    if (location.startsWith('/reports')) return 10;
    return 0;
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, WidgetRef ref) {
    final isSelected = _calculateSelectedIndex(context, ref) == index;
    final color = isSelected 
        ? Theme.of(context).primaryColor 
        : (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54);
    
    return Semantics(
      label: 'Navigate to $label',
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () => _onItemTapped(index, context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          width: double.infinity,
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11, // Slightly smaller to fit
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        context.go('/analytics');
        break;
      case 4:
        context.go('/workflows');
        break;
      case 5:
        context.go('/publish');
        break;
      case 6:
        context.go('/knowledge');
        break;
      case 7:
        context.go('/settings');
        break;
      case 8:
        context.go('/debug');
        break;
      case 9:
        context.go('/admin');
        break;
      case 10:
        context.go('/reports');
        break;
    }
  }
}

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
          Text(
            AppLocalizations.of(context)!.welcomeBack(displayName),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.readyForCampaign,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.quickAccess,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
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
                    label: AppLocalizations.of(context)!.navClients,
                    onTap: () => context.go('/clients'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.bullhorn,
                    label: AppLocalizations.of(context)!.navCampaigns,
                    onTap: () => context.go('/campaigns'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.chartLine,
                    label: AppLocalizations.of(context)!.navAnalytics,
                    onTap: () => context.go('/analytics'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.diagramProject,
                    label: AppLocalizations.of(context)!.navWorkflows,
                    onTap: () => context.go('/workflows'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.rocket,
                    label: AppLocalizations.of(context)!.navPublish,
                    onTap: () => context.go('/publish'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.book,
                    label: AppLocalizations.of(context)!.navKnowledge,
                    onTap: () => context.go('/knowledge'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.gear,
                    label: AppLocalizations.of(context)!.navSettings,
                    onTap: () => context.go('/settings'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.clipboardList,
                    label: "Reports",
                    onTap: () => context.go('/reports'),
                  ),
                  _buildNavCard(
                    context,
                    icon: FontAwesomeIcons.bug,
                    label: AppLocalizations.of(context)!.navDebug,
                    onTap: () => context.go('/debug'),
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
              Icon(icon, size: 24, color: Theme.of(context).primaryColor),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
