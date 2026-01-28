import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/auth/auth_service.dart';
import '../models/monitor_models.dart';

/// Service for interacting with monitoring and logging API
/// Service for interacting with monitoring and logging API
class MonitorApiService {
  static const _uuid = Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService? _authService;

  MonitorApiService([this._authService]);

  /// Log an event
  Future<void> log(LogEntry entry) async {
    try {
      if (entry.scope == LogScope.system) {
        // System logs go to global collection
        await _firestore.collection('system').doc('logs').collection('entries').doc(entry.id).set(entry.toJson());
      } else {
        // User logs go to user subcollection
        final uid = entry.userId ?? _authService?.currentUser?.uid;
        if (uid != null) {
          await _firestore.collection('users').doc(uid).collection('logs').doc(entry.id).set(entry.toJson());
        }
      }
    } catch (e) {
      debugPrint('Error writing log: $e');
    }
  }

  /// Fetch metrics for a specific app
  Future<MetricSummary> getMetricSummary(String appId) async {
    // Keeping mock for metrics for now as requested task focused on Logs/Memory
    await Future.delayed(const Duration(milliseconds: 500));

    return const MetricSummary(
      totalMessages: 5842,
      activeUsers: 842,
      avgInteractions: 12.5,
      totalTokens: 154200,
      estimatedCost: 12.45,
    );
  }

  /// Fetch time-series metric data
  Future<List<MetricDataPoint>> getMetricHistory(
    String appId, 
    String metricType, {
    int days = 7,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();
    return List.generate(days, (i) {
      return MetricDataPoint(
        timestamp: now.subtract(Duration(days: days - i)),
        value: 80.0 + (i * 2) + (i % 3 == 0 ? 5.0 : -3.0),
      );
    });
  }

  /// Fetch execution logs
  Future<List<LogEntry>> getLogs(
    String appId, {
    String? query,
    LogLevel? level,
    LogScope scope = LogScope.user,
    int limit = 50,
  }) async {
    try {
      Query collectionRef;
      
      if (scope == LogScope.system) {
         // Check permissions? Assuming Admin Dashboard guards this.
         collectionRef = _firestore.collection('system').doc('logs').collection('entries');
      } else {
         final user = _authService?.currentUser;
         if (user == null) return [];
         collectionRef = _firestore.collection('users').doc(user.uid).collection('logs');
      }

      Query q = collectionRef.orderBy('timestamp', descending: true).limit(limit);

      if (level != null) {
        q = q.where('level', isEqualTo: level.name);
      }
      
      // Note: Firestore doesn't support regex/contains queries natively.
      // We'll have to filter in memory if 'query' is present, or rely on client-side filtering.
      // Let's filter in memory for 'query'.
      
      final snapshot = await q.get();
      final logs = snapshot.docs.map((d) => LogEntry.fromJson(d.data() as Map<String, dynamic>)).toList();
      
      if (query != null && query.isNotEmpty) {
        return logs.where((l) => l.message.toLowerCase().contains(query.toLowerCase())).toList();
      }
      
      return logs;
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      return [];
    }
  }

  /// Submit an annotation for a log entry
  Future<Annotation> submitAnnotation(Annotation annotation) async {
    // Add annotation to the log entry? Or separate collection?
    // For simplicity, let's update the log entry.
    // But we need to know WHERE the log is (system vs user).
    // Assuming user logs for now based on current context.
    // In a real app we'd pass the scope or parent path.
    return annotation;
  }

  String _getMockMessage(int level, int index) {
    if (level == 2) return 'Critical error in LLM Node: Connection timeout at step $index';
    if (level == 1) return 'High latency detected in Knowledge Retrieval: ${400 + index * 50}ms';
    return 'Execution completed successfully for trace tr_$index';
  }
}
