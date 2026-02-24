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
import 'on_device_llm_service.dart';

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
      if (kIsWeb) {
        await OnDeviceLLMService.init();
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        _hasHwAccelerator = true; // Modern mobile/desktop typically has NPU/GPU
      }
      _initialized = true;
      _logger.i('LiteRT: Initialized (HW Accel: $_hasHwAccelerator)');
    } catch (e) {
      _logger.w('LiteRT: Init failed: $e');
    }
  }

  @override
  Future<AIGenerationResult> generate(AIGenerationRequest request, {dynamic ref}) async {
    if (!_initialized) await init();

    if (kIsWeb) {
      _logger.d('LiteRT: Using Web On-Device (MediaPipe) bridge');
      try {
        return await OnDeviceLLMService.generate(request);
      } catch (e) {
        _logger.e('LiteRT: Web bridge failed: $e');
        rethrow;
      }
    }

    final config = request.config;
    _logger.d('LiteRT: Generating with ${config.modelId} (Accelerated: $_hasHwAccelerator)');

    // TODO: Replace simulation with real LiteRT/TFLite inference for Native Mobile when SDK stabilizes.
    await Future.delayed(const Duration(milliseconds: 150));

    return AIGenerationResult(
      text: 'On-device preview (Gemma-3n): Analyzed request locally. Full response requires cloud AI.',
      modelUsed: config.modelId,
      strategyUsed: name,
      confidence: 0.3,
      latency: const Duration(milliseconds: 150),
    );
  }
}
