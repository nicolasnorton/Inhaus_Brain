import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';

final remoteConfigProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService(FirebaseRemoteConfig.instance);
});

final remoteConfigInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(remoteConfigProvider);
  await service.initialize();
});

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: AppConfig.isStaging
          ? const Duration(minutes: 5)
          : const Duration(hours: 1),
    ));

    await _remoteConfig.setDefaults(const {
      'brainweave_engine_enabled': true,
    });

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Fallback to defaults if fetch fails
      print('Failed to fetch remote config: $e');
    }
  }

  bool get brainweaveEngineEnabled => _remoteConfig.getBool('brainweave_engine_enabled');
}
