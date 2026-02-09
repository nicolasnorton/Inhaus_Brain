import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../architecture/blackboard.dart';
import '../auth/auth_service.dart';

/// Service responsible for saving and restoring the Blackboard state
/// to/from Firestore to enable session persistence.
class BlackboardPersistenceService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _debounceTimer;
  bool _isSaving = false;

  BlackboardPersistenceService(this._ref) {
    _initListener();
  }

  void _initListener() {
    // Listen to changes in the Blackboard state
    _ref.listen<BlackboardState>(blackboardProvider, (previous, next) {
      if (previous == next) return;
      _scheduleSave(next);
    });
  }

  void _scheduleSave(BlackboardState state) {
    // Debounce saves to avoid write amplification
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _saveSession(state);
    });
  }

  Future<void> _saveSession(BlackboardState state) async {
    if (_isSaving) return; // Prevent concurrent saves
    
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return; // Cannot save if not logged in

    _isSaving = true;
    try {
      final sessionRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc('active');

      await sessionRef.set({
        ...state.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('Persistence: Session saved successfully.');
    } catch (e) {
      debugPrint('Persistence: Error saving session: $e');
    } finally {
      _isSaving = false;
    }
  }

  Future<void> restoreSession() async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) {
      debugPrint('Persistence: Cannot restore session - No user logged in.');
      return;
    }

    try {
      final sessionDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc('active')
          .get();

      if (sessionDoc.exists && sessionDoc.data() != null) {
        final data = sessionDoc.data()!;
        final restoredState = BlackboardState.fromJson(data);
        
        debugPrint('Persistence: Restoring session state...');
        _ref.read(blackboardProvider.notifier).restoreState(restoredState);
      } else {
        debugPrint('Persistence: No active session found to restore.');
      }
    } catch (e) {
      debugPrint('Persistence: Error restoring session: $e');
    }
  }

  Future<void> clearSession() async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc('active')
          .delete();
      debugPrint('Persistence: Session cleared from Firestore.');
      // Also clear local blackboard?
      // _ref.read(blackboardProvider.notifier).clear(); 
    } catch (e) {
      debugPrint('Persistence: Error clearing session: $e');
    }
  }
}

final blackboardPersistenceServiceProvider = Provider<BlackboardPersistenceService>((ref) {
  return BlackboardPersistenceService(ref);
});
