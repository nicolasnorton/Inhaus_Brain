import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';

/// Analytics Service (Inhaus Brain v1.3)
/// 
/// Logs structured events to Firestore, which are then streamed to BigQuery via Cloud Functions.
/// Used for tracking AI Profitability (Token Usage), Error Rates, and Agent Performance.
class AnalyticsService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AnalyticsService(this._ref);

  /// Log a generic event
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .add({
        'name': eventName,
        'parameters': parameters ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
      });
    } catch (e) {
      debugPrint('Analytics: Failed to log event $eventName: $e');
    }
  }

  /// Log AI Generation Usage (Cost Tracking)
  Future<void> logAiUsage({
    required String modelId,
    required String provider,
    required int inputTokens, // Estimated or actual
    required int outputTokens, // Estimated or actual
    required double latencyMs,
    required bool isCacheHit,
    String? agentName,
  }) async {
    await logEvent('ai_generation', parameters: {
      'model_id': modelId,
      'provider': provider,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'latency_ms': latencyMs,
      'is_cache_hit': isCacheHit,
      'agent': agentName ?? 'unknown',
    });
  }

  /// Log Agent Action
  Future<void> logAgentAction({
    required String agentName,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    await logEvent('agent_action', parameters: {
      'agent': agentName,
      'action': action,
      ...(metadata ?? {}),
    });
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref);
});
