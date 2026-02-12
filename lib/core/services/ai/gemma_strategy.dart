/// Gemma strategy — lightweight open models via Python Cloud Functions proxy.
///
/// Routes to Gemma 3 family models (4B, 27B, FunctionGemma, TranslateGemma)
/// through the Python backend. Staging-gated via FeatureFlags.
library;

import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'ai_strategy.dart';
import 'ai_generation_request.dart';
import '../../config/app_environment.dart';

class GemmaStrategy extends AIStrategy {
  static final _logger = Logger();

  /// Cloud Functions base URL (shared Firebase project).
  static const _functionsBase = 'https://us-central1-inhausbrain.cloudfunctions.net';

  @override
  String get name => 'gemma';

  @override
  Future<AIGenerationResult> generate(AIGenerationRequest request) async {
    if (!AppConfig.enableGemma) {
      throw StateError('Gemma is disabled in ${AppConfig.current.name} environment');
    }

    final stopwatch = Stopwatch()..start();
    final config = request.config;
    final prompt = request.effectivePrompt;

    _logger.d('Gemma: Generating with ${config.modelId}');

    try {
      final response = await http.post(
        Uri.parse('$_functionsBase/python-extract/gemma'),
        headers: {
          'Content-Type': 'application/json',
          'X-Environment': AppConfig.current.name,
        },
        body: jsonEncode({
          'prompt': prompt,
          'model': config.modelId,
          'temperature': config.temperature,
          'max_tokens': config.maxTokens ?? 1024,
          if (request.systemInstruction != null)
            'system_instruction': request.systemInstruction,
          if (request.outputMode == 'json')
            'response_mime_type': 'application/json',
        }),
      ).timeout(Duration(seconds: _timeoutForModel(config.modelId)));

      stopwatch.stop();

      if (response.statusCode != 200) {
        throw Exception('Gemma proxy returned ${response.statusCode}: ${response.body}');
      }

      final result = jsonDecode(response.body);
      final text = result['text'] as String? ?? result['response'] as String? ?? '';
      final modelUsed = result['model_used'] as String? ?? config.modelId;

      return AIGenerationResult(
        text: text,
        modelUsed: modelUsed,
        strategyUsed: name,
        confidence: 0.9,
        latency: stopwatch.elapsed,
      );
    } catch (e) {
      _logger.e('Gemma: Generation failed', error: e);
      rethrow;
    }
  }

  /// Timeout based on model size: smaller = faster.
  static int _timeoutForModel(String modelId) {
    if (modelId.contains('270m') || modelId.contains('functiongemma')) return 5;
    if (modelId.contains('4b')) return 10;
    if (modelId.contains('27b')) return 30;
    return 15;
  }
}
