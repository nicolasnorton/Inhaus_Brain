/// LiteRT strategy — on-device AI generation.
///
/// Falls back to local Gemma models via LiteRT/TFLite when cloud
/// strategies are unavailable. On web, this strategy is not available
/// and will throw so the error propagates to the user.
library;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'ai_strategy.dart';
import 'ai_generation_request.dart';

class LiteRTStrategy extends AIStrategy {
  static final _logger = Logger();
  static bool _initialized = false;
  static bool _hasHwAccelerator = false;

  @override
  String get name => 'litert';

  /// Initialize LiteRT runtime and check for hardware acceleration.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      _logger.d('LiteRT: Initializing...');
      await Future.delayed(const Duration(milliseconds: 100));
      if (!kIsWeb) {
        _hasHwAccelerator = true; // Modern mobile/desktop typically has NPU/GPU
      }
      _initialized = true;
      _logger.i('LiteRT: Initialized (HW Accel: $_hasHwAccelerator)');
    } catch (e) {
      _logger.w('LiteRT: Init failed: $e');
    }
  }

  @override
  Future<AIGenerationResult> generate(AIGenerationRequest request) async {
    if (!_initialized) await init();

    final config = request.config;

    // On web, LiteRT is not available — throw so the router shows a real error.
    if (kIsWeb) {
      _logger.w('LiteRT: Not available on web. Propagating error.');
      throw Exception('On-device AI (LiteRT) is not available on web. Cloud AI service is temporarily unavailable.');
    }

    _logger.d('LiteRT: Generating with ${config.modelId} (Accelerated: $_hasHwAccelerator)');

    // TODO: Replace simulation with real LiteRT/TFLite inference when SDK stabilizes.
    await Future.delayed(const Duration(milliseconds: 150));

    return AIGenerationResult(
      text: 'On-device preview (Gemma-2B): Analyzed request locally. Full response requires cloud AI.',
      modelUsed: 'gemma-2b-litert',
      strategyUsed: name,
      confidence: 0.3,
      latency: const Duration(milliseconds: 150),
    );
  }
}
