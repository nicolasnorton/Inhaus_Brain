/// AI Router — selects the appropriate generation strategy.
///
/// Routes requests to the correct strategy based on the model's
/// [AIProvider] and environment flags from [AppConfig].
///
/// ```
/// AIRouter.generate(request) → VertexAIStrategy / GemmaStrategy / LiteRTStrategy
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../tokens/llm_provider.dart';
import '../../config/app_environment.dart';
import 'ai_generation_request.dart';
import 'ai_strategy.dart';
import 'vertex_ai_strategy.dart';
import 'gemma_strategy.dart';
import 'litert_strategy.dart';
import 'proxy_strategy.dart';

class AIRouter {
  static final _logger = Logger();

  // Strategy singletons (stateless, safe to share)
  static final _vertexAI = VertexAIStrategy();
  static final _gemma = GemmaStrategy();
  static final _liteRT = LiteRTStrategy();
  static final _proxy = ProxyStrategy();

  /// Route a generation request to the appropriate strategy.
  ///
  /// On web, prefers the proxy strategy for Gemini/Vertex to bypass
  /// CORS and App Check issues. Falls back through strategies on error.
  static Future<AIGenerationResult> generate(
    AIGenerationRequest request, {
    dynamic ref,
  }) async {
    final strategy = _resolveStrategy(request);
    _logger.d('AIRouter: Routing to ${strategy.name} for ${request.config.modelId}');

    try {
      return await strategy.generate(request);
    } catch (e) {
      _logger.w('AIRouter: ${strategy.name} failed: $e. Trying fallback chain.');
      return _fallback(request, failedStrategy: strategy.name, error: e);
    }
  }

  /// Route a streaming request.
  static Stream<AIGenerationResult> generateStream(
    AIGenerationRequest request, {
    dynamic ref,
  }) {
    final strategy = _resolveStrategy(request);
    if (!strategy.supportsStreaming) {
      _logger.w('AIRouter: ${strategy.name} does not support streaming, falling back to VertexAI');
      return _vertexAI.generateStream(request);
    }
    return strategy.generateStream(request);
  }

  /// Determine which strategy to use for this request.
  static AIStrategy _resolveStrategy(AIGenerationRequest request) {
    final provider = request.config.provider;

    // On web, prefer Proxy for Gemini to bypass CORS/AppCheck 
    if (kIsWeb && (provider == AIProvider.gemini || provider == AIProvider.vertex)) {
      return _proxy;
    }

    switch (provider) {
      case AIProvider.gemini:
      case AIProvider.vertex:
        return _vertexAI;
      case AIProvider.gemma:
        if (AppConfig.enableGemma) return _gemma;
        // Fall back to VertexAI if Gemma is disabled
        _logger.i('AIRouter: Gemma disabled in ${AppConfig.current.name}, routing to VertexAI');
        return _vertexAI;
      case AIProvider.litert:
        return _liteRT;
    }
  }

  /// Fallback chain when the primary strategy fails.
  static Future<AIGenerationResult> _fallback(
    AIGenerationRequest request, {
    required String failedStrategy,
    required Object error,
  }) async {
    // If proxy failed, try direct SDK
    if (failedStrategy == 'proxy') {
      try {
        _logger.i('AIRouter: Proxy failed, trying direct VertexAI SDK');
        return await _vertexAI.generate(request);
      } catch (e) {
        _logger.w('AIRouter: VertexAI SDK also failed: $e');
      }
    }

    // If VertexAI failed, try LiteRT
    if (failedStrategy == 'vertex_ai' || failedStrategy == 'proxy') {
      try {
        _logger.i('AIRouter: Trying LiteRT fallback');
        return await _liteRT.generate(request);
      } catch (e) {
        _logger.w('AIRouter: LiteRT also failed: $e');
      }
    }

    // Ultimate fallback: mock response
    return AIGenerationResult(
      text: 'AI generation unavailable. Error: $error',
      modelUsed: request.config.modelId,
      strategyUsed: 'mock_fallback',
      confidence: 0.0,
    );
  }
}
