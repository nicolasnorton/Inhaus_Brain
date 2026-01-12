import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/app_models.dart';
import '../providers/apps_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/create_app_dialog.dart';

/// Main screen for managing apps
class ManageAppsScreen extends ConsumerStatefulWidget {
  const ManageAppsScreen({super.key});

  @override
  ConsumerState<ManageAppsScreen> createState() => _ManageAppsScreenState();
}

class _ManageAppsScreenState extends ConsumerState<ManageAppsScreen> {
  String _searchQuery = '';

  void _showEditDialog(App app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit App Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'App Name'),
              controller: TextEditingController(text: app.name),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              controller: TextEditingController(text: app.description),
              maxLines: 3,
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
              Navigator.pop(context);
              _showSnackBar('App updated successfully');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDuplicateDialog(App app) {
    final controller = TextEditingController(text: '${app.name} (Copy)');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate App'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New App Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(appsProvider.notifier).duplicateApp(app.id, controller.text);
              Navigator.pop(context);
              _showSnackBar('App duplicated successfully');
            },
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(App app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export DSL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export this app as a DSL file (YAML format).'),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Include secret environment variables'),
              subtitle: const Text('Be careful with sensitive information'),
              value: false,
              onChanged: (value) {},
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
              Navigator.pop(context);
              _showSnackBar('DSL exported successfully');
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(App app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${app.name}"?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will permanently delete:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  Text('• All app configurations and prompts', style: TextStyle(fontSize: 12)),
                  Text('• Workflow orchestration and settings', style: TextStyle(fontSize: 12)),
                  Text('• Usage logs and analytics', style: TextStyle(fontSize: 12)),
                  Text('• Published web apps and API access', style: TextStyle(fontSize: 12)),
                  Text('• All user conversations and data', style: TextStyle(fontSize: 12)),
                ],
              ),
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
              ref.read(appsProvider.notifier).deleteApp(app.id);
              Navigator.pop(context);
              _showSnackBar('App deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apps = ref.watch(filteredAppsProvider);
    final viewMode = ref.watch(appViewModeProvider);
    final sortBy = ref.watch(appSortProvider);

    // Filter by search query
    final filteredApps = _searchQuery.isEmpty
        ? apps
        : apps.where((app) {
            return app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                app.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                app.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
          }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.layerGroup,
                  color: theme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Apps',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Organize, maintain, and share your AI applications',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const CreateAppDialog(),
                  ),
                  icon: const Icon(FontAwesomeIcons.plus),
                  label: const Text('New App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Search
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search apps...',
                      prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Filter by type
                DropdownButton<AppType?>(
                  hint: const Text('All Types'),
                  value: ref.watch(appFilterProvider)?.type,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...AppType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    ref.read(appFilterProvider.notifier).state =
                        value != null ? AppFilter(type: value) : null;
                  },
                ),
                const SizedBox(width: 16),
                // Sort
                DropdownButton<AppSortBy>(
                  value: sortBy,
                  items: AppSortBy.values.map((sort) {
                    return DropdownMenuItem(
                      value: sort,
                      child: Text('Sort: ${sort.displayName}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(appSortProvider.notifier).state = value;
                    }
                  },
                ),
                const SizedBox(width: 16),
                // View mode toggle
                IconButton(
                  icon: Icon(
                    viewMode == AppViewMode.grid
                        ? FontAwesomeIcons.list
                        : FontAwesomeIcons.grip,
                  ),
                  onPressed: () {
                    ref.read(appViewModeProvider.notifier).state =
                        viewMode == AppViewMode.grid
                            ? AppViewMode.list
                            : AppViewMode.grid;
                  },
                  tooltip: viewMode == AppViewMode.grid ? 'List View' : 'Grid View',
                ),
              ],
            ),
          ),
          // Apps grid/list
          Expanded(
            child: filteredApps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.magnifyingGlass,
                          size: 64,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No apps found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  )
                : viewMode == AppViewMode.grid
                    ? GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          return AppCard(
                            app: app,
                            isGridView: true,
                            onEdit: () => _showEditDialog(app),
                            onDuplicate: () => _showDuplicateDialog(app),
                            onExport: () => _showExportDialog(app),
                            onDelete: () => _showDeleteDialog(app),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          return AppCard(
                            app: app,
                            isGridView: false,
                            onEdit: () => _showEditDialog(app),
                            onDuplicate: () => _showDuplicateDialog(app),
                            onExport: () => _showExportDialog(app),
                            onDelete: () => _showDeleteDialog(app),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
