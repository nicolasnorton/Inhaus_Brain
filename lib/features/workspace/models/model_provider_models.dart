/// Models for AI model providers

/// Model provider type
enum ModelProviderType {
  llm,
  embedding,
  rerank,
  tts,
  stt;

  String get displayName {
    switch (this) {
      case ModelProviderType.llm:
        return 'LLM';
      case ModelProviderType.embedding:
        return 'Embedding';
      case ModelProviderType.rerank:
        return 'Rerank';
      case ModelProviderType.tts:
        return 'Text-to-Speech';
      case ModelProviderType.stt:
        return 'Speech-to-Text';
    }
  }
}

/// Model provider
enum ModelProvider {
  openai,
  anthropic,
  google,
  cohere,
  mistral,
  groq,
  together,
  replicate,
  huggingface,
  ollama,
  custom;

  String get displayName {
    switch (this) {
      case ModelProvider.openai:
        return 'OpenAI';
      case ModelProvider.anthropic:
        return 'Anthropic';
      case ModelProvider.google:
        return 'Google';
      case ModelProvider.cohere:
        return 'Cohere';
      case ModelProvider.mistral:
        return 'Mistral';
      case ModelProvider.groq:
        return 'Groq';
      case ModelProvider.together:
        return 'Together AI';
      case ModelProvider.replicate:
        return 'Replicate';
      case ModelProvider.huggingface:
        return 'Hugging Face';
      case ModelProvider.ollama:
        return 'Ollama';
      case ModelProvider.custom:
        return 'Custom';
    }
  }

  String get logoUrl {
    switch (this) {
      case ModelProvider.openai:
        return 'assets/providers/openai.png';
      case ModelProvider.anthropic:
        return 'assets/providers/anthropic.png';
      case ModelProvider.google:
        return 'assets/providers/google.png';
      case ModelProvider.cohere:
        return 'assets/providers/cohere.png';
      case ModelProvider.mistral:
        return 'assets/providers/mistral.png';
      case ModelProvider.groq:
        return 'assets/providers/groq.png';
      case ModelProvider.together:
        return 'assets/providers/together.png';
      case ModelProvider.replicate:
        return 'assets/providers/replicate.png';
      case ModelProvider.huggingface:
        return 'assets/providers/huggingface.png';
      case ModelProvider.ollama:
        return 'assets/providers/ollama.png';
      case ModelProvider.custom:
        return 'assets/providers/custom.png';
    }
  }
}

/// Model configuration
class ModelConfig {
  final String id;
  final String name;
  final ModelProvider provider;
  final ModelProviderType type;
  final Map<String, dynamic> capabilities;
  final int? contextWindow;
  final int? maxOutputTokens;
  final bool supportsVision;
  final bool supportsStreaming;
  final bool supportsFunctionCalling;
  final double? costPer1kTokens;

  const ModelConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.type,
    this.capabilities = const {},
    this.contextWindow,
    this.maxOutputTokens,
    this.supportsVision = false,
    this.supportsStreaming = false,
    this.supportsFunctionCalling = false,
    this.costPer1kTokens,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider.name,
        'type': type.name,
        'capabilities': capabilities,
        if (contextWindow != null) 'context_window': contextWindow,
        if (maxOutputTokens != null) 'max_output_tokens': maxOutputTokens,
        'supports_vision': supportsVision,
        'supports_streaming': supportsStreaming,
        'supports_function_calling': supportsFunctionCalling,
        if (costPer1kTokens != null) 'cost_per_1k_tokens': costPer1kTokens,
      };

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      provider: ModelProvider.values.byName(json['provider'] as String),
      type: ModelProviderType.values.byName(json['type'] as String),
      capabilities: json['capabilities'] as Map<String, dynamic>? ?? {},
      contextWindow: json['context_window'] as int?,
      maxOutputTokens: json['max_output_tokens'] as int?,
      supportsVision: json['supports_vision'] as bool? ?? false,
      supportsStreaming: json['supports_streaming'] as bool? ?? false,
      supportsFunctionCalling: json['supports_function_calling'] as bool? ?? false,
      costPer1kTokens: json['cost_per_1k_tokens'] as double?,
    );
  }
}

/// Provider credentials
class ProviderCredentials {
  final ModelProvider provider;
  final String apiKey;
  final String? baseUrl;
  final Map<String, String>? additionalHeaders;
  final DateTime createdAt;
  final DateTime? lastUsed;

  const ProviderCredentials({
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    this.additionalHeaders,
    required this.createdAt,
    this.lastUsed,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'api_key': apiKey,
        if (baseUrl != null) 'base_url': baseUrl,
        if (additionalHeaders != null) 'additional_headers': additionalHeaders,
        'created_at': createdAt.toIso8601String(),
        if (lastUsed != null) 'last_used': lastUsed!.toIso8601String(),
      };

  factory ProviderCredentials.fromJson(Map<String, dynamic> json) {
    return ProviderCredentials(
      provider: ModelProvider.values.byName(json['provider'] as String),
      apiKey: json['api_key'] as String,
      baseUrl: json['base_url'] as String?,
      additionalHeaders: (json['additional_headers'] as Map?)?.cast<String, String>(),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsed: json['last_used'] != null ? DateTime.parse(json['last_used'] as String) : null,
    );
  }
}

/// Provider status
enum ProviderStatus {
  connected,
  disconnected,
  error,
  testing;

  String get displayName {
    switch (this) {
      case ProviderStatus.connected:
        return 'Connected';
      case ProviderStatus.disconnected:
        return 'Disconnected';
      case ProviderStatus.error:
        return 'Error';
      case ProviderStatus.testing:
        return 'Testing';
    }
  }
}

/// Provider configuration
class ProviderConfig {
  final ModelProvider provider;
  final ProviderCredentials? credentials;
  final List<ModelConfig> availableModels;
  final ModelConfig? defaultModel;
  final ProviderStatus status;
  final String? errorMessage;
  final UsageQuota? quota;
  final bool enabled;

  const ProviderConfig({
    required this.provider,
    this.credentials,
    this.availableModels = const [],
    this.defaultModel,
    this.status = ProviderStatus.disconnected,
    this.errorMessage,
    this.quota,
    this.enabled = true,
  });

  ProviderConfig copyWith({
    ProviderCredentials? credentials,
    List<ModelConfig>? availableModels,
    ModelConfig? defaultModel,
    ProviderStatus? status,
    String? errorMessage,
    UsageQuota? quota,
    bool? enabled,
  }) {
    return ProviderConfig(
      provider: provider,
      credentials: credentials ?? this.credentials,
      availableModels: availableModels ?? this.availableModels,
      defaultModel: defaultModel ?? this.defaultModel,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      quota: quota ?? this.quota,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        if (credentials != null) 'credentials': credentials!.toJson(),
        'available_models': availableModels.map((m) => m.toJson()).toList(),
        if (defaultModel != null) 'default_model': defaultModel!.toJson(),
        'status': status.name,
        if (errorMessage != null) 'error_message': errorMessage,
        'enabled': enabled,
      };

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    return ProviderConfig(
      provider: ModelProvider.values.byName(json['provider'] as String),
      credentials: json['credentials'] != null
          ? ProviderCredentials.fromJson(json['credentials'] as Map<String, dynamic>)
          : null,
      availableModels: (json['available_models'] as List?)
              ?.map((m) => ModelConfig.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      defaultModel: json['default_model'] != null
          ? ModelConfig.fromJson(json['default_model'] as Map<String, dynamic>)
          : null,
      status: ProviderStatus.values.byName(json['status'] as String),
      errorMessage: json['error_message'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

/// Usage quota
class UsageQuota {
  final int requestsUsed;
  final int requestsLimit;
  final int tokensUsed;
  final int tokensLimit;
  final DateTime resetAt;

  const UsageQuota({
    required this.requestsUsed,
    required this.requestsLimit,
    required this.tokensUsed,
    required this.tokensLimit,
    required this.resetAt,
  });

  double get requestsPercentage => (requestsUsed / requestsLimit) * 100;
  double get tokensPercentage => (tokensUsed / tokensLimit) * 100;

  bool get isNearLimit => requestsPercentage > 80 || tokensPercentage > 80;
  bool get isOverLimit => requestsUsed >= requestsLimit || tokensUsed >= tokensLimit;
}
