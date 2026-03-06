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

  // ── Creative Campaign Canvas (Weavy-style) ────────────────────────────────
  /// Controls visibility of the Designer Canvas mode in Campaigns.
  /// When false, no creative nodes or Designer Mode buttons appear.
  static bool get enableDesignerCanvasMode =>
      _overrides['enableDesignerCanvasMode'] ?? AppConfig.isStaging;

  /// Controls Figma REST API integration and MCP tools.
  /// Requires enableDesignerCanvasMode to be meaningful.
  static bool get enableFigmaIntegration =>
      _overrides['enableFigmaIntegration'] ?? AppConfig.isStaging;

  // ── BrainWeave ────────────────────────────────────────────────────────────
  /// Controls visibility of the BrainWeave workspace tab and 6R pipeline.
  static bool get brainweaveEnabled =>
      _overrides['brainweave_enabled'] ?? true;

  /// Controls BrainWeave 2.1 Upgrades (Subagents, Concept Matching, Wiki, Hybrid Search)
  static bool get brainweave21Enabled =>
      _overrides['brainweave21_enabled'] ?? false;

  /// When true, PicoClaw prefers Gemma on-device over cloud Gemini.
  /// Default false — cloud is primary for demo reliability.
  static bool get useEdgeFallback =>
      _overrides['use_edge_fallback'] ?? false;

  // ── Model Override Keys (String Remote Config) ────────────────────────
  static final Map<String, String> _stringOverrides = {};

  /// Remote Config model strings — fall back to hardcoded defaults.
  static String get defaultReasoningModel =>
      _stringOverrides['gemini_default_reasoning_model'] ?? 'gemini-3.1-pro-preview';
  static String get fastModel =>
      _stringOverrides['gemini_fast_model'] ?? 'gemini-3-flash-preview';
  static String get embeddingModel =>
      _stringOverrides['gemini_embedding_model'] ?? 'gemini-embedding-001';
  static String get picoClawModel =>
      _stringOverrides['pico_claw_model'] ?? 'gemini-3.1-pro-preview';
  static String get edgeFallbackModel =>
      _stringOverrides['edge_fallback_model'] ?? 'gemma-3-9b';

  /// Check any flag by name (for dynamic/future flags)
  static bool isEnabled(String flagName, {bool defaultValue = false}) =>
      _overrides[flagName] ?? defaultValue;
}
