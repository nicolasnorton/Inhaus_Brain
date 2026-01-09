import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/plugin_models.dart';

/// Card widget for displaying plugin information
class PluginCard extends ConsumerWidget {
  final Plugin plugin;
  final VoidCallback? onInstall;
  final VoidCallback? onConfigure;
  final VoidCallback? onRemove;
  final VoidCallback? onUpdate;

  const PluginCard({
    super.key,
    required this.plugin,
    this.onInstall,
    this.onConfigure,
    this.onRemove,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isInstalled = plugin.status == PluginStatus.installed;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and type badge
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Plugin icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface,
                    ),
                    child: plugin.icon != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              plugin.icon!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildDefaultIcon(theme),
                            ),
                          )
                        : _buildDefaultIcon(theme),
                  ),
                  const SizedBox(width: 12),
                  // Plugin name and author
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plugin.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (plugin.author != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'by ${plugin.author}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Type badge
                  _buildTypeBadge(theme),
                ],
              ),
            ),
            const Divider(height: 1),
            // Description and version
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plugin.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.tag,
                          size: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'v${plugin.version}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (plugin.hasUpdate) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Text(
                              'Update available',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (plugin.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: plugin.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.primaryColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isInstalled) ...[
                    if (plugin.hasUpdate && onUpdate != null)
                      TextButton.icon(
                        onPressed: onUpdate,
                        icon: const Icon(FontAwesomeIcons.arrowUp, size: 14),
                        label: const Text('Update'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    if (onConfigure != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onConfigure,
                        icon: const Icon(FontAwesomeIcons.gear, size: 14),
                        label: const Text('Configure'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                        ),
                      ),
                    ],
                    if (onRemove != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(FontAwesomeIcons.trash, size: 14),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: onInstall,
                      icon: const Icon(FontAwesomeIcons.download, size: 14),
                      label: const Text('Install'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(ThemeData theme) {
    IconData icon;
    switch (plugin.type) {
      case PluginType.modelProvider:
        icon = FontAwesomeIcons.microchip;
        break;
      case PluginType.tool:
        icon = FontAwesomeIcons.wrench;
        break;
      case PluginType.customEndpoint:
        icon = FontAwesomeIcons.plug;
        break;
      case PluginType.reverseInvocation:
        icon = FontAwesomeIcons.arrowsRotate;
        break;
    }

    return Icon(
      icon,
      color: theme.primaryColor,
      size: 24,
    );
  }

  Widget _buildTypeBadge(ThemeData theme) {
    Color badgeColor;
    switch (plugin.type) {
      case PluginType.modelProvider:
        badgeColor = Colors.blue;
        break;
      case PluginType.tool:
        badgeColor = Colors.green;
        break;
      case PluginType.customEndpoint:
        badgeColor = Colors.purple;
        break;
      case PluginType.reverseInvocation:
        badgeColor = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        plugin.type.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
