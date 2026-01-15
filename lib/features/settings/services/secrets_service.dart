import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_service.dart';

class SecretsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  SecretsService(this._authService);

  // --- System Secrets (Super Admin Only) ---

  Future<String> getSystemSecrets() async {
    if (!await _authService.isSuperAdmin) {
      throw Exception('Access Denied: Super Admin rights required.');
    }
    
    try {
      final doc = await _firestore.collection('system_config').doc('secrets').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['content'] as String? ?? '';
      }
      return ''; // Default empty
    } catch (e) {
      return ''; // Handle error or return empty
    }
  }

  Future<void> saveSystemSecrets(String content) async {
    if (!await _authService.isSuperAdmin) {
      throw Exception('Access Denied: Super Admin rights required.');
    }

    await _firestore.collection('system_config').doc('secrets').set({
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _authService.currentUser?.email,
    });
  }

  // --- User Secrets (User Level) ---

  Future<String> getUserSecrets() async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('secrets')
          .get();
      
      if (doc.exists && doc.data() != null) {
        return doc.data()!['content'] as String? ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<void> saveUserSecrets(String content) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('secrets')
        .set({
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final secretsServiceProvider = Provider<SecretsService>((ref) {
  return SecretsService(ref.watch(authServiceProvider));
});
