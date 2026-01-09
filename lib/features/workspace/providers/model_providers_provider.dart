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
      ProviderConfig(provider: ModelProvider.openai),
      ProviderConfig(provider: ModelProvider.anthropic),
      ProviderConfig(provider: ModelProvider.google),
      ProviderConfig(provider: ModelProvider.cohere),
      ProviderConfig(provider: ModelProvider.mistral),
      ProviderConfig(provider: ModelProvider.groq),
    ];
  }
}
