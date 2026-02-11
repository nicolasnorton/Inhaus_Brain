import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';

/// Audit Log Service (Inhaus Brain v2.0 Production)
/// 
/// Provides a tamper-evident record of security-sensitive actions.
/// Logs are stored in a top-level `audit_logs` collection.
class AuditLogService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuditLogService(this._ref);

  /// Log a security-sensitive event
  Future<void> log({
    required String action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? metadata,
    bool isCritical = false,
  }) async {
    final user = _ref.read(authServiceProvider).currentUser;
    // We log even if user is null for login attempts, but we try to capture whatever we have
    
    final logData = {
      'timestamp': FieldValue.serverTimestamp(),
      'actorId': user?.uid ?? 'system/anonymous',
      'actorEmail': user?.email ?? 'anonymous',
      'action': action,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'metadata': {
        ...(metadata ?? {}),
        'platform': kIsWeb ? 'web' : 'mobile',
        'isCritical': isCritical,
        'userAgent': kIsWeb ? 'web-browser' : 'app-client', // Simplified
      },
    };

    try {
      await _firestore.collection('audit_logs').add(logData);
      
      if (kDebugMode) {
        print('AuditLog: Recorded $action by ${user?.email ?? "anonymous"}');
      }
    } catch (e) {
      // In a real production system, we might want to fallback to local storage 
      // or a secondary logging service if Firestore fails
      debugPrint('AuditLog: CRITICAL FAILURE failing to log $action: $e');
    }
  }

  /// Convenience methods for common actions
  Future<void> logLogin(String email) => log(
    action: 'auth/login',
    metadata: {'email': email},
    isCritical: true,
  );

  Future<void> logLogout() => log(action: 'auth/logout');

  Future<void> logPermissionChange({
    required String targetUserId,
    required String oldRole,
    required String newRole,
  }) => log(
    action: 'security/role-change',
    resourceType: 'user',
    resourceId: targetUserId,
    metadata: {'oldRole': oldRole, 'newRole': newRole},
    isCritical: true,
  );

  Future<void> logDataDeletion({
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? details,
  }) => log(
    action: 'data/delete',
    resourceType: resourceType,
    resourceId: resourceId,
    metadata: details,
    isCritical: true,
  );
}

final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  return AuditLogService(ref);
});
