
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class TelemetryService {
  final _logger = Logger();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Log User Feedback (Thumbs Up/Down)
  Future<void> logFeedback({
    required String messageId,
    required String content,
    required bool isPositive,
    String? modelName,
    double? confidenceScore,
  }) async {
    final rating = isPositive ? 'positive' : 'negative';
    
    // 1. Log to Console (Dev)
    _logger.i('[Telemetry] Feedback: $rating for msg $messageId (Model: $modelName)');

    // 2. Log to Firebase Analytics
    try {
      await _analytics.logEvent(
        name: 'ai_feedback',
        parameters: {
          'message_id': messageId,
          'rating': rating,
          'model_name': modelName ?? 'unknown',
          'content_length': content.length,
          'confidence': confidenceScore ?? -1.0, 
          // Note: Avoid logging full PII content. Just metrics.
          // In a real secure environment, we might log a hash of the content.
        },
      );
    } catch (e) {
      _logger.w('Failed to log analytics event: $e');
    }

    // 3. Log to Cloud Logging (Simulated via print for now, would use a logging agent)
    // Ideally, we'd fire a structured log entry here.
  }

  // Log Detailed Interaction (Audit Trail)
  Future<void> logInteraction({
    required String agentName,
    required String action,
    required double durationMs,
    bool success = true,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'agent_interaction',
        parameters: {
          'agent': agentName,
          'action': action,
          'duration_ms': durationMs,
          'success': success ? 1 : 0,
        },
      );
    } catch (e) {
      // Ignore analytics errors
    }
  }

  // Log Knowledge Ingestion Performance
  Future<void> logKnowledgeIngestion({
    required String type,
    required int docCount,
    required double durationMs,
    bool success = true,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'kb_ingestion',
        parameters: {
          'source_type': type,
          'doc_count': docCount,
          'duration_ms': durationMs,
          'success': success ? 1 : 0,
        },
      );
    } catch (_) {}
  }

  // Log RAG Query Performance
  Future<void> logKnowledgeQuery({
    required String query,
    required int chunkCount,
    required double durationMs,
    bool cacheHit = false,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'kb_query',
        parameters: {
          'chunk_count': chunkCount,
          'duration_ms': durationMs,
          'cache_hit': cacheHit ? 1 : 0,
        },
      );
    } catch (_) {}
  }
  // Log Video Generation Performance
  Future<void> logVideoGeneration({
    required String modelId,
    required bool isPreview,
    required double durationMs,
    required bool success,
    String? errorReason,
    bool isFallback = false,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'video_generation',
        parameters: {
          'model_id': modelId,
          'is_preview': isPreview ? 1 : 0,
          'duration_ms': durationMs,
          'success': success ? 1 : 0,
          'error': errorReason ?? 'none',
          'is_fallback': isFallback ? 1 : 0,
        },
      );
      _logger.i('[Telemetry] Video Gen ($modelId): ${success ? "Success" : "Fail"} in ${durationMs}ms (Fallback: $isFallback)');
    } catch (_) {}
  }

  /// Log AI generation with model-tier tracking.
  ///
  /// Tracks which strategy (vertex_ai, gemma, litert, proxy, cache)
  /// was used, the model tier, and latency for cost optimization.
  Future<void> logAiGeneration({
    required String modelId,
    required String strategy,
    required double latencyMs,
    required bool success,
    String? modelTier,    // 'pro', 'flash', 'flash-lite', 'gemma-fast', 'litert'
    bool isCacheHit = false,
    bool isFallback = false,
    int? inputTokenEstimate,
    int? outputTokenEstimate,
    String? errorReason,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'ai_generation',
        parameters: {
          'model_id': modelId,
          'strategy': strategy,
          'model_tier': modelTier ?? _inferTier(modelId),
          'latency_ms': latencyMs,
          'success': success ? 1 : 0,
          'cache_hit': isCacheHit ? 1 : 0,
          'is_fallback': isFallback ? 1 : 0,
          'input_tokens': inputTokenEstimate ?? 0,
          'output_tokens': outputTokenEstimate ?? 0,
          'error': errorReason ?? 'none',
        },
      );
      _logger.d('[Telemetry] AI Gen: $strategy/$modelId (${modelTier ?? _inferTier(modelId)}) ${latencyMs}ms ${success ? "✓" : "✗"} ${isCacheHit ? "[CACHE]" : ""}');
    } catch (_) {}
  }

  /// Infer model tier from model ID for analytics grouping.
  String _inferTier(String modelId) {
    if (modelId.contains('pro')) return 'pro';
    if (modelId.contains('flash-lite') || modelId.contains('flashlite')) return 'flash-lite';
    if (modelId.contains('flash')) return 'flash';
    if (modelId.contains('gemma-3-27b')) return 'gemma-quality';
    if (modelId.contains('gemma-3-4b')) return 'gemma-fast';
    if (modelId.contains('functiongemma')) return 'functiongemma';
    if (modelId.contains('translategemma')) return 'translategemma';
    if (modelId.contains('gemma-2b') || modelId.contains('litert')) return 'litert';
    return 'unknown';
  }

  
  // Log Role Actions (RBAC)
  Future<void> logRoleAction({
    required String role,
    required String action,
    String? resourceId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'rbac_action',
        parameters: {
          'user_role': role,
          'action': action,
          'resource_id': resourceId ?? 'n/a',
        },
      );
      _logger.d('[Telemetry] RBAC: $role performed $action on ${resourceId ?? "global"}');
    } catch (_) {}
  }
}

final telemetryServiceProvider = Provider<TelemetryService>((ref) => TelemetryService());
