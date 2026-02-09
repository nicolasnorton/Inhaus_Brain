import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';

/// Standard Severity Levels for Analytics
enum AnalyticsSeverity { info, warning, error, critical }

/// Service for logging app usage and system events to Firestore `events` collection.
/// These events are then streamed to BigQuery via Cloud Function.
class AnalyticsService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AnalyticsService(this._ref);

  /// Logs a structured event.
  /// 
  /// [type]: Short snake_case string identifying event (e.g., 'llm_generation_complete').
  /// [payload]: Arbitrary JSON-encodable map with details.
  /// [severity]: Importance level.
  Future<void> logEvent(
    String type, {
    Map<String, dynamic>? payload,
    String? agentId,
    AnalyticsSeverity severity = AnalyticsSeverity.info,
  }) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return; // Anonymous events currently ignored

    try {
      // Just generate session ID if needed or get from elsewhere?
      // Since Blackboard state doesn't have an explicit 'sessionId', we can use user ID + date or just omit for now.
      // The schema had 'session_id'. Let's default to null if not available.
      String? sessionId;
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .add({
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'agentId': agentId,
        'sessionId': sessionId,
        'payload': payload ?? {},
        'severity': severity.name.toUpperCase(), // Store as UPPERCASE in DB for consistency
        'clientPlatform': kIsWeb ? 'web' : 'mobile', // Simple platform check
      });
      
      debugPrint('[Analytics] Logged: $type');
    } catch (e) {
      // Fail silently to avoid interrupting user flow
      debugPrint('[Analytics] Failed to log event: $e');
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref);
});
