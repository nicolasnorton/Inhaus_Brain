
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  /// Get stream of reports for a specific client (or user).
  /// For Inhaus Brain, we might filter by clientId.
  Stream<List<Report>> getReports(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Report.fromJson(doc.data()))
          .toList();
    });
  }

  /// Get a single report by ID.
  Future<Report?> getReport(String reportId) async {
    final doc = await _firestore.collection(_collection).doc(reportId).get();
    if (doc.exists && doc.data() != null) {
      return Report.fromJson(doc.data()!);
    }
    return null;
  }

  /// Create a new report.
  Future<void> createReport(Report report) async {
    await _firestore.collection(_collection).doc(report.id).set(report.toJson());
  }

  /// Update an existing report (e.g. adding sources).
  Future<void> updateReport(Report report) async {
    await _firestore
        .collection(_collection)
        .doc(report.id)
        .update(report.toJson());
  }
  
  /// Delete a report
  Future<void> deleteReport(String reportId) async {
    await _firestore.collection(_collection).doc(reportId).delete();
  }
}
