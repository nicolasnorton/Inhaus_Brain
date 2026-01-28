import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import '../../core/auth/auth_service.dart';
import 'providers/client_provider.dart';
import 'models/client_model.dart';
import '../auth/models/user_model.dart';

class ClientManagementScreen extends ConsumerWidget {
  const ClientManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allClients = ref.watch(clientProvider);
    final appUserAsync = ref.watch(appUserProvider);
    // Since isAdmin is also async in strict logic, we might need a better pattern. 
    // But for now, we will wait for appUser to be loaded.
    
    return appUserAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (appUser) {
         return _buildContent(context, ref, allClients, appUser);
      },
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Client> allClients, AppUser? appUser) {
    // Note: This relies on authServiceProvider.isAdmin which might also need to become AsyncValue if it depends on FS
    // But currentUser is synchronous if already loaded. 
    // Let's rely on appUser role check directly since we have the object.
    
    final isAdmin = appUser?.role == UserRole.admin || appUser?.role == UserRole.superAdmin;
    debugPrint('ClientManagementScreen: User=${appUser?.email}, Role=${appUser?.role}, IsAdmin=$isAdmin');

    final clients = isAdmin 
      ? allClients 
      : allClients.where((c) => appUser?.assignedClientIds.contains(c.id) ?? false).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.clientModule,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.portfolioManagement,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => _showAddClientDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.addClient),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 48),
              Expanded(
                child: clients.isEmpty
                    ? _buildEmptyState(context)
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: clients.length,
                        itemBuilder: (context, index) => _buildClientCard(context, clients[index], ref),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.usersViewfinder, size: 64, color: Colors.white10),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noClientsConfigured,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5) ?? Colors.white54, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, Client client, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const FaIcon(FontAwesomeIcons.building, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      client.industry,
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const Divider(color: Colors.black12),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.campaignsCountLabel,
                    style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  Text(
                    '${client.campaignIds.length}',
                    style: TextStyle(color: Theme.of(context).textTheme.headlineSmall?.color, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.go('/clients/${client.id}');
                },
                child: Text(AppLocalizations.of(context)!.manageClient),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddClientDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final industryController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(AppLocalizations.of(context)!.addNewClient),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.clientNameLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: industryController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.industryLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.contactEmail),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(clientProvider.notifier).addClient(
                nameController.text,
                industryController.text,
                email: emailController.text,
              );
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.addClient),
          ),
        ],
      ),
    );
  }
}
