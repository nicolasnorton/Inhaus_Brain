import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/globals.dart';
import '../../workspace/models/app_models.dart';
import '../../workspace/providers/apps_provider.dart';
import '../../workspace/widgets/create_app_dialog.dart';
import '../../workspace/services/workflow_exchange_service.dart';
import '../../workspace/data/app_templates_data.dart';
import '../../workspace/models/app_template.dart';

class WorkflowStartScreen extends ConsumerStatefulWidget {
  const WorkflowStartScreen({super.key});

  @override
  ConsumerState<WorkflowStartScreen> createState() => _WorkflowStartScreenState();
}

class _WorkflowStartScreenState extends ConsumerState<WorkflowStartScreen> {
  String _selectedCategory = 'My Apps';

  final List<String> _categories = [
    'My Apps',
    // Divider logic handled in builder
    'Retail',
    'Media & Entertainment',
    'Automotive & Logistics',
    'Financial Services',
    'Healthcare & Life Sciences',
    'Telecommunications',
    'Travel & Hospitality',
    'Manufacturing & Energy',
    'Public Sector',
    'Productivity',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Filter Content based on Selection
    List<Widget> contentGrid = [];
    bool isTemplates = false;

    if (_selectedCategory == 'My Apps') {
      final apps = ref.watch(appsProvider);
      final workflows = apps.where((app) => 
        app.type == AppType.workflow || 
        app.type == AppType.chatflow || 
        app.type == AppType.agent ||
        app.type == AppType.textGenerator
      ).toList();

      if (workflows.isEmpty) {
        contentGrid = [_buildEmptyState(context, ref)];
      } else {
        contentGrid = [
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildWorkflowCard(context, ref, workflows[index]),
              childCount: workflows.length,
            ),
          )
        ];
      }
    } else {
      // Show Blueprints for Category
      isTemplates = true;
      final allTemplates = AppTemplatesData.allTemplates;
      final filtered = allTemplates.where((t) {
        if (t.description.startsWith('$_selectedCategory:')) return true;
        if (_selectedCategory == 'Other' && !t.description.contains(':')) return true;
        return false;
      }).toList();

      contentGrid = [
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 350,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.2,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildTemplateCard(context, filtered[index]),
            childCount: filtered.length,
          ),
        )
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Color(0xFF161B22), // Darker sidebar
              border: Border(right: BorderSide(color: Colors.white10)),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (context, index) {
                if (index == 0) return const Divider(color: Colors.white10, height: 32);
                return const SizedBox(height: 4);
              },
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return ListTile(
                  title: Text(
                    category == 'My Apps' ? 'My Workflows' : category,
                    style: TextStyle(
                      color: isSelected ? Colors.blueAccent : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  leading: category == 'My Apps' 
                      ? Icon(Icons.dashboard_outlined, color: isSelected ? Colors.blueAccent : Colors.white54, size: 20)
                      : null, // Icons for categories?
                  selected: isSelected,
                  selectedTileColor: Colors.blueAccent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () => setState(() => _selectedCategory = category),
                  dense: true,
                );
              },
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, ref),
                SliverPadding(
                    padding: const EdgeInsets.all(32),
                    sliver: contentGrid.isNotEmpty 
                      ? contentGrid.first 
                      : const SliverToBoxAdapter(child: SizedBox.shrink())
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF111111),
      expandedHeight: 100, // Reduced height for cleaner look
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16), // Adjusted padding
        title: Row(
          children: [
            Text(
              _selectedCategory == 'My Apps' ? 'Workflows' : '$_selectedCategory Blueprints',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const Spacer(),
            if (_selectedCategory == 'My Apps') ...[
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
            ],
            // Always show Create App button
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
          ],
        ),
      ),
    );
  }

  // --- Handlers ---
  
  void _showCreateDialog(BuildContext context, {AppTemplate? template}) {
    showDialog(
      context: context,
      builder: (context) => CreateAppDialog(initialTemplate: template),
    );
  }

  // --- Widgets ---

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
                  // Menu...
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white24),
                    color: const Color(0xFF2D333B),
                    onSelected: (value) {
                      if (value == 'export') {
                        final service = WorkflowExchangeService(ref);
                        service.exportApp(app.id); 
                      }
                      if (value == 'delete') {
                         ref.read(appsProvider.notifier).deleteApp(app.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(children: [Icon(Icons.download, size: 16), SizedBox(width:8), Text('Export JSON', style: TextStyle(color:Colors.white))]),
                      ),
                       const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width:8), Text('Delete', style: TextStyle(color:Colors.red))]),
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
                   const Icon(Icons.play_circle_outline, size: 16, color: Colors.blueAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, AppTemplate template) {
    return Card(
      color: const Color(0xFF1C2128).withValues(alpha: 0.5), // Slightly different background
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
      child: InkWell(
        onTap: () => _showCreateDialog(context, template: template),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(template.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  template.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCreateDialog(context, template: template),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5)),
                    foregroundColor: Colors.blueAccent,
                  ),
                  child: const Text('Create'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
