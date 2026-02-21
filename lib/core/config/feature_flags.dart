/// Runtime feature flags for InhausBrain.
///
/// These can be toggled via Firestore Remote Config document
/// `staging_config/feature_flags` or fall back to [AppConfig] defaults.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'app_environment.dart';

class FeatureFlags {
  FeatureFlags._();

  static bool _initialized = false;
  static final Map<String, bool> _overrides = {};

  /// Initialize from Firestore Remote Config (optional, non-blocking).
  /// Falls back to [AppConfig] defaults if Firestore is unreachable.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('staging_config')
          .doc('feature_flags')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        for (final entry in data.entries) {
          if (entry.value is bool) {
            _overrides[entry.key] = entry.value as bool;
          }
        }
        debugPrint('FeatureFlags: Loaded ${_overrides.length} overrides from Firestore');
      }
    } catch (e) {
      debugPrint('FeatureFlags: Could not load remote flags: $e');
    }
    _initialized = true;
  }

  // ── Flag accessors (remote override → AppConfig default) ───

  static bool get enableGemma =>
      _overrides['enableGemma'] ?? AppConfig.enableGemma;

  static bool get enableExperimentalModels =>
      _overrides['enableExperimentalModels'] ?? AppConfig.enableExperimentalModels;

  static bool get enableVerboseAILogging =>
      _overrides['enableVerboseAILogging'] ?? AppConfig.enableVerboseAILogging;

  static bool get enableEnhancedCaching =>
      _overrides['enableEnhancedCaching'] ?? AppConfig.enableEnhancedCaching;

  static bool get enableFunctionGemmaRouter =>
      _overrides['enableFunctionGemmaRouter'] ?? AppConfig.enableFunctionGemmaRouter;

  static bool get enableTranslateGemma =>
      _overrides['enableTranslateGemma'] ?? AppConfig.enableTranslateGemma;

  static bool get enableStitch =>
      _overrides['enableStitch'] ?? AppConfig.enableStitch;

  /// Check any flag by name (for dynamic/future flags)
  static bool isEnabled(String flagName, {bool defaultValue = false}) =>
      _overrides[flagName] ?? defaultValue;
}
