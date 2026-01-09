import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/publish_models.dart';
import '../services/publish_service.dart';

/// Publish configuration notifier
class PublishConfigNotifier extends StateNotifier<PublishConfig?> {
  final PublishService _service;

  PublishConfigNotifier(this._service) : super(null);

  /// Load publish configuration
  Future<void> loadConfig(String appId) async {
    try {
      final config = await _service.getPublishConfig(appId);
      state = config;
    } catch (e) {
      // Handle error
      state = null;
    }
  }

  /// Publish app
  Future<void> publish(String appId) async {
    try {
      final config = await _service.publishApp(appId);
      state = config;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  /// Unpublish app
  Future<void> unpublish(String appId) async {
    try {
      await _service.unpublishApp(appId);
      if (state != null) {
        state = PublishConfig(
          appId: state!.appId,
          appName: state!.appName,
          description: state!.description,
          iconUrl: state!.iconUrl,
          appType: state!.appType,
          enabledMethods: state!.enabledMethods,
          webApp: state!.webApp,
          api: state!.api,
          embed: state!.embed,
          mcpServer: state!.mcpServer,
          publishedAt: state!.publishedAt,
          isPublished: false,
        );
      }
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  /// Update web app settings
  Future<void> updateWebAppSettings(WebAppConfig config) async {
    try {
      await _service.updateWebAppSettings(config);
      if (state != null) {
        state = PublishConfig(
          appId: state!.appId,
          appName: state!.appName,
          description: state!.description,
          iconUrl: state!.iconUrl,
          appType: state!.appType,
          enabledMethods: state!.enabledMethods,
          webApp: config,
          api: state!.api,
          embed: state!.embed,
          mcpServer: state!.mcpServer,
          publishedAt: state!.publishedAt,
          isPublished: state!.isPublished,
        );
      }
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  /// Update API settings
  Future<void> updateAPISettings(APIConfig config) async {
    try {
      await _service.updateAPISettings(config);
      if (state != null) {
        state = PublishConfig(
          appId: state!.appId,
          appName: state!.appName,
          description: state!.description,
          iconUrl: state!.iconUrl,
          appType: state!.appType,
          enabledMethods: state!.enabledMethods,
          webApp: state!.webApp,
          api: config,
          embed: state!.embed,
          mcpServer: state!.mcpServer,
          publishedAt: state!.publishedAt,
          isPublished: state!.isPublished,
        );
      }
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  /// Update embed settings
  Future<void> updateEmbedSettings(EmbedConfig config) async {
    try {
      await _service.updateEmbedSettings(config);
      if (state != null) {
        state = PublishConfig(
          appId: state!.appId,
          appName: state!.appName,
          description: state!.description,
          iconUrl: state!.iconUrl,
          appType: state!.appType,
          enabledMethods: state!.enabledMethods,
          webApp: state!.webApp,
          api: state!.api,
          embed: config,
          mcpServer: state!.mcpServer,
          publishedAt: state!.publishedAt,
          isPublished: state!.isPublished,
        );
      }
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
}

/// API keys notifier
class APIKeysNotifier extends StateNotifier<List<String>> {
  final PublishService _service;

  APIKeysNotifier(this._service) : super([]);

  /// Generate new API key
  Future<void> generateKey(String appId) async {
    try {
      final key = await _service.generateAPIKey(appId);
      state = [...state, key];
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  /// Revoke API key
  Future<void> revokeKey(String key) async {
    try {
      await _service.revokeAPIKey(key);
      state = state.where((k) => k != key).toList();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
}

/// Providers

/// Publish service provider
final publishServiceProvider = Provider<PublishService>((ref) {
  return PublishService();
});

/// Current publish configuration
final publishConfigProvider =
    StateNotifierProvider<PublishConfigNotifier, PublishConfig?>((ref) {
  final service = ref.watch(publishServiceProvider);
  return PublishConfigNotifier(service);
});

/// Publishing status
final isPublishingProvider = StateProvider<bool>((ref) => false);

/// API keys
final apiKeysProvider =
    StateNotifierProvider<APIKeysNotifier, List<String>>((ref) {
  final service = ref.watch(publishServiceProvider);
  return APIKeysNotifier(service);
});

/// Embed code
final embedCodeProvider = StateProvider<String?>((ref) => null);

/// Selected publish method
final selectedPublishMethodProvider =
    StateProvider<PublishMethod>((ref) => PublishMethod.webApp);
