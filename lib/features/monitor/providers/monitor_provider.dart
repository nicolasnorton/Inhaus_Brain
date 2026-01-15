import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monitor_models.dart';
import '../services/monitor_api_service.dart';

import '../../../core/auth/auth_service.dart';

/// Provider for MonitorApiService
final monitorApiServiceProvider = Provider((ref) {
  return MonitorApiService(ref.watch(authServiceProvider));
});

/// Provider for app metrics summary
final appMetricsProvider = FutureProvider.family<MetricSummary, String>((ref, appId) async {
  return ref.watch(monitorApiServiceProvider).getMetricSummary(appId);
});

/// Provider for metric history (time-series)
final metricHistoryProvider = FutureProvider.family<List<MetricDataPoint>, ({String appId, String metricType})>((ref, arg) async {
  return ref.watch(monitorApiServiceProvider).getMetricHistory(arg.appId, arg.metricType);
});

/// State for filtered logs
class LogSearchState {
  final String query;
  final LogLevel? level;

  LogSearchState({this.query = '', this.level});

  LogSearchState copyWith({String? query, LogLevel? level, bool clearLevel = false}) {
    return LogSearchState(
      query: query ?? this.query,
      level: clearLevel ? null : (level ?? this.level),
    );
  }
}

final logSearchProvider = StateProvider<LogSearchState>((ref) => LogSearchState());

/// Provider for execution logs
final appLogsProvider = FutureProvider.family<List<LogEntry>, String>((ref, appId) async {
  final search = ref.watch(logSearchProvider);
  return ref.watch(monitorApiServiceProvider).getLogs(
    appId,
    query: search.query.isEmpty ? null : search.query,
    level: search.level,
  );
});
