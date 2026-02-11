import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/webhook_service.dart';

class IntegrationsSettingsScreen extends ConsumerWidget {
  const IntegrationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webhooks = ref.watch(webhooksStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Integrations & Webhooks', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Unified Webhooks',
              subtitle: 'Trigger external workflows in Make, Zapier, or Pabbly when events happen in InhausBrain.',
            ),
            const SizedBox(height: 20),
            _buildWebhookList(webhooks, ref, context),
            const SizedBox(height: 40),
            _buildSectionHeader(
              title: 'API Access',
              subtitle: 'Coming Soon: Manage API keys for direct programmatic access to InhausBrain agents.',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Center(
                child: Text('API Keys are currently in private beta.', style: TextStyle(color: Colors.white38)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWebhookDialog(context, ref),
        label: const Text('Add Webhook'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  Widget _buildWebhookList(AsyncValue<List<Webhook>> webhooks, WidgetRef ref, BuildContext context) {
    return webhooks.when(
      data: (list) {
        if (list.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Column(
              children: [
                Icon(Icons.webhook_outlined, size: 48, color: Colors.white12),
                SizedBox(height: 16),
                Text('No webhooks configured yet.', style: TextStyle(color: Colors.white24)),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final wh = list[index];
            return Card(
              color: Colors.white.withOpacity(0.03),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(wh.url, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(
                  'Events: ${wh.events.map((e) => e.name).join(", ")}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
                  onPressed: () => ref.read(webhookServiceProvider).deleteWebhook(wh.id),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
    );
  }

  void _showAddWebhookDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    List<WebhookEvent> selectedEvents = [WebhookEvent.campaignCreated];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Add New Webhook', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Webhook URL',
                  hintText: 'https://hooks.zapier.com/...',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Select Events', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: WebhookEvent.values.map((e) {
                  final isSelected = selectedEvents.contains(e);
                  return FilterChip(
                    label: Text(e.name, style: const TextStyle(fontSize: 10)),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) selectedEvents.add(e);
                        else selectedEvents.remove(e);
                      });
                    },
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedColor: Colors.blueAccent.withOpacity(0.2),
                    labelStyle: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white70),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (urlController.text.isNotEmpty) {
                  ref.read(webhookServiceProvider).createWebhook(
                    url: urlController.text,
                    events: selectedEvents,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

final webhooksStreamProvider = StreamProvider<List<Webhook>>((ref) {
  return ref.watch(webhookServiceProvider).streamWebhooks();
});
