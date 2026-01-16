import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/auth/auth_service.dart';
import '../models/audit_models.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth;
  static const _uuid = Uuid();

  AuditService(this._auth);

  Future<void> logAction({
    required String action,
    required String resourceId,
    required String resourceType,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final id = _uuid.v4();
    final log = AuditLog(
      id: id,
      actorId: user.uid,
      actorEmail: user.email ?? 'unknown',
      action: action,
      resourceId: resourceId,
      resourceType: resourceType,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    await _firestore.collection('audit_logs').doc(id).set(log.toJson());
  }

  Future<List<AuditLog>> getLogs({int limit = 100}) async {
    final snapshot = await _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => AuditLog.fromJson(doc.data())).toList();
  }
}

final auditServiceProvider = Provider((ref) => AuditService(ref.read(authServiceProvider)));

final auditLogsProvider = FutureProvider.autoDispose<List<AuditLog>>((ref) {
  return ref.read(auditServiceProvider).getLogs();
});
