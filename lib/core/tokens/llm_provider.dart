/// AI Provider identifiers.
///
/// Pruned to only providers that are functionally wired up.
/// Dead providers (openai, claude, grok, mistral, runway, midjourney)
/// removed in gemini-gemma-vertex-overhaul-staging-2026.
enum AIProvider {
  gemini,  // Google Gemini via Firebase AI SDK
  vertex,  // Vertex AI managed endpoints
  gemma,   // Gemma open models (via Model Garden / Python proxy)
  litert,  // On-Device (LiteRT)
}

class AIModelConfig {
  final AIProvider provider;
  final String modelId;
  final double temperature;
  final int? maxTokens;
  final String? overrideBaseUrl;
  final String? responseMimeType;
  final bool useGoogleSearch;

  const AIModelConfig({
    required this.provider,
    required this.modelId,
    this.temperature = 0.7,
    this.maxTokens,
    this.overrideBaseUrl,
    this.responseMimeType,
    this.useGoogleSearch = false,
  });

  AIModelConfig copyWith({
    AIProvider? provider,
    String? modelId,
    double? temperature,
    int? maxTokens,
    String? overrideBaseUrl,
    String? responseMimeType,
    bool? useGoogleSearch,
  }) {
    return AIModelConfig(
      provider: provider ?? this.provider,
      modelId: modelId ?? this.modelId,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      overrideBaseUrl: overrideBaseUrl ?? this.overrideBaseUrl,
      responseMimeType: responseMimeType ?? this.responseMimeType,
      useGoogleSearch: useGoogleSearch ?? this.useGoogleSearch,
    );
  }

  String get displayName {
    switch (provider) {
      case AIProvider.gemini:
        return 'Gemini (${modelId})';
      case AIProvider.vertex:
        return 'Vertex AI (${modelId})';
      case AIProvider.gemma:
        return 'Gemma (${modelId})';
      case AIProvider.litert:
        return 'LiteRT On-Device (${modelId})';
    }
  }

  // ── Gemini 1.5 — GA Stable ────────────────────────────────
  static AIModelConfig get geminiPro => const AIModelConfig(
    provider: AIProvider.gemini, modelId: 'gemini-2.5-pro', temperature: 1.0);
  static AIModelConfig get geminiFlash => const AIModelConfig(
    provider: AIProvider.gemini, modelId: 'gemini-2.5-flash', temperature: 1.0);
  static AIModelConfig get geminiFlashLite => const AIModelConfig(
    provider: AIProvider.gemini, modelId: 'gemini-1.5-flash-lite', temperature: 1.0);

  // ── Research (Gemini + Google Search grounding) ───────────
  static AIModelConfig get geminiResearch => const AIModelConfig(
    provider: AIProvider.gemini, modelId: 'gemini-2.5-flash',
    useGoogleSearch: true, temperature: 1.0);
  static AIModelConfig get geminiDeepResearch => const AIModelConfig(
    provider: AIProvider.gemini, modelId: 'gemini-2.5-pro',
    useGoogleSearch: true, temperature: 1.0);

  // ── Media Models ──────────────────────────────────────────
  static AIModelConfig get imagen4 => const AIModelConfig(
    provider: AIProvider.vertex, modelId: 'imagen-4.0-generate-001', temperature: 1.0);
  static AIModelConfig get veo31 => const AIModelConfig(
    provider: AIProvider.vertex, modelId: 'veo-3.1-generate-001');

  // ── Gemma Open Models (via Python proxy / Model Garden) ───
  static AIModelConfig get gemma3Fast => const AIModelConfig(
    provider: AIProvider.gemma, modelId: 'gemma-3-4b-it', temperature: 0.3);
  static AIModelConfig get gemma3Quality => const AIModelConfig(
    provider: AIProvider.gemma, modelId: 'gemma-3-27b-it', temperature: 0.7);
  static AIModelConfig get functionGemma => const AIModelConfig(
    provider: AIProvider.gemma, modelId: 'functiongemma-270m', temperature: 0.1);
  static AIModelConfig get translateGemma => const AIModelConfig(
    provider: AIProvider.gemma, modelId: 'translategemma-4b', temperature: 0.3);

  // ── LiteRT On-Device ──────────────────────────────────────
  static AIModelConfig get gemma2n => const AIModelConfig(
    provider: AIProvider.litert, modelId: 'gemma-2b-it-gpu');

  // ── Serialization ─────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'provider': provider.name, // Use name instead of index for safer deserialization
    'modelId': modelId,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'overrideBaseUrl': overrideBaseUrl,
    'responseMimeType': responseMimeType,
    'useGoogleSearch': useGoogleSearch,
  };

  factory AIModelConfig.fromJson(Map<String, dynamic> json) {
    // Handle both legacy index-based and new name-based provider field
    AIProvider provider;
    final providerVal = json['provider'];
    if (providerVal is int) {
      // Legacy: map old indices → new providers (old enum had 9 entries)
      // 0=gemini, 1=vertex, 2-7=dead, 8=litert → now 0=gemini,1=vertex,2=gemma,3=litert
      if (providerVal <= 1) {
        provider = AIProvider.values[providerVal];
      } else if (providerVal == 8) {
        provider = AIProvider.litert;
      } else {
        provider = AIProvider.gemini; // Remap all dead providers to gemini
      }
    } else {
      provider = AIProvider.values.firstWhere(
        (e) => e.name == providerVal,
        orElse: () => AIProvider.gemini,
      );
    }

    return AIModelConfig(
      provider: provider,
      modelId: json['modelId'] as String,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int?,
      overrideBaseUrl: json['overrideBaseUrl'] as String?,
      responseMimeType: json['responseMimeType'] as String?,
      useGoogleSearch: json['useGoogleSearch'] as bool? ?? false,
    );
  }
}

