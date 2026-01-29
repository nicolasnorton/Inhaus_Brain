
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_model.dart';

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
}

final dashboardsServiceProvider = Provider<DashboardsService>((ref) {
  return DashboardsService();
});

final dashboardsStreamProvider = StreamProvider.autoDispose<List<Dashboard>>((ref) {
  final service = ref.watch(dashboardsServiceProvider);
  return service.getDashboards('client_1');
});
