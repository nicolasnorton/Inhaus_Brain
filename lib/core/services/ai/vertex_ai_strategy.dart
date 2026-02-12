/// Vertex AI strategy — primary cloud generation path.
///
/// Uses the Firebase AI SDK for Gemini 2.5 Pro/Flash/Flash-Lite.
/// Supports multimodal input, streaming, Google Search grounding,
/// code execution, and safety filters.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:logger/logger.dart';
import 'ai_strategy.dart';
import 'ai_generation_request.dart';
import '../../tokens/llm_provider.dart';

class VertexAIStrategy extends AIStrategy {
  static final _logger = Logger();

  @override
  String get name => 'vertex_ai';

  @override
  bool get supportsStreaming => true;

  @override
  Future<AIGenerationResult> generate(AIGenerationRequest request) async {
    final stopwatch = Stopwatch()..start();
    final config = request.config;
    final prompt = request.effectivePrompt;

    _logger.d('VertexAI: Generating with ${config.modelId}');

    final ai = FirebaseAI.vertexAI();
    final model = ai.generativeModel(
      model: config.modelId,
      generationConfig: GenerationConfig(
        temperature: config.temperature,
        maxOutputTokens: config.maxTokens ?? 2048,
        responseMimeType: config.responseMimeType,
      ),
      safetySettings: _safetySettings,
      tools: _buildTools(config),
    );

    final parts = _buildParts(prompt, request);
    final content = Content.multi(parts);
    final response = await model.generateContent([content]);

    stopwatch.stop();
    return _parseResponse(response, config, stopwatch.elapsed);
  }

  @override
  Stream<AIGenerationResult> generateStream(AIGenerationRequest request) async* {
    final config = request.config;
    final prompt = request.effectivePrompt;

    final ai = FirebaseAI.vertexAI();
    final model = ai.generativeModel(
      model: config.modelId,
      generationConfig: GenerationConfig(
        temperature: config.temperature,
        maxOutputTokens: config.maxTokens,
        responseMimeType: config.responseMimeType,
      ),
      safetySettings: _safetySettings,
    );

    final parts = _buildParts(prompt, request);
    final content = Content.multi(parts);
    final stream = model.generateContentStream([content]);

    String accumulated = '';

    await for (final chunk in stream) {
      if (chunk.text != null && chunk.text!.isNotEmpty) {
        accumulated += chunk.text!;
        yield AIGenerationResult(
          text: accumulated,
          modelUsed: config.modelId,
          strategyUsed: name,
        );
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  List<Part> _buildParts(String prompt, AIGenerationRequest request) {
    final parts = <Part>[TextPart(prompt)];
    if (request.imageBytes != null) {
      parts.add(InlineDataPart(request.imageMimeType ?? 'image/jpeg', request.imageBytes!));
    }
    if (request.audioBytes != null) {
      parts.add(InlineDataPart(request.audioMimeType ?? 'audio/mp3', request.audioBytes!));
    }
    if (request.videoBytes != null) {
      parts.add(InlineDataPart(request.videoMimeType ?? 'video/mp4', request.videoBytes!));
    }
    if (request.pdfBytes != null) {
      parts.add(InlineDataPart(request.pdfMimeType ?? 'application/pdf', request.pdfBytes!));
    }
    return parts;
  }

  List<Tool> _buildTools(AIModelConfig config) {
    // Code Execution is incompatible with JSON mode
    if (config.responseMimeType == 'application/json') return [];
    return [
      Tool.codeExecution(),
      if (config.useGoogleSearch) Tool.googleSearch(),
    ];
  }

  static final _safetySettings = [
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high, HarmBlockMethod.probability),
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high, HarmBlockMethod.probability),
    SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high, HarmBlockMethod.probability),
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high, HarmBlockMethod.probability),
  ];

  AIGenerationResult _parseResponse(
    GenerateContentResponse response,
    AIModelConfig config,
    Duration latency,
  ) {
    String fullText = response.text ?? '';

    if (fullText.isEmpty && response.candidates.isNotEmpty) {
      final buffer = StringBuffer();
      for (var part in response.candidates.first.content.parts) {
        if (part is TextPart) {
          buffer.write(part.text);
        } else if (part is FunctionCall) {
          buffer.write(jsonEncode({'tool': part.name, 'args': part.args}));
        } else if (part is FunctionResponse) {
          buffer.write('\n**Function Result:** ${part.response}');
        } else if (part is ExecutableCodePart) {
          String code = part.code.trim();
          if (code.startsWith('print(') && code.endsWith(')')) {
            code = code.substring(6, code.length - 1);
          }
          buffer.write(code);
        } else {
          debugPrint('VertexAI: Unknown part type: ${part.runtimeType}');
          buffer.write(part.toString());
        }
      }
      fullText = buffer.toString();
    }

    if (fullText.trim().isEmpty) {
      fullText = 'No content generated. (Empty Response)';
    }

    // Grounding sources
    List<String> sources = [];
    if (response.candidates.isNotEmpty) {
      final grounding = response.candidates.first.groundingMetadata;
      if (grounding != null && grounding.groundingChunks.isNotEmpty) {
        sources = grounding.groundingChunks
            .map((c) => c.web?.uri?.toString())
            .whereType<String>()
            .toSet()
            .toList();
        if (sources.isNotEmpty) {
          fullText += '\n\n**Sources:** ${sources.join(', ')}';
        }
      }
    }

    // Confidence
    double confidence = 1.0;
    if (response.candidates.isNotEmpty) {
      final candidate = response.candidates.first;
      if (candidate.finishReason != FinishReason.stop) {
        confidence = 0.5;
        if (candidate.finishReason == FinishReason.safety ||
            candidate.finishReason == FinishReason.recitation) {
          confidence = 0.0;
        }
      }
    }

    // Strip markdown wrapper from JSON responses
    if (config.responseMimeType == 'application/json') {
      fullText = _stripMarkdown(fullText);
    }

    return AIGenerationResult(
      text: fullText,
      modelUsed: config.modelId,
      strategyUsed: name,
      confidence: confidence,
      sourceCitations: sources,
      latency: latency,
    );
  }

  static String _stripMarkdown(String text) {
    if (text.startsWith('```')) {
      final firstLineEnd = text.indexOf('\n');
      final lastBackticks = text.lastIndexOf('```');
      if (firstLineEnd != -1 && lastBackticks > firstLineEnd) {
        return text.substring(firstLineEnd + 1, lastBackticks).trim();
      }
    }
    return text.trim();
  }
}
