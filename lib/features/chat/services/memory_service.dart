import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workspace/services/memory_firestore_service.dart';

/// Memory service — bridges legacy MemoryOps interface to the new Firestore-backed service.
/// Phase 3: persistent, cross-session memory.
class MemoryService {
  final MemoryFirestoreService _firestoreService;

  MemoryService(this._firestoreService);

  Future<void> init() async {
    // No-op — Firestore doesn't require local initialization
  }

  Future<String> readMemory() async {
    return await _firestoreService.readMemory();
  }

  Future<void> appendToMemory(String section, String content) async {
    await _firestoreService.appendToMemory(section, content);
  }

  /// New: Log activity to daily notes
  Future<void> logActivity(String entry) async {
    await _firestoreService.appendDailyNote(entry);
  }

  /// New: Read recent daily notes
  Future<String> readRecentActivity({int days = 3}) async {
    return await _firestoreService.readRecentDailyNotes(days: days);
  }

  /// New: Update a specific memory section
  Future<void> updateMemorySection(String sectionHeader, String newContent) async {
    await _firestoreService.updateMemorySection(sectionHeader, newContent);
  }
}

final memoryServiceProvider = Provider<MemoryService>((ref) {
  final firestoreService = ref.read(memoryFirestoreServiceProvider);
  return MemoryService(firestoreService);
});
