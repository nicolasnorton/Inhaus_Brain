import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_service.dart';
import 'providers/client_provider.dart';
import 'models/client_model.dart';

class ClientManagementScreen extends ConsumerWidget {
  const ClientManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allClients = ref.watch(clientProvider);
    final appUser = ref.watch(appUserProvider);
    final isAdmin = ref.watch(authServiceProvider).isAdmin;
    debugPrint('ClientManagementScreen: User=${appUser?.email}, Role=${appUser?.role}, IsAdmin=$isAdmin');

    final clients = isAdmin 
      ? allClients 
      : allClients.where((c) => appUser?.assignedClientIds.contains(c.id) ?? false).toList();

    return Scaffold(
      backgroundColor: Colors.black,
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
                        'CLIENT MODULE',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Portfolio Management',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => _showAddClientDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Client'),
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
                    ? _buildEmptyState()
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.usersViewfinder, size: 64, color: Colors.white10),
          const SizedBox(height: 24),
          Text(
            'No clients configured yet.',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, Client client, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      client.industry,
                      style: const TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAMPAIGNS',
                    style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  Text(
                    '${client.campaignIds.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.go('/clients/${client.id}');
                },
                child: const Text('Manage Client'),
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
        backgroundColor: const Color(0xFF111111),
        title: const Text('Add New Client', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Client Name', labelStyle: TextStyle(color: Colors.white54)),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: industryController,
              decoration: const InputDecoration(labelText: 'Industry', labelStyle: TextStyle(color: Colors.white54)),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Contact Email', labelStyle: TextStyle(color: Colors.white54)),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Add Client'),
          ),
        ],
      ),
    );
  }
}
