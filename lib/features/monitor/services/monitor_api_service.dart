import 'package:uuid/uuid.dart';
import '../models/monitor_models.dart';

/// Service for interacting with monitoring and logging API
class MonitorApiService {
  static const _uuid = Uuid();

  /// Fetch metrics for a specific app
  Future<MetricSummary> getMetricSummary(String appId) async {
    // Mock API delay
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
    int limit = 50,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate mock logs
    final logs = List.generate(limit, (i) {
      final logId = _uuid.v4();
      final levelIndex = i % 10 == 0 ? 2 : (i % 5 == 0 ? 1 : 0);
      return LogEntry(
        id: logId,
        appId: appId,
        timestamp: DateTime.now().subtract(Duration(minutes: i * 5)),
        level: LogLevel.values[levelIndex],
        message: _getMockMessage(levelIndex, i),
        traceId: 'tr_${_uuid.v4().substring(0, 8)}',
        metadata: {
          'node_id': 'node_$i',
          'execution_time': '${200 + i * 10}ms',
          'tokens': 150 + i,
        },
      );
    });

    // Apply filtering
    return logs.where((log) {
      if (level != null && log.level != level) return false;
      if (query != null && !log.message.contains(query)) return false;
      return true;
    }).toList();
  }

  /// Submit an annotation for a log entry
  Future<Annotation> submitAnnotation(Annotation annotation) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return annotation;
  }

  String _getMockMessage(int level, int index) {
    if (level == 2) return 'Critical error in LLM Node: Connection timeout at step $index';
    if (level == 1) return 'High latency detected in Knowledge Retrieval: ${400 + index * 50}ms';
    return 'Execution completed successfully for trace tr_$index';
  }
}
