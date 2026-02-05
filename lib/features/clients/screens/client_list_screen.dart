import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'package:inhaus_brain/core/auth/auth_service.dart';
import '../providers/client_provider.dart';
import '../models/client_model.dart';
import 'package:inhaus_brain/features/auth/models/user_model.dart';

class ClientListScreen extends ConsumerWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientState = ref.watch(clientProvider);
    final appUserAsync = ref.watch(appUserProvider);

    return appUserAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (appUser) {
         return _buildContent(context, ref, clientState.clients, appUser, clientState.isLoading);
      },
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Client> allClients, AppUser? appUser, bool isLoading) {
    final isAdmin = appUser?.role == UserRole.admin || appUser?.role == UserRole.superAdmin;
    
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
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
                          fontSize: MediaQuery.of(context).size.width < 600 ? 24 : null,
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await context.push<bool>('/clients/new');
                        if (result == true) {
                          // Optional: Manually refresh
                        }
                      },
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
              if (isLoading && clients.isEmpty)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 1100 ? 2 : 3);
                      return clients.isEmpty
                          ? _buildEmptyState(context)
                          : GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: crossAxisCount == 1 ? 1.5 : 1.2,
                              ),
                              itemCount: clients.length,
                              itemBuilder: (context, index) => _buildClientCard(context, clients[index], ref),
                            );
                    },
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
                child: FaIcon(
                  client.clientType == ClientType.corporate ? FontAwesomeIcons.building : FontAwesomeIcons.userTie,
                  color: Colors.blueAccent, 
                  size: 20
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  ref.read(clientProvider.notifier).selectClient(client.id);
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
}
