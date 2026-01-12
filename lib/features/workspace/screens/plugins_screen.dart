import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/plugin_models.dart';
import '../providers/plugins_provider.dart';
import '../widgets/plugin_card.dart';
import '../widgets/plugin_config_dialog.dart';

/// Main screen for managing plugins
class PluginsScreen extends ConsumerStatefulWidget {
  const PluginsScreen({super.key});

  @override
  ConsumerState<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends ConsumerState<PluginsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PluginType? _selectedType;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showInstallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install Plugin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(FontAwesomeIcons.store),
              title: const Text('From Marketplace'),
              subtitle: const Text('Official and partner plugins'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Marketplace installation coming soon');
              },
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.github),
              title: const Text('From GitHub'),
              subtitle: const Text('Install from repository URL'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('GitHub installation coming soon');
              },
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.upload),
              title: const Text('Local Upload'),
              subtitle: const Text('Upload .zip package'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Local upload coming soon');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _installPlugin(Plugin plugin) {
    ref.read(installedPluginsProvider.notifier).installPlugin(plugin);
    _showSnackBar('${plugin.name} installed successfully');
  }

  void _removePlugin(Plugin plugin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Plugin'),
        content: Text('Are you sure you want to remove ${plugin.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(installedPluginsProvider.notifier).uninstallPlugin(plugin.id);
              Navigator.pop(context);
              _showSnackBar('${plugin.name} removed');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _updatePlugin(Plugin plugin) {
    if (plugin.latestVersion != null) {
      ref
          .read(installedPluginsProvider.notifier)
          .updatePlugin(plugin.id, plugin.latestVersion!);
      _showSnackBar('${plugin.name} updated to v${plugin.latestVersion}');
    }
  }

  void _configurePlugin(Plugin plugin) {
    showDialog(
      context: context,
      builder: (context) => PluginConfigDialog(plugin: plugin),
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
    final installedPlugins = ref.watch(installedPluginsProvider);
    final marketplacePlugins = ref.watch(marketplacePluginsProvider);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.puzzlePiece,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plugins',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Extend Dify with custom models, tools, and integrations',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showInstallDialog,
                      icon: const Icon(FontAwesomeIcons.plus),
                      label: const Text('Install Plugin'),
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
                const SizedBox(height: 16),
                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: theme.primaryColor,
                  tabs: [
                    Tab(
                      text: 'Installed (${installedPlugins.length})',
                    ),
                    const Tab(text: 'Explore Marketplace'),
                  ],
                ),
              ],
            ),
          ),
          // Filter and search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search plugins...',
                      prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<PluginType?>(
                  value: _selectedType,
                  hint: const Text('All Types'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...PluginType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Installed tab
                _buildPluginGrid(
                  _filterPlugins(installedPlugins),
                  isInstalled: true,
                ),
                // Marketplace tab
                _buildPluginGrid(
                  _filterPlugins(marketplacePlugins),
                  isInstalled: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Plugin> _filterPlugins(List<Plugin> plugins) {
    var filtered = plugins;

    // Filter by type
    if (_selectedType != null) {
      filtered = filtered.where((p) => p.type == _selectedType).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(_searchQuery) ||
            p.description.toLowerCase().contains(_searchQuery) ||
            p.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    return filtered;
  }

  Widget _buildPluginGrid(List<Plugin> plugins, {required bool isInstalled}) {
    if (plugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isInstalled
                  ? FontAwesomeIcons.boxOpen
                  : FontAwesomeIcons.magnifyingGlass,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              isInstalled ? 'No plugins installed' : 'No plugins found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white60,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isInstalled
                  ? 'Install plugins from the marketplace to get started'
                  : 'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white38,
                  ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: plugins.length,
      itemBuilder: (context, index) {
        final plugin = plugins[index];
        return PluginCard(
          plugin: plugin,
          onInstall: isInstalled ? null : () => _installPlugin(plugin),
          onConfigure: isInstalled ? () => _configurePlugin(plugin) : null,
          onRemove: isInstalled ? () => _removePlugin(plugin) : null,
          onUpdate: plugin.hasUpdate ? () => _updatePlugin(plugin) : null,
        );
      },
    );
  }
}
