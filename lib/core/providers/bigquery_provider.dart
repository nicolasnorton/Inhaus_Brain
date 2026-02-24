import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bigquery_service.dart';

/// Provider for BigQueryService
final bigQueryServiceProvider = Provider<BigQueryService>((ref) {
  return BigQueryService();
});

/// FutureProvider for AI Performance metrics from BigQuery
final aiPerformanceMetricsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final bq = ref.watch(bigQueryServiceProvider);
  return bq.getAiPerformanceMetrics(days: days);
});

/// FutureProvider for Usage metrics from BigQuery
final usageMetricsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final bq = ref.watch(bigQueryServiceProvider);
  return bq.getUsageMetrics(days: days);
});
