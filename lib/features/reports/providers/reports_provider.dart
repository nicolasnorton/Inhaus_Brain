
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../services/reports_service.dart';
import '../../clients/providers/client_provider.dart';

// Service Provider
final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService();
});

// Stream of Reports for the SELECTED client (was hardcoded to 'client_1')
final reportsStreamProvider = StreamProvider.autoDispose<List<Report>>((ref) {
  final selectedClient = ref.watch(selectedClientProvider);
  if (selectedClient == null) return Stream.value(<Report>[]);
  final service = ref.watch(reportsServiceProvider);
  return service.getReports(selectedClient.id);
});

// Stream of Reports for a specific client (used by client detail screens)
final clientReportsProvider = StreamProvider.family.autoDispose<List<Report>, String>((ref, clientId) {
  final service = ref.watch(reportsServiceProvider);
  return service.getReports(clientId);
});

// Single Report Provider (Detail View)
final reportProvider = FutureProvider.family.autoDispose<Report?, String>((ref, id) async {
  final service = ref.watch(reportsServiceProvider);
  return service.getReport(id);
});
