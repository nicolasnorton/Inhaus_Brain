/// Abstract strategy interface for AI generation.
///
/// Each strategy handles a specific provider (VertexAI, Gemma, LiteRT).
/// The [AIRouter] selects the appropriate strategy based on model tier
/// and environment flags.
library;

import 'ai_generation_request.dart';

/// Contract for all AI generation strategies.
abstract class AIStrategy {
  /// Human-readable strategy name for logging/telemetry.
  String get name;

  /// Generate text content using this strategy's provider.
  Future<AIGenerationResult> generate(AIGenerationRequest request);

  /// Whether this strategy supports streaming.
  bool get supportsStreaming => false;

  /// Stream text content (optional — default throws).
  Stream<AIGenerationResult> generateStream(AIGenerationRequest request) {
    throw UnimplementedError('$name does not support streaming');
  }
}
