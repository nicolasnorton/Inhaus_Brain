
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
}

final telemetryServiceProvider = Provider<TelemetryService>((ref) => TelemetryService());
