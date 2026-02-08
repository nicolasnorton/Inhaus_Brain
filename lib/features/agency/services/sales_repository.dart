
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agency_models.dart';

class SalesRepository {
  final FirebaseFirestore _firestore;

  SalesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<SalesLead>> getLeadsStream() {
    return _firestore
        .collection('sales_leads')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SalesLead(
          id: doc.id,
          name: data['name'] ?? 'Unknown',
          company: data['company'] ?? 'Unknown Company',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          status: _parseStatus(data['status']),
          estimatedValue: (data['estimatedValue'] ?? 0).toDouble(),
          lastContacted: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
          notes: data['notes'] ?? '',
        );
      }).toList();
    });
  }

  Future<void> updateLeadStatus(String leadId, LeadStatus status) async {
    await _firestore.collection('sales_leads').doc(leadId).update({
      'status': status.toString().split('.').last,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Helper to parse string status to enum
  LeadStatus _parseStatus(String? status) {
    if (status == null) return LeadStatus.newLead;
    return LeadStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => LeadStatus.newLead,
    );
  }
}
