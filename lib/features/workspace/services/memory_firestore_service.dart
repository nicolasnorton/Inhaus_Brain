import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// PicoClaw-inspired memory service backed by Firestore.
/// Replaces SharedPreferences-based memory with persistent, cross-session storage.
///
/// Schema:
///   /workspaces/{userId}/docs/memory → { content: String, updatedAt: Timestamp }
///   /workspaces/{userId}/daily_notes/{YYYYMMDD} → { content: String, entries: List, updatedAt: Timestamp }
class MemoryFirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MemoryFirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  DocumentReference _memoryRef(String userId) =>
      _firestore.collection('workspaces').doc(userId).collection('docs').doc('memory');

  DocumentReference _dailyNoteRef(String userId, String dateKey) =>
      _firestore.collection('workspaces').doc(userId).collection('daily_notes').doc(dateKey);

  // ─── Long-Term Memory ─────────────────────────────────────

  /// Read the full memory document content.
  Future<String> readMemory() async {
    final uid = _userId;
    if (uid == null) return '# Brian\'s Memory\n\n(Not authenticated)';

    final snap = await _memoryRef(uid).get();
    if (!snap.exists) return '# Brian\'s Memory\n\n## Initialized\n- No memories recorded yet.';

    return (snap.data() as Map<String, dynamic>?)?['content'] as String? ?? '';
  }

  /// Append a section to the memory document.
  Future<void> appendToMemory(String section, String content) async {
    final uid = _userId;
    if (uid == null) return;

    final current = await readMemory();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final newEntry = '\n\n## $section ($timestamp)\n$content';

    await _memoryRef(uid).set({
      'content': current + newEntry,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Replace a specific section in memory (for structured updates).
  Future<void> updateMemorySection(String sectionHeader, String newContent) async {
    final uid = _userId;
    if (uid == null) return;

    final current = await readMemory();

    // Find and replace the section, or append if not found
    final sectionPattern = RegExp(
      r'## ' + RegExp.escape(sectionHeader) + r'[^\n]*\n([\s\S]*?)(?=\n## |\Z)',
    );

    String updated;
    if (sectionPattern.hasMatch(current)) {
      updated = current.replaceFirst(sectionPattern, '## $sectionHeader\n$newContent');
    } else {
      updated = '$current\n\n## $sectionHeader\n$newContent';
    }

    await _memoryRef(uid).set({
      'content': updated,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Daily Notes ───────────────────────────────────────────

  /// Get today's date key in YYYYMMDD format.
  String _todayKey() => DateFormat('yyyyMMdd').format(DateTime.now());

  /// Append an entry to today's daily note.
  Future<void> appendDailyNote(String entry) async {
    final uid = _userId;
    if (uid == null) return;

    final dateKey = _todayKey();
    final timestamp = DateFormat('HH:mm').format(DateTime.now());
    final formattedEntry = '- $timestamp $entry';

    final ref = _dailyNoteRef(uid, dateKey);
    final snap = await ref.get();

    if (snap.exists) {
      // Append to existing note
      final data = snap.data() as Map<String, dynamic>?;
      final currentContent = data?['content'] as String? ?? '';
      final entries = List<String>.from(data?['entries'] ?? []);
      entries.add(formattedEntry);

      await ref.update({
        'content': '$currentContent\n$formattedEntry',
        'entries': entries,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new daily note
      final dateStr = DateFormat('MMMM d, yyyy').format(DateTime.now());
      await ref.set({
        'content': '# $dateStr\n\n$formattedEntry',
        'entries': [formattedEntry],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Read daily notes for the last N days.
  Future<String> readRecentDailyNotes({int days = 3}) async {
    final uid = _userId;
    if (uid == null) return '';

    final notes = <String>[];
    final today = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyyMMdd').format(date);
      final snap = await _dailyNoteRef(uid, dateKey).get();

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        final content = data?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          notes.add(content);
        }
      }
    }

    if (notes.isEmpty) return '';
    return notes.join('\n\n---\n\n');
  }
}

// ─── Riverpod Providers ────────────────────────────────────────

final memoryFirestoreServiceProvider = Provider<MemoryFirestoreService>((ref) {
  return MemoryFirestoreService();
});
