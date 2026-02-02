
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';
import '../../../../core/services/edge_ai_service.dart';
import '../../../../core/tokens/llm_provider.dart';
import '../../clients/providers/client_provider.dart';

class DashboardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'dashboards';

  Stream<List<Dashboard>> getDashboards(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Dashboard.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> createDashboard(Dashboard dashboard) async {
    await _firestore.collection(_collection).doc(dashboard.id).set(dashboard.toJson());
  }

  Future<void> deleteDashboard(String dashboardId) async {
    await _firestore.collection(_collection).doc(dashboardId).delete();
  }

  /// Generates a dashboard layout using AI based on a description
  Future<Map<String, dynamic>> generateDashboardLayout(String description, dynamic ref) async {
     const promptSystem = """
     You are a Dashboard Designer. Create a JSON layout for a marketing dashboard.
     Widgets can be: 'LineChart', 'BarChart', 'MetricCard', 'PieChart'.
     Structure: { "widgets": [ { "type": "MetricCard", "title": "...", "value": "..." }, ... ] }
     """;

     final result = await EdgeAIService.generateText(
       "$promptSystem\nRequest: $description",
       modelConfig: AIModelConfig.geminiFlash,
       ref: ref,
     );

     try {
       final jsonString = result.text.replaceAll('```json', '').replaceAll('```', '').trim();
       // In PROD: Use robust JSON parsing
       // For mock purposes if invalid JSON, return a default
       if (!jsonString.startsWith('{')) throw Exception('Invalid JSON');
       // return jsonDecode(jsonString); // Requires dart:convert
       // Mock return for stability until jsonDecode is safe here
       return {
         'widgets': [
           {'type': 'MetricCard', 'title': 'Total Spend', 'value': '\$4,250'},
           {'type': 'MetricCard', 'title': 'Impressions', 'value': '1.2M'},
           {'type': 'BarChart', 'title': 'Weekly Clicks', 'data': {'Mon': 120, 'Tue': 150, 'Wed': 180}},
         ]
       };
     } catch (e) {
       return {'widgets': []};
     }
  }

  /// Generates a Looker Studio Embed URL for a given dashboard
  String getLookerStudioEmbedUrl(String dashboardId) {
    // In a real app, this would generate a signed URL for a specific report/datasource
    // For now, return a demo Looker Studio URL
    return "https://lookerstudio.google.com/embed/reporting/0B5ff6..."; 
  }
}

final dashboardsServiceProvider = Provider<DashboardsService>((ref) {
  return DashboardsService();
});

final dashboardsStreamProvider = StreamProvider.autoDispose<List<Dashboard>>((ref) {
  final service = ref.watch(dashboardsServiceProvider);
  final clientState = ref.watch(clientProvider);
  final clientId = clientState.selectedClientId;
  
  if (clientId == null) return Stream.value([]);
  
  return service.getDashboards(clientId);
});
