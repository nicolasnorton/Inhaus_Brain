import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import '../../core/auth/auth_service.dart';
import '../../features/auth/models/user_model.dart';
import '../assistant/widgets/ai_assistant_button.dart';
import '../assistant/widgets/ai_assistant_overlay.dart';
import '../../core/providers/demo_provider.dart';
import '../../features/knowledge/providers/knowledge_provider.dart';
import '../../core/config/feature_flags.dart';
import 'dart:ui';

class DashboardScreen extends ConsumerWidget {
  final Widget child;
  
  const DashboardScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final String location = GoRouterState.of(context).uri.toString();
        
        // Modules that have their own sidebar/navigation and should hide the global hamburger
        final bool hideGlobalHamburger = location.startsWith('/reports/') || 
                                       location.startsWith('/app-editor') ||
                                       location.startsWith('/workflow-canvas');

        return Scaffold(
          drawer: isMobile ? Drawer(
            width: 250,
            backgroundColor: Theme.of(context).cardColor,
            child: _buildSidebarContent(context, ref, isMobile: true),
          ) : null,
          body: Stack(
            children: [
              Row(
                children: [
                  // Desktop Sidebar
                  if (!isMobile)
                    Container(
                      width: 80,
                      color: Theme.of(context).brightness == Brightness.light 
                          ? Colors.black.withValues(alpha: 0.03) 
                          : Theme.of(context).cardColor.withValues(alpha: 0.3),
                      child: _buildSidebarContent(context, ref),
                    ),
                  
                  if (!isMobile)
                    const VerticalDivider(thickness: 1, width: 1),
                  
                  // Mobile Discrete Sidebar (Vertical Strip)
                  if (isMobile && !hideGlobalHamburger)
                    GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        width: 12,
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        child: Center(
                          child: Container(
                            width: 2,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Main Content Area
                  Expanded(
                    child: SafeArea(
                      left: false, // Sidebar handles its own spacing if needed
                      right: false,
                      bottom: false,
                      child: Stack(
                        children: [
                          child,
                          // Mobile Menu Trigger (Only if not hiding and not in a special module)
                          if (isMobile && !hideGlobalHamburger)
                            Positioned(
                              top: 12,
                              left: 16, // More breathing room
                              child: Builder(
                                builder: (context) => Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))
                                    ]
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.menu, size: 20),
                                    onPressed: () => Scaffold.of(context).openDrawer(),
                                    tooltip: 'Open Navigation',
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
    );
  }

  Widget _buildSidebarContent(BuildContext context, WidgetRef ref, {bool isMobile = false}) {
    return SafeArea(
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
            child: Consumer(
              builder: (context, ref, child) {
                final userAsync = ref.watch(appUserProvider);
                return userAsync.when(
                  data: (user) {
                    final isClient = user?.role == UserRole.clientUser;
                    return Column(
                      children: [
                        _buildNavItem(context, 0, FontAwesomeIcons.gaugeHigh, AppLocalizations.of(context)!.navDashboard, ref),
                        _buildNavItem(context, 1, FontAwesomeIcons.usersViewfinder, AppLocalizations.of(context)!.navClients, ref),
                        _buildNavItem(context, 2, FontAwesomeIcons.bullhorn, AppLocalizations.of(context)!.navCampaigns, ref),
                        _buildNavItem(context, 14, FontAwesomeIcons.palette, 'Designer Canvas', ref),
                        _buildNavItem(context, 3, FontAwesomeIcons.chartLine, AppLocalizations.of(context)!.navAnalytics, ref),
                        _buildNavItem(context, 4, FontAwesomeIcons.diagramProject, AppLocalizations.of(context)!.navWorkflows, ref), // Enabled for all
                        _buildNavItem(context, 5, FontAwesomeIcons.rocket, AppLocalizations.of(context)!.navPublish, ref), // Enabled for all
                        _buildNavItem(context, 6, FontAwesomeIcons.book, AppLocalizations.of(context)!.navKnowledge, ref), // Enabled for all
                        _buildNavItem(context, 10, FontAwesomeIcons.clipboardList, "Reports", ref),
                        _buildNavItem(context, 11, FontAwesomeIcons.building, "Agency", ref),
                        if (!isClient) _buildNavItem(context, 12, FontAwesomeIcons.wandMagicSparkles, "Composer", ref),
                        if (FeatureFlags.brainweaveEnabled) _buildNavItem(context, 13, FontAwesomeIcons.brain, "BrainWeave", ref),
                        _buildNavItem(context, 7, FontAwesomeIcons.gear, AppLocalizations.of(context)!.navSettings, ref),
                        if (!isClient) _buildNavItem(context, 8, FontAwesomeIcons.bug, AppLocalizations.of(context)!.navDebug, ref),
                        _buildNavItem(context, 9, FontAwesomeIcons.userShield, 'Admin', ref), // Enabled for all
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
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
    if (location.startsWith('/agency')) return 11;
    if (location.startsWith('/composer')) return 12;
    if (location.startsWith('/brainweave')) return 13;
    if (location.startsWith('/creative-canvas')) return 14;
    return 0;
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, WidgetRef ref) {
    final isSelected = _calculateSelectedIndex(context, ref) == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeTextColor = isDark ? Colors.white : Colors.black87;
    final inactiveTextColor = isDark ? Colors.white54 : Colors.black54;
    
    final activeBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.black.withValues(alpha: 0.05);
    final inactiveBgColor = Colors.transparent;
    
    return Semantics(
      label: 'Navigate to $label',
      selected: isSelected,
      button: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : inactiveBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () => _onItemTapped(index, context, ref),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Row(
                children: [
                  Icon(icon, color: isSelected ? activeTextColor : inactiveTextColor, size: 18),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? activeTextColor : inactiveTextColor,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
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
      case 11: // Added
        context.go('/agency');
        break;
      case 12:
        context.go('/composer');
        break;
      case 13:
        context.go('/brainweave');
        break;
      case 14:
        context.go('/creative-canvas');
        break;
    }
  }
}

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final appUserAsync = ref.watch(appUserProvider);
    final displayName = authUser?.displayName ?? 'Agent';

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
          appUserAsync.when(
            data: (appUser) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 600 ? 2 : (constraints.maxWidth < 900 ? 3 : 4);
                  final childAspectRatio = constraints.maxWidth < 600 ? 1.5 : 1.1;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                    children: [
                      if (true) ...[
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.usersViewfinder,
                          label: AppLocalizations.of(context)!.navClients,
                          onTap: () => context.go('/clients'),
                          imageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.bullhorn,
                          label: AppLocalizations.of(context)!.navCampaigns,
                          onTap: () => context.go('/campaigns'),
                          imageUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.palette,
                          label: 'Designer Canvas',
                          onTap: () => context.go('/creative-canvas'),
                          imageUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.building,
                          label: "Agency",
                          onTap: () => context.go('/agency'),
                          imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.chartLine,
                          label: AppLocalizations.of(context)!.navAnalytics,
                          onTap: () => context.go('/analytics'),
                          imageUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.diagramProject,
                          label: AppLocalizations.of(context)!.navWorkflows,
                          onTap: () => context.go('/workflows'),
                          imageUrl: 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.rocket,
                          label: AppLocalizations.of(context)!.navPublish,
                          onTap: () => context.go('/publish'),
                          imageUrl: 'https://images.unsplash.com/photo-1504608524841-42fe6f032b4b?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.book,
                          label: AppLocalizations.of(context)!.navKnowledge,
                          onTap: () => context.go('/knowledge'),
                          imageUrl: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.gear,
                          label: AppLocalizations.of(context)!.navSettings,
                          onTap: () => context.go('/settings'),
                          imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.clipboardList,
                          label: "Reports",
                          onTap: () => context.go('/reports'),
                          imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.wandMagicSparkles,
                          label: "Composer",
                          onTap: () => context.go('/composer'),
                          imageUrl: 'https://images.unsplash.com/photo-1536329583941-14287ec6fc4e?w=400&q=80',
                        ),
                        if (FeatureFlags.brainweaveEnabled)
                          _buildNavCard(
                            context,
                            icon: FontAwesomeIcons.brain,
                            label: "BrainWeave",
                            onTap: () => context.go('/brainweave'),
                            imageUrl: 'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=400&q=80',
                          ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.bug,
                          label: AppLocalizations.of(context)!.navDebug,
                          onTap: () => context.go('/debug'),
                          imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400&q=80',
                        ),
                        _buildNavCard(
                          context,
                          icon: FontAwesomeIcons.userShield,
                          label: "Admin",
                          onTap: () => context.go('/admin'),
                          imageUrl: 'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=400&q=80',
                        ),
                      ],
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading user data')),
          ),
          const SizedBox(height: 32),
          Text(
            "Demo Campaigns",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildGlassmorphicDemoButton(
            context,
            ref,
            title: "Banco del Austro – Full Strategy Campaign",
            clientKey: "banco del austro",
            icon: FontAwesomeIcons.buildingColumns,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 12),
          _buildGlassmorphicDemoButton(
            context,
            ref,
            title: "Bajaj Ecuador – Scooter Launch",
            clientKey: "bajaj",
            icon: FontAwesomeIcons.motorcycle,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 12),
          _buildGlassmorphicDemoButton(
            context,
            ref,
            title: "Nutrileche – Brand Refresh",
            clientKey: "nutrileche",
            icon: FontAwesomeIcons.glassWater,
            color: Colors.greenAccent,
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
    String? imageUrl,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).primaryColor;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : Colors.black.withValues(alpha: 0.1);
    
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          highlightColor: accentColor.withValues(alpha: 0.05),
          splashColor: accentColor.withValues(alpha: 0.1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              // Dark overlay
              if (imageUrl != null)
                Container(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              // Icon + Label
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(icon, size: 24, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicDemoButton(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String clientKey,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Activate Demo Mode
            ref.read(demoModeProvider.notifier).state = true;
            ref.read(knowledgeProvider.notifier).initDemoData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('🚀 Demo Mode Activated: $title'), backgroundColor: color),
            );
            // We pass the key as an extra so the wizard can prefill it
            context.go('/campaigns', extra: {'demoClientKey': clientKey});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
