
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
  return service.getReports('client_1');
});

final clientReportsProvider = StreamProvider.family.autoDispose<List<Report>, String>((ref, clientId) {
  final service = ref.watch(reportsServiceProvider);
  return service.getReports(clientId);
});

// Single Report Provider (Detail View)
final reportProvider = FutureProvider.family.autoDispose<Report?, String>((ref, id) async {
  final service = ref.watch(reportsServiceProvider);
  return service.getReport(id);
});
