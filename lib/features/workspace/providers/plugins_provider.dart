import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plugin_models.dart';

/// Provider for installed plugins
final installedPluginsProvider =
    StateNotifierProvider<PluginsNotifier, List<Plugin>>((ref) {
  return PluginsNotifier();
});

/// Provider for available marketplace plugins
final marketplacePluginsProvider = StateProvider<List<Plugin>>((ref) {
  return _getMockMarketplacePlugins();
});

/// Provider for selected plugin
final selectedPluginProvider = StateProvider<Plugin?>((ref) => null);

/// Provider for plugin settings
final pluginSettingsProvider =
    StateNotifierProvider<PluginSettingsNotifier, PluginSettings>((ref) {
  return PluginSettingsNotifier();
});

/// Provider for filtered plugins by type
final filteredPluginsProvider =
    Provider.family<List<Plugin>, PluginType?>((ref, type) {
  final plugins = ref.watch(installedPluginsProvider);
  if (type == null) return plugins;
  return plugins.where((p) => p.type == type).toList();
});

/// State notifier for plugins
class PluginsNotifier extends StateNotifier<List<Plugin>> {
  PluginsNotifier() : super(_getMockInstalledPlugins());

  /// Install a plugin
  void installPlugin(Plugin plugin) {
    final installed = plugin.copyWith(
      status: PluginStatus.installed,
      installedAt: DateTime.now(),
    );
    state = [...state, installed];
  }

  /// Update a plugin
  void updatePlugin(String pluginId, String newVersion) {
    final index = state.indexWhere((p) => p.id == pluginId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(
          version: newVersion,
          hasUpdate: false,
          updatedAt: DateTime.now(),
        ),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Uninstall a plugin
  void uninstallPlugin(String pluginId) {
    state = state.where((p) => p.id != pluginId).toList();
  }

  /// Update plugin status
  void updateStatus(String pluginId, PluginStatus status) {
    final index = state.indexWhere((p) => p.id == pluginId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(status: status),
        ...state.sublist(index + 1),
      ];
    }
  }
}

/// State notifier for plugin settings
class PluginSettingsNotifier extends StateNotifier<PluginSettings> {
  PluginSettingsNotifier() : super(const PluginSettings());

  void updateInstallPermission(PluginPermission permission) {
    state = state.copyWith(installPermission: permission);
  }

  void updateDebugPermission(PluginPermission permission) {
    state = state.copyWith(debugPermission: permission);
  }

  void toggleAutoUpdate() {
    state = state.copyWith(autoUpdate: !state.autoUpdate);
  }

  void blockPlugin(String pluginId) {
    if (!state.blockedPlugins.contains(pluginId)) {
      state = state.copyWith(
        blockedPlugins: [...state.blockedPlugins, pluginId],
      );
    }
  }

  void unblockPlugin(String pluginId) {
    state = state.copyWith(
      blockedPlugins:
          state.blockedPlugins.where((id) => id != pluginId).toList(),
    );
  }
}

/// Mock installed plugins
List<Plugin> _getMockInstalledPlugins() {
  return [
    Plugin(
      id: 'openai-provider',
      name: 'OpenAI Provider',
      type: PluginType.modelProvider,
      source: PluginSource.marketplace,
      version: '1.0.0',
      description: 'Access OpenAI models (GPT-4, GPT-3.5, DALL-E)',
      icon: 'assets/providers/openai.png',
      status: PluginStatus.installed,
      author: 'Inhaus Corp',
      installedAt: DateTime.now().subtract(const Duration(days: 30)),
      tags: ['llm', 'openai', 'gpt'],
    ),
    Plugin(
      id: 'anthropic-provider',
      name: 'Anthropic Provider',
      type: PluginType.modelProvider,
      source: PluginSource.marketplace,
      version: '1.2.0',
      description: 'Access Anthropic Claude models',
      icon: 'assets/providers/anthropic.png',
      status: PluginStatus.installed,
      author: 'Inhaus Corp',
      installedAt: DateTime.now().subtract(const Duration(days: 15)),
      hasUpdate: true,
      latestVersion: '1.3.0',
      tags: ['llm', 'anthropic', 'claude'],
    ),
  ];
}

/// Mock marketplace plugins
List<Plugin> _getMockMarketplacePlugins() {
  return [
    Plugin(
      id: 'weather-api',
      name: 'Weather API',
      type: PluginType.tool,
      source: PluginSource.marketplace,
      version: '2.1.0',
      description: 'Get weather data for any location worldwide',
      author: 'Weather Tools Inc',
      tags: ['weather', 'api', 'data'],
      documentationUrl: 'https://docs.example.com/weather-api',
    ),
    Plugin(
      id: 'database-connector',
      name: 'Database Connector',
      type: PluginType.tool,
      source: PluginSource.marketplace,
      version: '3.0.0',
      description: 'Connect to PostgreSQL, MySQL, and MongoDB databases',
      author: 'Data Tools',
      tags: ['database', 'sql', 'nosql'],
      documentationUrl: 'https://docs.example.com/db-connector',
    ),
    Plugin(
      id: 'webhook-receiver',
      name: 'Webhook Receiver',
      type: PluginType.customEndpoint,
      source: PluginSource.marketplace,
      version: '1.5.0',
      description: 'Receive and process webhooks from external services',
      author: 'Integration Tools',
      tags: ['webhook', 'integration', 'api'],
      documentationUrl: 'https://docs.example.com/webhooks',
    ),
    Plugin(
      id: 'llamacloud',
      name: 'LlamaCloud',
      type: PluginType.tool,
      source: PluginSource.marketplace,
      version: '1.0.5',
      description: 'Official LlamaIndex cloud service for advanced RAG and data parsing',
      author: 'LlamaIndex',
      tags: ['rag', 'llamaindex', 'knowledge'],
      documentationUrl: 'https://cloud.llamaindex.ai',
    ),
    Plugin(
      id: 'mcp-server',
      name: 'Custom MCP Server',
      type: PluginType.tool,
      source: PluginSource.marketplace,
      version: '1.0.0',
      description: 'Connect to any Model Context Protocol (MCP) server for custom tools and resources',
      author: 'Inhaus Brain',
      tags: ['mcp', 'tools', 'server'],
      documentationUrl: 'https://modelcontextprotocol.io',
    ),
    Plugin(
      id: 'google-provider',
      name: 'Google AI Provider',
      type: PluginType.modelProvider,
      source: PluginSource.marketplace,
      version: '1.0.0',
      description: 'Access Google Gemini models',
      icon: 'assets/providers/google.png',
      author: 'Inhaus Corp',
      tags: ['llm', 'google', 'gemini'],
    ),
    Plugin(
      id: 'math-functions',
      name: 'Math Functions',
      type: PluginType.tool,
      source: PluginSource.marketplace,
      version: '1.0.0',
      description: 'Advanced mathematical calculations and formulas',
      author: 'Math Tools',
      tags: ['math', 'calculations', 'formulas'],
    ),
    Plugin(
      id: 'reverse-api',
      name: 'Reverse API',
      type: PluginType.reverseInvocation,
      source: PluginSource.marketplace,
      version: '2.0.0',
      description: 'Call Dify workflows from external applications',
      author: 'Integration Tools',
      tags: ['api', 'reverse', 'integration'],
    ),
  ];
}
