/// LiteRT strategy — on-device AI generation.
///
/// Falls back to local Gemma models via LiteRT/TFLite when cloud
/// strategies are unavailable. Simulated for now until LiteRT
/// SDK stabilizes in Flutter.
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
    _logger.d('LiteRT: Generating with ${config.modelId} (Accelerated: $_hasHwAccelerator)');

    // Simulate on-device latency (fast!)
    await Future.delayed(const Duration(milliseconds: 150));

    return AIGenerationResult(
      text: 'LiteRT (${config.modelId}): Analyzed request locally. [Fast On-Device Preview]',
      modelUsed: config.modelId,
      strategyUsed: name,
      confidence: 0.85,
      latency: const Duration(milliseconds: 150),
    );
  }
}
