/// Configuration for an AI Agent, defining its operational parameters.
class AgentConfig {
  final String model;
  final double temperature;
  final int maxTokens;
  final Map<String, dynamic> customSettings;

  const AgentConfig({
    this.model = 'gemini-2.5-flash',
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.customSettings = const {},
  });

  AgentConfig copyWith({
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? customSettings,
  }) {
    return AgentConfig(
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}
