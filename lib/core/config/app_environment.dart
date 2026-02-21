/// Environment configuration for InhausBrain.
///
/// Detects staging vs production based on hostname and provides
/// environment-specific feature gates. All new behavior (Gemma,
/// experimental models) is gated behind staging flags.
library;

import 'package:flutter/foundation.dart';

enum AppEnvironment { staging, production }

class AppConfig {
  AppConfig._();

  /// Detect environment from hostname or dart-define.
  static AppEnvironment get current {
    // 1. Explicit dart-define override (highest priority)
    const envOverride = String.fromEnvironment('ENVIRONMENT', defaultValue: '');
    if (envOverride == 'staging') return AppEnvironment.staging;
    if (envOverride == 'production') return AppEnvironment.production;

    // 2. Web hostname detection
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.contains('beta') || host.contains('staging') || host.contains('localhost')) {
        return AppEnvironment.staging;
      }
      return AppEnvironment.production;
    }

    // 3. Native: default to staging in debug, production in release
    if (kDebugMode) return AppEnvironment.staging;
    return AppEnvironment.production;
  }

  // ── Convenience ────────────────────────────────────
  static bool get isStaging => current == AppEnvironment.staging;
  static bool get isProduction => current == AppEnvironment.production;

  // ── Feature Gates ──────────────────────────────────
  /// Enable Gemma model tier (routing, classification, translation)
  static bool get enableGemma => isStaging;

  /// Enable experimental / preview models (Gemini 3 preview, etc.)
  static bool get enableExperimentalModels => isStaging;

  /// Verbose AI request/response logging
  static bool get enableVerboseAILogging => isStaging;

  /// Budget governor — always on regardless of environment
  static bool get enableBudgetGovernor => true;

  /// Enhanced semantic caching with TTL/LRU
  static bool get enableEnhancedCaching => isStaging;

  /// FunctionGemma-based intent routing
  static bool get enableFunctionGemmaRouter => isStaging;

  /// TranslateGemma for multilingual campaign content
  static bool get enableTranslateGemma => isStaging;

  /// Google Stitch MCP — AI-powered UI design generation
  static bool get enableStitch => isStaging;

  // ── Display ────────────────────────────────────────
  static String get environmentLabel => isStaging ? 'STAGING' : 'PRODUCTION';
}
