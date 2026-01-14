import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/globals.dart';
import '../../workspace/models/app_models.dart';
import '../../workspace/providers/apps_provider.dart';
import '../../workspace/widgets/create_app_dialog.dart';

import '../../workspace/services/workflow_exchange_service.dart';

class WorkflowStartScreen extends ConsumerWidget {
  const WorkflowStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(appsProvider);
    // ... (filter logic)
    final workflows = apps.where((app) => 
      app.type == AppType.workflow || 
      app.type == AppType.chatflow || 
      app.type == AppType.agent ||
      app.type == AppType.textGenerator // Include text generators too
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, ref),
          SliverPadding(
            padding: const EdgeInsets.all(32),
            sliver: workflows.isEmpty 
              ? _buildEmptyState(context, ref)
              : _buildWorkflowGrid(context, ref, workflows),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF111111),
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        title: Row(
          children: [
            const Text(
              'Workflows',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.push('/pipelines'),
              icon: const Icon(Icons.build, size: 18, color: Colors.amberAccent),
              label: const Text('Legacy Builder', style: TextStyle(color: Colors.amberAccent)),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () async {
                final service = WorkflowExchangeService(ref);
                final success = await service.importApp();
                if (success && context.mounted) {
                   scaffoldMessengerKey.currentState?.showSnackBar(
                     const SnackBar(content: Text('Workflow imported successfully!'))
                   );
                }
              },
              icon: const Icon(Icons.upload_file, size: 18, color: Colors.white70),
              label: const Text('Import', style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.diagramProject, size: 64, color: Colors.white10),
            const SizedBox(height: 24),
            const Text(
              'No Workflows Yet',
              style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first automated process to get started.',
              style: TextStyle(color: Colors.white38),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _showCreateDialog(context),
              child: const Text('Create App'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                 final service = WorkflowExchangeService(ref);
                 await service.importApp();
              },
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Import App'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowGrid(BuildContext context, WidgetRef ref, List<App> workflows) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.4,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final workflow = workflows[index];
          return _buildWorkflowCard(context, ref, workflow);
        },
        childCount: workflows.length,
      ),
    );
  }

  Widget _buildWorkflowCard(BuildContext context, WidgetRef ref, App app) {
    return Card(
      color: const Color(0xFF1C2128),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
      child: InkWell(
        onTap: () => context.go('/app-editor?id=${app.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: app.type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(app.icon, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          app.type.displayName,
                          style: TextStyle(color: app.type.color, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Export Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white24),
                    color: const Color(0xFF2D333B),
                    onSelected: (value) {
                      if (value == 'export') {
                        final service = WorkflowExchangeService(ref);
                        try {
                          service.exportApp(app.id);
                          scaffoldMessengerKey.currentState?.showSnackBar(
                             SnackBar(content: Text('Exporting ${app.name}...')),
                          );
                        } catch (e) {
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(content: Text('Error: $e'))
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Export JSON', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                       const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Text(
                  app.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(color: Colors.white10, height: 24),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.white24),
                  const SizedBox(width: 4),
                  Text(
                    'Updated ${app.updatedAt.toString().split(' ')[0]}',
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.download, size: 16, color: Colors.white24),
                    tooltip: 'Export JSON',
                    onPressed: () {
                        final service = WorkflowExchangeService(ref);
                        try {
                          service.exportApp(app.id);
                          scaffoldMessengerKey.currentState?.showSnackBar(
                             SnackBar(content: Text('Exporting ${app.name}...')),
                          );
                        } catch (e) {
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(content: Text('Error: $e'))
                          );
                        }
                    },
                  ),
                  const Icon(Icons.play_circle_outline, size: 16, color: Colors.blueAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateAppDialog(),
    );
  }
}
