import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/model_provider_models.dart';

/// Provider for model provider configurations
final modelProvidersProvider =
    StateNotifierProvider<ModelProvidersNotifier, List<ProviderConfig>>((ref) {
  return ModelProvidersNotifier();
});

/// Provider for selected model provider
final selectedProviderProvider = StateProvider<ModelProvider?>((ref) => null);

/// Provider for available models (filtered by type)
final availableModelsProvider = Provider.family<List<ModelConfig>, ModelProviderType?>((ref, type) {
  final providers = ref.watch(modelProvidersProvider);
  final allModels = providers
      .where((p) => p.enabled && p.status == ProviderStatus.connected)
      .expand((p) => p.availableModels)
      .toList();

  if (type == null) return allModels;
  return allModels.where((m) => m.type == type).toList();
});

/// Provider for default models by type
final defaultModelsProvider = StateProvider<Map<ModelProviderType, ModelConfig>>((ref) => {});

/// State notifier for model providers
class ModelProvidersNotifier extends StateNotifier<List<ProviderConfig>> {
  ModelProvidersNotifier() : super(_getDefaultProviders());

  /// Add or update provider configuration
  void configureProvider(ProviderConfig config) {
    final index = state.indexWhere((p) => p.provider == config.provider);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        config,
        ...state.sublist(index + 1),
      ];
    } else {
      state = [...state, config];
    }
  }

  /// Update provider credentials
  void updateCredentials(ModelProvider provider, ProviderCredentials credentials) {
    final index = state.indexWhere((p) => p.provider == provider);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(credentials: credentials),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Update provider status
  void updateStatus(ModelProvider provider, ProviderStatus status, {String? errorMessage}) {
    final index = state.indexWhere((p) => p.provider == provider);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(status: status, errorMessage: errorMessage),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Enable/disable provider
  void toggleProvider(ModelProvider provider, bool enabled) {
    final index = state.indexWhere((p) => p.provider == provider);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(enabled: enabled),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Set default model for provider
  void setDefaultModel(ModelProvider provider, ModelConfig model) {
    final index = state.indexWhere((p) => p.provider == provider);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(defaultModel: model),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Update available models for provider
  void updateAvailableModels(ModelProvider provider, List<ModelConfig> models) {
    final index = state.indexWhere((p) => p.provider == provider);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(availableModels: models),
        ...state.sublist(index + 1),
      ];
    }
  }

  /// Remove provider
  void removeProvider(ModelProvider provider) {
    state = state.where((p) => p.provider != provider).toList();
  }

  /// Get default providers list
  static List<ProviderConfig> _getDefaultProviders() {
    return [
      ProviderConfig(
        provider: ModelProvider.openai,
        status: ProviderStatus.connected,
        quota: UsageQuota(
          requestsUsed: 450,
          requestsLimit: 1000,
          tokensUsed: 120000,
          tokensLimit: 500000,
          resetAt: DateTime(2026, 2, 1),
        ),
      ),
      ProviderConfig(
        provider: ModelProvider.anthropic,
        status: ProviderStatus.connected,
        quota: UsageQuota(
          requestsUsed: 850,
          requestsLimit: 1000,
          tokensUsed: 420000,
          tokensLimit: 500000,
          resetAt: DateTime(2026, 2, 1),
        ),
      ),
      ProviderConfig(
        provider: ModelProvider.google,
        status: ProviderStatus.connected,
        credentials: ProviderCredentials(
          provider: ModelProvider.google,
          apiKey: '', // User must provide key via settings
          createdAt: DateTime.now(),
        ),
        availableModels: [
          ModelConfig(
            id: 'gemini-3.1-pro-preview',
            name: 'Gemini 3.1 Pro (Frontier Reasoner)',
            provider: ModelProvider.google,
            type: ModelProviderType.llm,
            contextWindow: 2000000,
            maxOutputTokens: 16384,
            supportsVision: true,
            supportsStreaming: true,
            supportsFunctionCalling: true,
          ),
          ModelConfig(
            id: 'gemini-3-flash-preview',
            name: 'Gemini 3 Flash (Frontier Speed)',
            provider: ModelProvider.google,
            type: ModelProviderType.llm,
            contextWindow: 1000000,
            maxOutputTokens: 8192,
            supportsVision: true,
            supportsStreaming: true,
            supportsFunctionCalling: true,
          ),
          ModelConfig(
            id: 'gemini-2.5-pro',
            name: 'Gemini 2.5 Pro (Balanced Stable)',
            provider: ModelProvider.google,
            type: ModelProviderType.llm,
            contextWindow: 1000000,
            maxOutputTokens: 16384,
            supportsVision: true,
            supportsStreaming: true,
            supportsFunctionCalling: true,
          ),
          ModelConfig(
            id: 'gemini-2.5-flash',
            name: 'Gemini 2.5 Flash (Latency Optimized)',
            provider: ModelProvider.google,
            type: ModelProviderType.llm,
            contextWindow: 1000000,
            maxOutputTokens: 8192,
            supportsVision: true,
            supportsStreaming: true,
            supportsFunctionCalling: true,
          ),
          ModelConfig(
            id: 'gemma-3n-e2b-it',
            name: 'Gemma-3n (On-Device Fallback)',
            provider: ModelProvider.google,
            type: ModelProviderType.llm,
            contextWindow: 32768,
            maxOutputTokens: 2048,
            supportsVision: true,
            supportsStreaming: true,
            supportsFunctionCalling: false,
          ),
          ModelConfig(
            id: 'gemini-2.5-flash-image',
            name: 'Nano Banana (High Fidelity)',
            provider: ModelProvider.google,
            type: ModelProviderType.image,
            contextWindow: 0,
            maxOutputTokens: 0,
            supportsVision: false,
            supportsStreaming: false,
            supportsFunctionCalling: false,
          ),
          ModelConfig(
            id: 'veo-3.1-generate-preview',
            name: 'Veo 3.1 (Video Generation)',
            provider: ModelProvider.google,
            type: ModelProviderType.video,
            contextWindow: 0,
            maxOutputTokens: 0,
            supportsVision: false,
            supportsStreaming: false,
            supportsFunctionCalling: false,
          ),
        ],
      ),
      const ProviderConfig(provider: ModelProvider.groq),
      const ProviderConfig(provider: ModelProvider.together),
      const ProviderConfig(provider: ModelProvider.mistral),
      const ProviderConfig(provider: ModelProvider.cohere),
      const ProviderConfig(provider: ModelProvider.replicate),
      const ProviderConfig(provider: ModelProvider.huggingface),
      const ProviderConfig(provider: ModelProvider.ollama),
      const ProviderConfig(provider: ModelProvider.custom),
    ];
  }
}
