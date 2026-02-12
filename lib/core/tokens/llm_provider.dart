enum AIProvider {
  gemini,
  vertex, // Added for Vertex AI Proxy
  openai,
  claude,
  grok,
  mistral,
  runway, // For video
  midjourney, // Proxy/Mock
  litert // On-Device
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
      case AIProvider.gemini: return 'Google Gemini 1.5 (${modelId})';
      case AIProvider.vertex: return 'Google Vertex AI 1.5 (${modelId})';
      case AIProvider.openai: return 'Google Gemini 1.5 (Compatible Mode)';
      case AIProvider.claude: return 'Google Gemini 1.5 (Compatible Mode)';
      case AIProvider.grok: return 'Google Gemini 1.5 (Compatible Mode)';
      case AIProvider.mistral: return 'Google Gemini 1.5 (Compatible Mode)';
      case AIProvider.runway: return 'Runway Gen-2';
      case AIProvider.midjourney: return 'Midjourney v6';
      case AIProvider.litert: return 'LiteRT On-Device (${modelId})';
    }
  }

  // Factory for known heavy hitters
  static AIModelConfig get geminiPro => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-pro', temperature: 1.0);
  static AIModelConfig get geminiFlash => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-flash', temperature: 1.0);
  static AIModelConfig get geminiFlashLite => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-flash', temperature: 1.0);
  
  // Image Models
  static AIModelConfig get geminiFlashImage => const AIModelConfig(provider: AIProvider.gemini, modelId: 'imagen-3.0-generate-001', temperature: 1.0);
  static AIModelConfig get geminiProImage => const AIModelConfig(provider: AIProvider.gemini, modelId: 'imagen-3.0-generate-001', temperature: 1.0);

  // Re-mapped Legacy Presets (All route to Gemini 1.5)
  static AIModelConfig get geminiResearch => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-flash', useGoogleSearch: true, temperature: 1.0);
  static AIModelConfig get geminiDeepResearch => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-pro', useGoogleSearch: true, temperature: 1.0);
  
  static AIModelConfig get gpt4o => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-pro', temperature: 1.0);
  static AIModelConfig get gpt4Turbo => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-pro', temperature: 1.0);
  static AIModelConfig get gpt35 => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-flash');

  static AIModelConfig get claude3Opus => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-pro', temperature: 1.0);
  static AIModelConfig get claude3Sonnet => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-flash', temperature: 1.0);
  
  static AIModelConfig get grok1 => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-1.5-pro', temperature: 1.0);

  // LiteRT Models
  static AIModelConfig get gemma2n => const AIModelConfig(provider: AIProvider.litert, modelId: 'gemma-2b-it-gpu');
  static AIModelConfig get veoFastPreview => const AIModelConfig(provider: AIProvider.gemini, modelId: 'veo-2.0-preview-001'); // Fixed ID

  
  // Serialization helpers if needed for persistence
  Map<String, dynamic> toJson() => {
    'provider': provider.index,
    'modelId': modelId,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'overrideBaseUrl': overrideBaseUrl,
    'responseMimeType': responseMimeType,
    'useGoogleSearch': useGoogleSearch,
  };

  factory AIModelConfig.fromJson(Map<String, dynamic> json) {
    return AIModelConfig(
      provider: AIProvider.values[json['provider'] as int],
      modelId: json['modelId'] as String,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int?,
      overrideBaseUrl: json['overrideBaseUrl'] as String?,
      responseMimeType: json['responseMimeType'] as String?,
      useGoogleSearch: json['useGoogleSearch'] as bool? ?? false,
    );
  }
}

