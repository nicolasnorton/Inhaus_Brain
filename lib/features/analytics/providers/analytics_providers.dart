import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_orchestrator_service.dart';

final analyticsOrchestratorProvider = Provider<AnalyticsOrchestratorService>((ref) {
  return AnalyticsOrchestratorService();
});

final dashboardDataProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, query) async {
  final service = ref.watch(analyticsOrchestratorProvider);
  return service.generateDashboard(query);
});
