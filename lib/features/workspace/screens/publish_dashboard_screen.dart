import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/publish_models.dart';
import '../providers/publish_provider.dart';
import '../widgets/web_app_settings_dialog.dart';
import '../widgets/api_key_manager.dart';
import '../widgets/embed_code_generator.dart';

/// Publish dashboard screen
class PublishDashboardScreen extends ConsumerStatefulWidget {
  final String appId;

  const PublishDashboardScreen({
    super.key,
    required this.appId,
  });

  @override
  ConsumerState<PublishDashboardScreen> createState() =>
      _PublishDashboardScreenState();
}

class _PublishDashboardScreenState
    extends ConsumerState<PublishDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load publish configuration
    Future.microtask(() {
      ref.read(publishConfigProvider.notifier).loadConfig(widget.appId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final publishConfig = ref.watch(publishConfigProvider);
    final isPublishing = ref.watch(isPublishingProvider);

    if (publishConfig == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (publishConfig.iconUrl != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Image.network(
                  publishConfig.iconUrl!,
                  width: 32,
                  height: 32,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.apps, size: 32),
              ),
            Text(publishConfig.appName),
          ],
        ),
        actions: [
          if (publishConfig.isPublished)
            TextButton.icon(
              onPressed: isPublishing
                  ? null
                  : () => _unpublish(context),
              icon: const Icon(Icons.stop),
              label: const Text('Unpublish'),
            )
          else
            ElevatedButton.icon(
              onPressed: isPublishing
                  ? null
                  : () => _publish(context),
              icon: const Icon(Icons.publish),
              label: const Text('Publish'),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            _buildStatusCard(publishConfig),
            const SizedBox(height: 24),

            // Publishing methods
            _buildWebAppCard(publishConfig),
            const SizedBox(height: 16),
            _buildAPICard(publishConfig),
            const SizedBox(height: 16),
            _buildEmbedCard(publishConfig),
            const SizedBox(height: 16),
            _buildMCPServerCard(publishConfig),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(PublishConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.isPublished ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              config.isPublished ? 'IN SERVICE' : 'NOT PUBLISHED',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (config.isPublished)
              Text(
                'Published ${_formatDate(config.publishedAt)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebAppCard(PublishConfig config) {
    final isEnabled = config.enabledMethods.contains(PublishMethod.webApp);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Web App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isEnabled ? 'IN SERVICE' : 'DISABLED',
                  style: TextStyle(
                    color: isEnabled ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isEnabled) ...[
              const SizedBox(height: 16),
              const Text('Public URL'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        config.webApp.publicUrl,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () => _copyToClipboard(
                        context,
                        config.webApp.publicUrl,
                      ),
                      tooltip: 'Copy URL',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _launchWebApp(config.webApp.publicUrl),
                    icon: const Icon(Icons.launch, size: 18),
                    label: const Text('Launch'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showWebAppSettings(context),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Settings'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAPICard(PublishConfig config) {
    final isEnabled = config.enabledMethods.contains(PublishMethod.api);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.code, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Backend Service API',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isEnabled ? 'IN SERVICE' : 'DISABLED',
                  style: TextStyle(
                    color: isEnabled ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isEnabled) ...[
              const SizedBox(height: 16),
              const Text('Service API Endpoint'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        config.api.endpoint,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () => _copyToClipboard(
                        context,
                        config.api.endpoint,
                      ),
                      tooltip: 'Copy endpoint',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAPIKeyManager(context),
                    icon: const Icon(Icons.key, size: 18),
                    label: const Text('API Key'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showAPIReference(context),
                    icon: const Icon(Icons.book, size: 18),
                    label: const Text('API Reference'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmbedCard(PublishConfig config) {
    final isEnabled = config.embed != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.web, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Website Embed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isEnabled ? 'CONFIGURED' : 'DISABLED',
                  style: TextStyle(
                    color: isEnabled ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showEmbedCodeGenerator(context),
              icon: const Icon(Icons.code, size: 18),
              label: const Text('Configure Embed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCPServerCard(PublishConfig config) {
    final isEnabled = config.mcpServer?.enabled ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.power, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'MCP Server',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isEnabled ? 'ENABLED' : 'DISABLED',
                  style: TextStyle(
                    color: isEnabled ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (config.mcpServer != null && isEnabled) ...[
              const SizedBox(height: 16),
              const Text('Server URL'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  config.mcpServer!.serverUrl,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _setupMCPServer(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Setup MCP Server'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _publish(BuildContext context) async {
    ref.read(isPublishingProvider.notifier).state = true;
    try {
      await ref.read(publishConfigProvider.notifier).publish(widget.appId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App published successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e')),
        );
      }
    } finally {
      ref.read(isPublishingProvider.notifier).state = false;
    }
  }

  Future<void> _unpublish(BuildContext context) async {
    ref.read(isPublishingProvider.notifier).state = true;
    try {
      await ref.read(publishConfigProvider.notifier).unpublish(widget.appId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App unpublished successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unpublish: $e')),
        );
      }
    } finally {
      ref.read(isPublishingProvider.notifier).state = false;
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _launchWebApp(String url) {
    // TODO: Implement URL launcher
    debugPrint('Launch: $url');
  }

  void _showWebAppSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WebAppSettingsDialog(),
    );
  }

  void _showAPIKeyManager(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => APIKeyManager(appId: widget.appId),
    );
  }

  void _showAPIReference(BuildContext context) {
    // TODO: Implement API reference dialog
    debugPrint('Show API reference');
  }

  void _showEmbedCodeGenerator(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EmbedCodeGenerator(),
    );
  }

  void _setupMCPServer(BuildContext context) {
    // TODO: Implement MCP server setup
    debugPrint('Setup MCP server');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }
}
