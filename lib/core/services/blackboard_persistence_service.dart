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
          .doc(state.sessionId ?? 'assistant_global');

      await sessionRef.set({
        ...state.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('Persistence: Session ${state.sessionId ?? 'assistant_global'} saved successfully.');
    } catch (e) {
      debugPrint('Persistence: Error saving session: $e');
    } finally {
      _isSaving = false;
    }
  }

  Future<void> restoreSession() async {
    final state = _ref.read(blackboardProvider);
    final sessionId = state.sessionId ?? 'assistant_global';
    await loadSession(sessionId);
  }

  Future<void> loadSession(String sessionId) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) {
      debugPrint('Persistence: Cannot load session - No user logged in.');
      return;
    }

    try {
      final sessionDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId)
          .get();

      if (sessionDoc.exists && sessionDoc.data() != null) {
        final data = sessionDoc.data()!;
        final restoredState = BlackboardState.fromJson(data);
        
        debugPrint('Persistence: Restoring session state for $sessionId...');
        _ref.read(blackboardProvider.notifier).restoreState(restoredState);
      } else {
        debugPrint('Persistence: No session found to restore for $sessionId. Initializing new...');
        _ref.read(blackboardProvider.notifier).initialize(sessionId);
      }
    } catch (e) {
      debugPrint('Persistence: Error loading session $sessionId: $e');
    }
  }

  Future<void> clearSession() async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final state = _ref.read(blackboardProvider);
    final sessionId = state.sessionId ?? 'assistant_global';

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId)
          .delete();
      debugPrint('Persistence: Session $sessionId cleared from Firestore.');
      _ref.read(blackboardProvider.notifier).clear(sessionId: sessionId); 
    } catch (e) {
      debugPrint('Persistence: Error clearing session: $e');
    }
  }
}

final blackboardPersistenceServiceProvider = Provider<BlackboardPersistenceService>((ref) {
  return BlackboardPersistenceService(ref);
});
