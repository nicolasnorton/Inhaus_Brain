import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A runtime skill stored in Firestore. Works on web (unlike file-based discovery).
class FirestoreSkill {
  final String name;
  final String description;
  final String content; // Full instructions (loaded on-demand)
  final Map<String, String> references;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FirestoreSkill({
    required this.name,
    required this.description,
    this.content = '',
    this.references = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory FirestoreSkill.fromFirestore(Map<String, dynamic> data, String id) {
    return FirestoreSkill(
      name: data['name'] as String? ?? id,
      description: data['description'] as String? ?? '',
      content: data['content'] as String? ?? '',
      references: Map<String, String>.from(data['references'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'content': content,
    'references': references,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// Metadata-only summary for system prompt (progressive disclosure).
  String toSummary() => '- **$name**: $description';
}

/// Firestore-backed skill service. Creates, reads, and manages skills at runtime.
/// Replaces file-based SkillDiscoveryService for web platform.
class SkillsFirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SkillsFirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference _skillsRef(String userId) =>
      _firestore.collection('workspaces').doc(userId).collection('skills');

  // ─── Skill Discovery (Metadata Only) ──────────────────────

  /// List all skills with metadata only (name + description). No full content.
  Future<List<FirestoreSkill>> listSkills() async {
    final uid = _userId;
    if (uid == null) return [];

    final snap = await _skillsRef(uid).get();
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return FirestoreSkill(
        name: data['name'] as String? ?? doc.id,
        description: data['description'] as String? ?? '',
        // Content intentionally omitted — progressive disclosure
      );
    }).toList();
  }

  /// Build skills summary for system prompt.
  Future<String> buildSkillsSummary() async {
    final skills = await listSkills();
    if (skills.isEmpty) return '';

    final summaries = skills.map((s) => s.toSummary()).join('\n');
    return '# Available Skills\n\n$summaries';
  }

  // ─── Skill Loading (On-Demand) ────────────────────────────

  /// Load full skill content by name (lazy loading).
  Future<FirestoreSkill?> getSkillContent(String skillName) async {
    final uid = _userId;
    if (uid == null) return null;

    final doc = await _skillsRef(uid).doc(skillName).get();
    if (!doc.exists) return null;

    return FirestoreSkill.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Load a specific reference from a skill.
  Future<String?> getSkillReference(String skillName, String refKey) async {
    final skill = await getSkillContent(skillName);
    return skill?.references[refKey];
  }

  // ─── Skill Creation (Runtime) ─────────────────────────────

  /// Create a new skill from a conversation.
  /// Brian can call this when the user provides reusable knowledge.
  Future<void> createSkill(FirestoreSkill skill) async {
    final uid = _userId;
    if (uid == null) return;

    await _skillsRef(uid).doc(skill.name).set(skill.toFirestore());
    debugPrint('SkillsFirestoreService: Created skill "${skill.name}"');
  }

  /// Update an existing skill.
  Future<void> updateSkill(String skillName, Map<String, dynamic> updates) async {
    final uid = _userId;
    if (uid == null) return;

    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _skillsRef(uid).doc(skillName).update(updates);
  }

  /// Delete a skill.
  Future<void> deleteSkill(String skillName) async {
    final uid = _userId;
    if (uid == null) return;

    await _skillsRef(uid).doc(skillName).delete();
  }
}

// ─── Riverpod Providers ────────────────────────────────────────

final skillsFirestoreServiceProvider = Provider<SkillsFirestoreService>((ref) {
  return SkillsFirestoreService();
});
