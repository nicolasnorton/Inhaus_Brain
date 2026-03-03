/// Unified request/result DTOs for the AI strategy layer.
///
/// All strategies accept [AIGenerationRequest] and return [AIGenerationResult].
/// This decouples callers from provider-specific APIs.
library;

import 'dart:typed_data';
import '../../tokens/llm_provider.dart';
import '../../../../features/knowledge/models/knowledge_source.dart';

/// Unified request for all AI generation strategies.
class AIGenerationRequest {
  final String prompt;
  final AIModelConfig config;
  final String? systemInstruction;
  final String? outputMode; // 'json' or null
  final List<KnowledgeSource> context;
  final List<Map<String, dynamic>>? tools;
  
  // Multimodal attachments
  final Uint8List? imageBytes;
  final String? imageMimeType;
  final Uint8List? audioBytes;
  final String? audioMimeType;
  final Uint8List? videoBytes;
  final String? videoMimeType;
  final Uint8List? pdfBytes;
  final String? pdfMimeType;
  final String? previousInteractionId;

  // Optional overrides
  final String? apiKey;
  final String? vertexKey;

  const AIGenerationRequest({
    required this.prompt,
    required this.config,
    this.systemInstruction,
    this.outputMode,
    this.context = const [],
    this.imageBytes,
    this.imageMimeType,
    this.audioBytes,
    this.audioMimeType,
    this.videoBytes,
    this.videoMimeType,
    this.pdfBytes,
    this.pdfMimeType,
    this.previousInteractionId,
    this.tools,
    this.apiKey,
    this.vertexKey,
  });

  /// Build effective prompt with knowledge context prepended.
  String get effectivePrompt {
    final buffer = StringBuffer();
    if (systemInstruction != null && systemInstruction!.isNotEmpty) {
      buffer.writeln(systemInstruction);
      buffer.writeln('-----------------------------------');
    }
    if (context.isNotEmpty) {
      buffer.writeln('CONTEXT FROM KNOWLEDGE BASE:');
      for (final source in context) {
        buffer.writeln('${source.title}: ${source.content.length > 200 ? source.content.substring(0, 200) : source.content}...');
      }
    }
    buffer.writeln('\nUSER PROMPT: $prompt');
    return buffer.toString();
  }

  /// True if request has any multimodal attachments.
  bool get isMultimodal =>
      imageBytes != null || audioBytes != null || videoBytes != null || pdfBytes != null;
}

/// Unified result from any AI generation strategy.
class AIGenerationResult {
  final String text;
  final String modelUsed;
  final String strategyUsed; // 'vertex_ai', 'gemma', 'litert', 'proxy', 'cache', 'mock'
  final double confidence;
  final List<String> sourceCitations;
  final Duration? latency;

  const AIGenerationResult({
    required this.text,
    required this.modelUsed,
    required this.strategyUsed,
    this.confidence = 1.0,
    this.sourceCitations = const [],
    this.latency,
  });

  AIGenerationResult copyWith({
    String? text,
    String? modelUsed,
    String? strategyUsed,
    double? confidence,
    List<String>? sourceCitations,
    Duration? latency,
  }) {
    return AIGenerationResult(
      text: text ?? this.text,
      modelUsed: modelUsed ?? this.modelUsed,
      strategyUsed: strategyUsed ?? this.strategyUsed,
      confidence: confidence ?? this.confidence,
      sourceCitations: sourceCitations ?? this.sourceCitations,
      latency: latency ?? this.latency,
    );
  }

  /// Convert to legacy EdgeAIResult for backward compat.
  /// (Will be removed once EdgeAIService is fully migrated.)
}
