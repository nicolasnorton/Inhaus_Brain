/// Unified Model Registry for InhausBrain.
///
/// Single source of truth for all model IDs. Replaces scattered
/// hardcoded model strings across `llm_provider.dart`, agent code,
/// and `gemini_client.py`. Supports tiered routing:
///   Gemma (fast/cheap) → Flash-Lite → Flash → Pro
library;

import 'app_environment.dart';
import 'feature_flags.dart';

/// Model tiers ordered by cost/latency (cheapest first).
enum ModelTier {
  /// Gemma 3 4B — ultra-fast routing, classification, simple extraction
  gemmaFast,

  /// Gemini 2.5 Flash-Lite — massive scale, cost-sensitive tasks
  flashLite,

  /// Gemini 2.5 Flash — balanced speed/quality, most agent tasks
  flash,

  /// Gemini 2.5 Pro — complex reasoning, strategy, proposals
  pro,
}

/// Specialized model roles beyond the standard tiers.
enum SpecializedModel {
  /// FunctionGemma 270M — tool-call intent classification
  functionCall,

  /// TranslateGemma 4B — multilingual campaign localization
  translate,

  /// Gemma 3 27B — quality summarization, detailed extraction
  summarize,

  /// Image generation
  image,

  /// Video generation
  video,

  /// Text embeddings
  embed,

  /// Research with grounding (Google Search)
  research,
}

class ModelRegistry {
  ModelRegistry._();

  // ── GA Stable Gemini Models ─────────────────────────────────
  static const _gemini = {
    ModelTier.pro: 'gemini-2.5-pro',
    ModelTier.flash: 'gemini-2.5-flash',
    ModelTier.flashLite: 'gemini-2.5-flash-lite',
  };

  // ── Gemma Open Models (via Model Garden / Python proxy) ─────
  static const _gemma = {
    ModelTier.gemmaFast: 'gemma-3-4b-it',
    SpecializedModel.summarize: 'gemma-3-27b-it',
    SpecializedModel.functionCall: 'functiongemma-270m',
    SpecializedModel.translate: 'translategemma-4b',
  };

  // ── Media & Utility Models ──────────────────────────────────
  static const _media = {
    SpecializedModel.image: 'imagen-4.0-generate-001',
    SpecializedModel.video: 'veo-3.1-generate-001',
    SpecializedModel.embed: 'text-embedding-004',
  };

  // ── Experimental / Preview ──────────────────────────────────
  static const _experimental = {
    ModelTier.pro: 'gemini-3-pro-preview',
    ModelTier.flash: 'gemini-3-flash-preview',
  };

  // ══════════════════════════════════════════════════════════════
  // Public API
  // ══════════════════════════════════════════════════════════════

  /// Resolve a tiered model ID, respecting environment flags.
  ///
  /// If Gemma is enabled and the requested tier is [ModelTier.gemmaFast],
  /// returns the Gemma model. Otherwise falls back to Gemini.
  static String resolve(ModelTier tier) {
    // Gemma tier only when feature flag is on
    if (tier == ModelTier.gemmaFast && FeatureFlags.enableGemma) {
      return _gemma[ModelTier.gemmaFast]!;
    }

    // Experimental models when enabled
    if (FeatureFlags.enableExperimentalModels && _experimental.containsKey(tier)) {
      return _experimental[tier]!;
    }

    return _gemini[tier] ?? _gemini[ModelTier.flash]!;
  }

  /// Resolve a specialized model ID.
  static String resolveSpecialized(SpecializedModel model) {
    // Gemma specialized models require feature flag
    if (_gemma.containsKey(model)) {
      if (!FeatureFlags.enableGemma) {
        // Fall back to Gemini Flash for tasks that would use Gemma
        return _gemini[ModelTier.flash]!;
      }
      return _gemma[model] as String;
    }

    // Research uses Flash with grounding enabled
    if (model == SpecializedModel.research) {
      return _gemini[ModelTier.flash]!; // Grounding is a config, not model ID
    }

    return _media[model] ?? _gemini[ModelTier.flash]!;
  }

  /// Check if a model ID belongs to the Gemma family.
  static bool isGemmaModel(String modelId) =>
      modelId.startsWith('gemma') ||
      modelId.startsWith('functiongemma') ||
      modelId.startsWith('translategemma');

  /// Get the recommended timeout for a model tier (seconds).
  static int timeoutForTier(ModelTier tier) {
    switch (tier) {
      case ModelTier.gemmaFast:
        return 10;
      case ModelTier.flashLite:
        return 15;
      case ModelTier.flash:
        return 30;
      case ModelTier.pro:
        return 60;
    }
  }

  /// All available model IDs (for UI dropdowns, validation, etc.)
  static List<String> get allModelIds => [
        ..._gemini.values,
        if (FeatureFlags.enableGemma) ..._gemma.values.map((v) => v.toString()),
        ..._media.values,
      ];
}
