import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/plugin_models.dart';
import '../providers/plugins_provider.dart';

class PluginConfigDialog extends ConsumerStatefulWidget {
  final Plugin plugin;

  const PluginConfigDialog({super.key, required this.plugin});

  @override
  ConsumerState<PluginConfigDialog> createState() => _PluginConfigDialogState();
}

class _PluginConfigDialogState extends ConsumerState<PluginConfigDialog> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers based on plugin type (mocking configuration fields)
    if (widget.plugin.id == 'llamacloud') {
      _controllers['api_key'] = TextEditingController();
      _controllers['project_id'] = TextEditingController();
    } else if (widget.plugin.id == 'mcp-server') {
      _controllers['server_url'] = TextEditingController();
      _controllers['auth_token'] = TextEditingController();
    } else {
      _controllers['api_key'] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPluginIcon(theme),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configure ${widget.plugin.name}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'v${widget.plugin.version} by ${widget.plugin.author}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            ..._buildConfigFields(theme),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Save logic would go here
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${widget.plugin.name} configured')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConfigFields(ThemeData theme) {
    return _controllers.entries.map((entry) {
      final label = entry.key.replaceAll('_', ' ').toUpperCase();
      final isSecret = entry.key.contains('key') || entry.key.contains('token');

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white60,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: entry.value,
              obscureText: isSecret,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  isSecret ? FontAwesomeIcons.key : FontAwesomeIcons.link,
                  size: 14,
                  color: Colors.white38,
                ),
                hintText: 'Enter ${label.toLowerCase()}...',
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPluginIcon(ThemeData theme) {
    IconData icon;
    switch (widget.plugin.type) {
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

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(icon, color: theme.primaryColor, size: 28),
      ),
    );
  }
}
