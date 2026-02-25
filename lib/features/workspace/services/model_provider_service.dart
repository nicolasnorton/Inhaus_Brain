import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/model_provider_models.dart';

/// Service for managing model provider interactions
class ModelProviderService {
  /// Test connection to a provider
  Future<ProviderTestResult> testConnection(
    ModelProvider provider,
    String apiKey, {
    String? baseUrl,
  }) async {
    try {
      final endpoint = _getTestEndpoint(provider, baseUrl);
      final headers = _getHeaders(provider, apiKey);

      final response = await http
          .get(Uri.parse(endpoint), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 401) {
        // 401 means the endpoint is reachable but auth failed (expected for test)
        return ProviderTestResult(
          success: response.statusCode == 200,
          message: response.statusCode == 200
              ? 'Connection successful'
              : 'Invalid API key',
          models: response.statusCode == 200
              ? await _fetchModels(provider, apiKey, baseUrl)
              : [],
        );
      }

      return ProviderTestResult(
        success: false,
        message: 'Connection failed: ${response.statusCode}',
        models: [],
      );
    } catch (e) {
      return ProviderTestResult(
        success: false,
        message: 'Connection error: $e',
        models: [],
      );
    }
  }

  /// Fetch available models from provider
  Future<List<ModelConfig>> _fetchModels(
    ModelProvider provider,
    String apiKey,
    String? baseUrl,
  ) async {
    try {
      final endpoint = _getModelsEndpoint(provider, baseUrl);
      final headers = _getHeaders(provider, apiKey);

      final response = await http
          .get(Uri.parse(endpoint), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseModels(provider, data);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get test endpoint for provider
  String _getTestEndpoint(ModelProvider provider, String? baseUrl) {
    if (baseUrl != null) return baseUrl;

    switch (provider) {
      case ModelProvider.openai:
        return 'https://api.openai.com/v1/models';
      case ModelProvider.anthropic:
        return 'https://api.anthropic.com/v1/models';
      case ModelProvider.google:
        return 'https://generativelanguage.googleapis.com/v1/models';
      case ModelProvider.cohere:
        return 'https://api.cohere.ai/v1/models';
      case ModelProvider.mistral:
        return 'https://api.mistral.ai/v1/models';
      case ModelProvider.groq:
        return 'https://api.groq.com/openai/v1/models';
      case ModelProvider.together:
        return 'https://api.together.xyz/v1/models';
      case ModelProvider.replicate:
        return 'https://api.replicate.com/v1/models';
      case ModelProvider.huggingface:
        return 'https://api-inference.huggingface.co/models';
      case ModelProvider.ollama:
        return 'http://localhost:11434/api/tags';
      case ModelProvider.custom:
        return baseUrl ?? '';
    }
  }

  /// Get models endpoint for provider
  String _getModelsEndpoint(ModelProvider provider, String? baseUrl) {
    return _getTestEndpoint(provider, baseUrl);
  }

  /// Get headers for provider
  Map<String, String> _getHeaders(ModelProvider provider, String apiKey) {
    switch (provider) {
      case ModelProvider.openai:
      case ModelProvider.groq:
      case ModelProvider.together:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
      case ModelProvider.anthropic:
        return {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        };
      case ModelProvider.google:
        return {
          'x-goog-api-key': apiKey,
          'Content-Type': 'application/json',
        };
      case ModelProvider.cohere:
      case ModelProvider.mistral:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
      case ModelProvider.replicate:
        return {
          'Authorization': 'Token $apiKey',
          'Content-Type': 'application/json',
        };
      case ModelProvider.huggingface:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
      case ModelProvider.ollama:
        return {
          'Content-Type': 'application/json',
        };
      case ModelProvider.custom:
        return {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        };
    }
  }

  /// Parse models from API response
  List<ModelConfig> _parseModels(ModelProvider provider, dynamic data) {
    // This is a simplified parser - in production, you'd parse the actual API response
    // For now, return some default models based on the provider
    return _getDefaultModels(provider);
  }

  /// Get default models for provider
  List<ModelConfig> _getDefaultModels(ModelProvider provider) {
    switch (provider) {
      case ModelProvider.openai:
        return [
          ModelConfig(
            id: 'gpt-4-turbo',
            name: 'GPT-4 Turbo',
            provider: provider,
            type: ModelProviderType.llm,
            contextWindow: 128000,
            maxOutputTokens: 4096,
            supportsVision: true,
            supportsStreaming: true,
            supportsFunctionCalling: true,
            costPer1kTokens: 0.01,
          ),
          ModelConfig(
            id: 'gpt-3.5-turbo',
            name: 'GPT-3.5 Turbo',
            provider: provider,
            type: ModelProviderType.llm,
            contextWindow: 16385,
            maxOutputTokens: 4096,
            supportsStreaming: true,
            supportsFunctionCalling: true,
            costPer1kTokens: 0.0015,
          ),
          ModelConfig(
            id: 'text-embedding-3-large',
            name: 'Text Embedding 3 Large',
            provider: provider,
            type: ModelProviderType.embedding,
            costPer1kTokens: 0.00013,
          ),
        ];
      case ModelProvider.anthropic:
        return [
          ModelConfig(
            id: 'claude-3-opus',
            name: 'Claude 3 Opus',
            provider: provider,
            type: ModelProviderType.llm,
            contextWindow: 200000,
            maxOutputTokens: 4096,
            supportsVision: true,
            supportsStreaming: true,
            costPer1kTokens: 0.015,
          ),
          ModelConfig(
            id: 'claude-3-sonnet',
            name: 'Claude 3 Sonnet',
            provider: provider,
            type: ModelProviderType.llm,
            contextWindow: 200000,
            maxOutputTokens: 4096,
            supportsVision: true,
            supportsStreaming: true,
            costPer1kTokens: 0.003,
          ),
        ];
      case ModelProvider.google:
        return [
          ModelConfig(
            id: 'gemini-3.1-pro-preview',
            name: 'Gemini 3.1 Pro',
            provider: provider,
            type: ModelProviderType.llm,
            contextWindow: 2000000,
            maxOutputTokens: 16384,
            supportsStreaming: true,
            supportsFunctionCalling: true,
            costPer1kTokens: 0.00125,
          ),
          ModelConfig(
            id: 'gemini-3-flash-preview',
            name: 'Gemini 3 Flash',
            provider: provider,
            type: ModelProviderType.llm,
            contextWindow: 1000000,
            maxOutputTokens: 8192,
            supportsVision: true,
            supportsStreaming: true,
            supportsFunctionCalling: true,
            costPer1kTokens: 0.00025,
          ),
        ];
      default:
        return [];
    }
  }
}

/// Result of provider connection test
class ProviderTestResult {
  final bool success;
  final String message;
  final List<ModelConfig> models;

  const ProviderTestResult({
    required this.success,
    required this.message,
    required this.models,
  });
}
