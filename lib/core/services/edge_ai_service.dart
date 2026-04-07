/// EdgeAIService — thin facade for all AI generation.
///
/// Delegates actual generation to the AI strategy layer via [AIRouter].
/// This file was reduced from 715→~160 LOC in the strategy pattern refactor.
///
/// Public API preserved for backward compatibility:
/// - [generateText] → AIRouter.generate()
/// - [generateTextStream] → AIRouter.generateStream()
/// - [generateImage] → Proxy / VertexAI
/// - [generateVideo] → VideoGenerationService
/// - [generateAudio] → Local asset (mocked)
library;

import 'dart:async';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../features/knowledge/models/knowledge_source.dart';
import '../tokens/llm_provider.dart';

import 'ai_proxy_service.dart';
import 'video_generation_service.dart';
import 'telemetry_service.dart';
import 'semantic_cache_service.dart';
import 'analytics_service.dart';
import 'ai/ai_generation_request.dart';
import 'ai/ai_router.dart';
import 'ai/litert_strategy.dart';

enum AIProximity {
  local,     // Chrome Prompt API or Gemini Nano
  cloud,     // Vertex AI
  simulated  // Dynamic Edge Mock
}

class AIProximityNotifier extends Notifier<AIProximity> {
  @override
  AIProximity build() => AIProximity.simulated;

  void setProximity(AIProximity proximity) {
    state = proximity;
  }
}

final aiProximityProvider = NotifierProvider<AIProximityNotifier, AIProximity>(AIProximityNotifier.new);

class EdgeAIResult {
  final String text;
  final AIProximity proximity;
  final String? modelUsed;
  final double confidence;
  final List<String>? sourceCitations;
  final String? interactionId;

  EdgeAIResult(this.text, this.proximity, {this.modelUsed, this.confidence = 1.0, this.sourceCitations, this.interactionId});
}

class EdgeAIService {
  static bool forceMock = false;
  static final _logger = Logger();

  /// Generate text via the AI strategy layer.
  static Future<EdgeAIResult> generateText(
    String prompt, {
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    String? systemInstruction,
    String? outputMode,
    Uint8List? imageBytes,
    String? imageMimeType,
    Uint8List? audioBytes,
    String? audioMimeType,
    Uint8List? videoBytes,
    String? videoMimeType,
    Uint8List? pdfBytes,
    String? pdfMimeType,
    AIModelConfig? modelConfig,
    String? apiKey,
    String? gemmaKey,
    String? vertexKey,
    List<Map<String, dynamic>>? tools,
    String? previousInteractionId,
    dynamic ref,
  }) async {
    final effectiveMemory = memoryContext ?? systemInstruction;
    var config = modelConfig ?? AIModelConfig.geminiFlash;

    if (outputMode == 'json') {
      config = config.copyWith(responseMimeType: 'application/json');
    }

    // Build unified request
    final request = AIGenerationRequest(
      prompt: prompt,
      config: config,
      systemInstruction: effectiveMemory,
      outputMode: outputMode,
      context: context,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      audioBytes: audioBytes,
      audioMimeType: audioMimeType,
      videoBytes: videoBytes,
      videoMimeType: videoMimeType,
      pdfBytes: pdfBytes,
      pdfMimeType: pdfMimeType,
      tools: tools,
      previousInteractionId: previousInteractionId,
      apiKey: apiKey,
      vertexKey: vertexKey,
    );

    // --- SEMANTIC CACHE CHECK ---
    if (ref != null && !forceMock) {
      try {
        final cache = ref.read(semanticCacheServiceProvider);
        final cachedResult = await cache.get(request.effectivePrompt, config);
        if (cachedResult != null) {
          _logger.i('EdgeAI: Cache HIT');
          ref.read(aiProximityProvider.notifier).setProximity(AIProximity.local);
          ref.read(analyticsServiceProvider).logAiUsage(
            modelId: config.modelId,
            provider: 'cache',
            inputTokens: request.effectivePrompt.length ~/ 4,
            outputTokens: cachedResult.text.length ~/ 4,
            latencyMs: 50.0,
            isCacheHit: true,
          );
          return cachedResult;
        }
      } catch (e) {
        _logger.w('EdgeAI: Cache check failed: $e');
      }
    }

    final stopwatch = Stopwatch()..start();
    _logger.d('EdgeAI: Generating via ${config.provider} (${config.modelId})');

    if (forceMock) {
      return EdgeAIResult('Edge Mock: Analyzed request locally. (Simulated Response)', AIProximity.simulated);
    }

    try {
      final result = await AIRouter.generate(request, ref: ref)
          .timeout(const Duration(seconds: 120));

      stopwatch.stop();

      // Convert strategy result to EdgeAIResult
      final edgeResult = EdgeAIResult(
        result.text,
        result.strategyUsed == 'litert' ? AIProximity.local : AIProximity.cloud,
        modelUsed: result.modelUsed,
        confidence: result.confidence,
        sourceCitations: result.sourceCitations.isEmpty ? null : result.sourceCitations,
        interactionId: result.interactionId,
      );

      // Cache + Analytics
      if (ref != null && edgeResult.confidence > 0.5) {
        try {
          ref.read(semanticCacheServiceProvider).set(request.effectivePrompt, config, edgeResult);
        } catch (_) {}
        try {
          ref.read(analyticsServiceProvider).logAiUsage(
            modelId: config.modelId,
            provider: config.provider.name,
            inputTokens: request.effectivePrompt.length ~/ 4,
            outputTokens: edgeResult.text.length ~/ 4,
            latencyMs: stopwatch.elapsedMilliseconds.toDouble(),
            isCacheHit: false,
          );
        } catch (_) {}
      }

      if (ref != null) {
        ref.read(aiProximityProvider.notifier).setProximity(edgeResult.proximity);
      }

      return edgeResult;
    } catch (e) {
      _logger.e('EdgeAI: Error: $e');
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      final errorResult = EdgeAIResult(
        'AI service temporarily unavailable. Please try again.\n\nDetails: $errorMsg',
        AIProximity.simulated,
        confidence: 0.0,
      );
      if (ref != null) ref.read(aiProximityProvider.notifier).setProximity(errorResult.proximity);
      return errorResult;
    }
  }

  /// Stream text via the AI strategy layer.
  static Stream<EdgeAIResult> generateTextStream(
    String prompt, {
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    String? systemInstruction,
    Uint8List? imageBytes,
    String? imageMimeType,
    Uint8List? audioBytes,
    String? audioMimeType,
    AIModelConfig? config,
    String? apiKey,
    String? previousInteractionId,
    dynamic ref,
  }) async* {
    final effectiveConfig = config ?? AIModelConfig.geminiFlash;
    final request = AIGenerationRequest(
      prompt: prompt,
      config: effectiveConfig,
      systemInstruction: memoryContext ?? systemInstruction,
      context: context,
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      audioBytes: audioBytes,
      audioMimeType: audioMimeType,
      previousInteractionId: previousInteractionId,
      apiKey: apiKey,
    );

    if (effectiveConfig.provider != AIProvider.gemini) {
      yield EdgeAIResult('Thinking...', AIProximity.simulated);
      yield await generateText(
        prompt,
        context: context,
        memoryContext: memoryContext ?? systemInstruction,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
        modelConfig: effectiveConfig,
        apiKey: apiKey,
        previousInteractionId: previousInteractionId,
        ref: ref,
      );
      return;
    }

    try {
      await for (final result in AIRouter.generateStream(request, ref: ref)) {
        yield EdgeAIResult(result.text, AIProximity.cloud, modelUsed: result.modelUsed, interactionId: result.interactionId);
      }
    } catch (e) {
      _logger.e('EdgeAI: Stream error: $e');
      yield EdgeAIResult('Stream Error: $e', AIProximity.simulated);
    }
  }

  /// Generate image via Nano Banana 2 (native Gemini image generation).
  static Future<String> generateImage(String prompt, {String? imagenKey, String? vertexKey, dynamic ref, Map<String, dynamic>? generationParams, String? modelId}) async {
    final effectiveModel = modelId ?? 'gemini-3.1-flash-image-preview';

    if (ref == null) throw Exception('Ref required for Image Proxy');
    final proxyResponse = await AIProxyService.generateNanoBanana(
      prompt: prompt,
      model: effectiveModel,
      responseModalities: const ['Image'],
      aspectRatio: generationParams?['aspectRatio'] as String?,
      imageSize: generationParams?['imageSize'] as String?,
    );

    // Parse generate_content response: candidates[0].content.parts[].inline_data
    final candidates = proxyResponse['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final parts = (candidates[0]['content']?['parts'] as List?) ?? [];
      for (final part in parts) {
        final inlineData = part['inline_data'] ?? part['inlineData'];
        if (inlineData != null) {
          final base64Image = inlineData['data'];
          final mimeType = inlineData['mime_type'] ?? inlineData['mimeType'] ?? 'image/png';
          if (base64Image != null) {
            return "data:$mimeType;base64,$base64Image";
          }
        }
      }
    }
    throw Exception('Image generation returned no images. Please try a different prompt.');
  }

  /// Generate video via VideoGenerationService.
  static Future<String> generateVideo(String prompt, {String? modelId, bool isFinal = false, bool includeSubtitles = false, String? veoKey, String? vertexKey, dynamic ref, Function(double)? onProgress, Function(String)? onStatusMessage}) async {
    final telemetry = ref?.read(telemetryServiceProvider);
    if (isFinal) {
      return await VideoGenerationService.generateFinal(prompt, modelId: modelId, confirmedByUser: true, onProgress: onProgress, onStatusMessage: onStatusMessage, telemetry: telemetry, includeSubtitles: includeSubtitles);
    } else {
      return await VideoGenerationService.generatePreview(prompt, modelId: modelId, onProgress: onProgress, onStatusMessage: onStatusMessage, telemetry: telemetry, includeSubtitles: includeSubtitles);
    }
  }

  /// Generate audio (mocked/static for now).
  static Future<String> generateAudio(String prompt, {String? lyriaKey}) async {
    debugPrint('EdgeAI: [AUDIO] Generating audio (MOCKED)');
    await Future.delayed(const Duration(milliseconds: 1500));
    return "assets/audio/success_chime.mp3";
  }

  /// Initialize LiteRT for on-device inference.
  static Future<void> initLiteRT() async {
    await LiteRTStrategy.init();
  }
}

