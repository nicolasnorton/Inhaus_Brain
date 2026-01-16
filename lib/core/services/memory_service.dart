import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/chat/models/memory_models.dart';
import '../auth/auth_service.dart';

class MemoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;
  
  // Local cache for synchronous reads (mirroring user memory)
  List<MemoryItem> _localMemoryCache = [];
  bool _isInitialized = false;

  MemoryService(this._authService) {
    _init();
  }

  void _init() {
    final user = _authService.currentUser;
    if (user != null) {
      // Subscribe to user's memory stream to keep local cache updated
      _firestore.collection('users').doc(user.uid).collection('memory')
          .snapshots()
          .listen((snapshot) {
        _localMemoryCache = snapshot.docs.map((doc) => MemoryItem.fromJson(doc.data())).toList();
        _isInitialized = true;
      }, onError: (e) {
        debugPrint('Error syncing memory: $e');
      });
    }
  }

  // --- Public API ---

  List<MemoryItem> get memory => List.unmodifiable(_localMemoryCache);

  Future<void> addMemory(MemoryItem item) async {
    final user = _authService.currentUser;
    if (user == null) return; // Guard against no user

    try {
      // 1. Save to User's Private Memory
      // Use compound ID or robust key to prevent duplicates if desired
      // Logic: upsert based on 'key' and 'campaignId' to match previous logic
      // But firestore needs a doc ID. We will Query first or use a deterministic ID?
      // Previous logic: indexWhere check.
      // Firestore approach: simpler to just add, but let's try to maintain uniqueness for keys within a campaign.
      
      final userMemoryRef = _firestore.collection('users').doc(user.uid).collection('memory');
      
      // Check for existing item with same key/campaign (inefficient read, but safe)
      // For optimization, one might use a composite ID like "campaignId_key" if unique.
      QuerySnapshot existing;
      if (item.campaignId != null) {
         existing = await userMemoryRef
            .where('key', isEqualTo: item.key)
            .where('campaignId', isEqualTo: item.campaignId)
            .get();
      } else {
         existing = await userMemoryRef
            .where('key', isEqualTo: item.key)
            .where('campaignId', isNull: true)
            .get();
      }

      final newItem = MemoryItem(
        id: existing.docs.isNotEmpty ? existing.docs.first.id : item.id,
        key: item.key,
        value: item.value,
        category: item.category,
        createdAt: DateTime.now(),
        campaignId: item.campaignId,
        metadata: item.metadata,
        agentId: item.agentId,
        userId: user.uid,
        scope: item.scope,
      );

      await userMemoryRef.doc(newItem.id).set(newItem.toJson());

      // 2. Dual-Write to Super Admin Memory (if applicable)
      // We assume ALL agent memories are relevant to Super Admin as per request.
      // We create a summary or direct copy.
      if (item.scope != MemoryScope.private) { // If it's shared or superAdmin
         await _syncToSuperAdmin(newItem);
      } else {
         // Even private agent memory implies "private to that agent", but Super Admin (Copilot) 
         // requested "full access to all system memories". 
         // So we should probably sync EVERYTHING but tag it properly.
         await _syncToSuperAdmin(newItem);
      }

    } catch (e) {
      debugPrint('Error adding memory: $e');
    }
  }

  Future<void> _syncToSuperAdmin(MemoryItem item) async {
    try {
      // Super Admin Memory Collection
      // We use a global collection: system/memory/super_admin/{id}
      final superMemoryRef = _firestore.collection('system').doc('memory').collection('super_admin');
      
      // We suffix ID with user ID to avoid collisions if multiple users generate same memory Key
      // Or just use a random ID.
      // Let's store it with the same ID but ensure we have userId in data.
      final docId = "${item.userId}_${item.id}";
      
      await superMemoryRef.doc(docId).set({
        ...item.toJson(),
        'syncedAt': FieldValue.serverTimestamp(),
        'originUserId': item.userId,
      });
    } catch (e) {
      debugPrint('Error syncing to super admin: $e');
    }
  }

  List<MemoryItem> getMemoriesForCampaign(String campaignId) {
    return _localMemoryCache.where((m) => m.campaignId == campaignId).toList();
  }

  List<MemoryItem> getMemoriesByCategory(String category) {
    return _localMemoryCache.where((m) => m.category == category).toList();
  }

  Future<void> clearMemory() async {
    final user = _authService.currentUser;
    if (user == null) return;
    
    final batch = _firestore.batch();
    final snapshot = await _firestore.collection('users').doc(user.uid).collection('memory').get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    // Cache updates automatically via listener
  }

  // Retrieve relevant context for an AI prompt
  String getContextString({String? campaignId}) {
    if (!_isInitialized && _localMemoryCache.isEmpty) {
        // Fallback or warning?
        // For now, return empty.
    }

    final relevant = campaignId != null 
        ? getMemoriesForCampaign(campaignId) 
        : _localMemoryCache;
    
    if (relevant.isEmpty) return "";
    
    // Format: "- [AgentName] Key: Value"
    return "\n[REMEMBERED FACTS & PREFERENCES]:\n${relevant.map((m) => "- ${m.key}: ${m.value}").join("\n")}";
  }
  
  Future<List<MemoryItem>> getSuperAdminMemories() async {
      // This is an expensive operation if we fetch EVERYTHING.
      // In production, we would filter.
      final snapshot = await _firestore.collection('system').doc('memory').collection('super_admin')
        .orderBy('createdAt', descending: true)
        .limit(100) // Safety limit
        .get();
      
      return snapshot.docs.map((doc) => MemoryItem.fromJson(doc.data())).toList();
  }

  Future<void> updateSuperAdminMemory(MemoryItem item) async {
    final docId = "${item.userId}_${item.id}";
    await _firestore.collection('system').doc('memory').collection('super_admin')
        .doc(docId).set({
          ...item.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': 'super_admin',
        }, SetOptions(merge: true));
    
    // Optional: Also sync back to user's private memory if we want consistency?
    // For now, let's keep it in system memory as a "correction".
  }

  Future<void> deleteSuperAdminMemory(MemoryItem item) async {
    final docId = "${item.userId}_${item.id}";
    await _firestore.collection('system').doc('memory').collection('super_admin')
        .doc(docId).delete();
  }
}

final memoryServiceProvider = Provider<MemoryService>((ref) {
  return MemoryService(ref.watch(authServiceProvider));
});
