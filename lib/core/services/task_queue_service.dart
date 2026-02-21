import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Task Queue Service (Inhaus Brain v2.0 Production)
/// 
/// Manages asynchronous task execution with support for 
/// backpressure, rate limiting, and remote dispatch (Cloud Tasks).
class TaskQueueService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // Local rate limiting for UI responsiveness
  final Map<String, _RateLimiter> _limiters = {};

  /// Enqueue an agent task for execution
  /// 
  /// In PRODUCTION mode, this dispatches to a Cloud Function which 
  /// then creates a Cloud Task for reliable, idempotent execution.
  Future<void> enqueueAgentTask({
    required String agentName,
    required String input,
    Map<String, dynamic>? metadata,
    bool useRemoteQueue = false,
  }) async {
    // 1. Check Rate Limit (e.g., max 5 agent triggers per minute per user)
    if (!_checkRateLimit('agent_execution', limit: 5, window: const Duration(minutes: 1))) {
      throw Exception('Rate limit exceeded. Please wait a moment.');
    }

    if (useRemoteQueue || kReleaseMode) {
      debugPrint('TaskQueue: Dispatching $agentName to remote queue...');
      try {
        await _functions.httpsCallable('enqueueAgentTask').call({
          'agentName': agentName,
          'input': input,
          'metadata': metadata ?? {},
        });
      } catch (e) {
        debugPrint('TaskQueue: Remote dispatch failed: $e');
        // Fallback or rethrow based on criticality
        rethrow;
      }
    } else {
      debugPrint('TaskQueue: Local execution requested for $agentName (Dev Mode)');
      // Local execution is typically handled by OrchestrationService directly
      // but we could wrap it here if we wanted a unified entry point.
    }
  }

  bool _checkRateLimit(String key, {required int limit, required Duration window}) {
    final limiter = _limiters.putIfAbsent(key, () => _RateLimiter(limit: limit, window: window));
    return limiter.allow();
  }
}

class _RateLimiter {
  final int limit;
  final Duration window;
  final List<DateTime> _history = [];

  _RateLimiter({required this.limit, required this.window});

  bool allow() {
    final now = DateTime.now();
    _history.removeWhere((dt) => now.difference(dt) > window);
    
    if (_history.length < limit) {
      _history.add(now);
      return true;
    }
    return false;
  }
}

final taskQueueServiceProvider = Provider<TaskQueueService>((ref) {
  return TaskQueueService();
});
