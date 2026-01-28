enum AIProvider {
  gemini,
  vertex, // Added for Vertex AI Proxy
  openai,
  claude,
  grok,
  mistral,
  runway, // For video
  midjourney // Proxy/Mock
}

class AIModelConfig {
  final AIProvider provider;
  final String modelId;
  final double temperature;
  final int? maxTokens;
  final String? overrideBaseUrl; // For local proxies or enterprise endpoints
  final String? responseMimeType; // e.g. 'application/json'

  const AIModelConfig({
    required this.provider,
    required this.modelId,
    this.temperature = 0.7,
    this.maxTokens,
    this.overrideBaseUrl,
    this.responseMimeType,
  });

  String get displayName {
    switch (provider) {
      case AIProvider.gemini: return 'Google Gemini ($modelId)';
      case AIProvider.vertex: return 'Google Vertex AI ($modelId)';
      case AIProvider.openai: return 'OpenAI ($modelId)';
      case AIProvider.claude: return 'Anthropic Claude ($modelId)';
      case AIProvider.grok: return 'xAI Grok ($modelId)';
      case AIProvider.mistral: return 'Mistral AI ($modelId)';
      case AIProvider.runway: return 'Runway Gen-2';
      case AIProvider.midjourney: return 'Midjourney v6';
    }
  }

  // Factory for known heavy hitters
  static AIModelConfig get geminiPro => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-pro-latest');
  static AIModelConfig get geminiFlash => const AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-2.0-flash');
  
  static AIModelConfig get gpt4o => const AIModelConfig(provider: AIProvider.openai, modelId: 'gpt-4o');
  static AIModelConfig get gpt4Turbo => const AIModelConfig(provider: AIProvider.openai, modelId: 'gpt-4-turbo');
  static AIModelConfig get gpt35 => const AIModelConfig(provider: AIProvider.openai, modelId: 'gpt-3.5-turbo');

  static AIModelConfig get claude3Opus => const AIModelConfig(provider: AIProvider.claude, modelId: 'claude-3-opus-20240229');
  static AIModelConfig get claude3Sonnet => const AIModelConfig(provider: AIProvider.claude, modelId: 'claude-3-5-sonnet-20240620');
  
  static AIModelConfig get grok1 => const AIModelConfig(provider: AIProvider.grok, modelId: 'grok-1');
  
  // Serialization helpers if needed for persistence
  Map<String, dynamic> toJson() => {
    'provider': provider.index,
    'modelId': modelId,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'overrideBaseUrl': overrideBaseUrl,
    'responseMimeType': responseMimeType,
  };

  factory AIModelConfig.fromJson(Map<String, dynamic> json) {
    return AIModelConfig(
      provider: AIProvider.values[json['provider'] as int],
      modelId: json['modelId'] as String,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int?,
      overrideBaseUrl: json['overrideBaseUrl'] as String?,
      responseMimeType: json['responseMimeType'] as String?,
    );
  }
}
