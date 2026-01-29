
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../services/reports_service.dart';

// Service Provider
final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService();
});

// Stream of Reports (Main Dashboard)
// Note: In a real app, 'clientId' might come from an Auth/User provider. 
// For now, we hardcode to 'client_1' or fetch from a hypothetical user state.
final reportsStreamProvider = StreamProvider.autoDispose<List<Report>>((ref) {
  final service = ref.watch(reportsServiceProvider);
  // TODO: Replace with actual logged-in user's client ID or context
  // For dev/demo, we assume 'client_1' or 'current_user_id' matches standard.
  // To make it easy to see "all" our dev reports, we might filter less strictly or pass the ID dynamically.
  // For now, let's just assume we want to see reports for 'client_1' which represents the main user context.
  return service.getReports('client_1');
});

// Single Report Provider (Detail View)
final reportProvider = FutureProvider.family.autoDispose<Report?, String>((ref, id) async {
  final service = ref.watch(reportsServiceProvider);
  return service.getReport(id);
});
