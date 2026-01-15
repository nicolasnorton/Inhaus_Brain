import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_service.dart';
import '../../auth/models/user_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Basic protection (Router should also handle this)
    final userAsync = ref.watch(appUserProvider);
    
    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error loading admin profile'))),
      data: (user) {
        if (user == null || (user.role != UserRole.superAdmin && user.role != UserRole.admin)) {
          return const Scaffold(body: Center(child: Text('Access Denied')));
        }

        final theme = Theme.of(context);
        final isSuperAdmin = user.role == UserRole.superAdmin;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
             backgroundColor: theme.scaffoldBackgroundColor,
             title: const Text('Admin Console'),
             elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _AdminCard(
                  title: 'User Management',
                  icon: FontAwesomeIcons.users,
                  color: Colors.blue,
                  onTap: () {
                    // TODO: Navigate to User Management
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming Soon: User Management')));
                  },
                ),
                if (isSuperAdmin)
                  _AdminCard(
                    title: 'System Secrets',
                    subtitle: 'Manage global API keys',
                    icon: FontAwesomeIcons.key,
                    color: Colors.redAccent,
                    onTap: () => context.push('/admin/system-secrets'),
                  ),
                _AdminCard(
                  title: 'System Analytics',
                  icon: FontAwesomeIcons.chartLine,
                  color: Colors.green,
                  onTap: () {},
                ),
                 _AdminCard(
                  title: 'Audit Logs',
                  icon: FontAwesomeIcons.listCheck,
                  color: Colors.orange,
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
