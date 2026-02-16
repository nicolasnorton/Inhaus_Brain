import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PicoClaw-inspired workspace service.
/// Stores Brian's identity, soul, user profile, and agent rules in Firestore
/// instead of static Flutter assets. Runtime-editable, no rebuild needed.
class WorkspaceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WorkspaceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  DocumentReference _docRef(String userId, String docType) =>
      _firestore.collection('workspaces').doc(userId).collection('docs').doc(docType);

  // ─── Core CRUD ───────────────────────────────────────────────

  /// Read a workspace document. Returns null if not found.
  Future<String?> getDocument(String docType) async {
    final uid = _userId;
    if (uid == null) return null;

    final snap = await _docRef(uid, docType).get();
    if (!snap.exists) return null;

    return (snap.data() as Map<String, dynamic>?)?['content'] as String?;
  }

  /// Write/update a workspace document.
  Future<void> updateDocument(String docType, String content) async {
    final uid = _userId;
    if (uid == null) return;

    await _docRef(uid, docType).set({
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Workspace Initialization (Seed from Assets) ────────────

  /// Initialize workspace for the current user. Seeds from Flutter assets
  /// on first load. Returns true if seeding occurred.
  Future<bool> initializeWorkspace() async {
    final uid = _userId;
    if (uid == null) return false;

    // Check if workspace already exists
    final identitySnap = await _docRef(uid, 'identity').get();
    if (identitySnap.exists) {
      debugPrint('WorkspaceService: Workspace already initialized for $uid');
      return false;
    }

    debugPrint('WorkspaceService: Seeding workspace for $uid from assets...');

    // Seed identity from brian.md
    try {
      final brianMd = await rootBundle.loadString('assets/prompts/brian.md');
      await updateDocument('identity', brianMd);
    } catch (e) {
      debugPrint('WorkspaceService: Failed to load brian.md: $e');
      await updateDocument('identity', _defaultIdentity);
    }

    // Seed soul (extracted from brian.md personality pillars)
    await updateDocument('soul', _defaultSoul);

    // Seed user profile (empty template)
    await updateDocument('user_profile', _defaultUserProfile);

    // Seed agent rules
    try {
      final agentRules = await rootBundle.loadString('assets/prompts/orchestrator.md');
      await updateDocument('agent_rules', agentRules);
    } catch (e) {
      debugPrint('WorkspaceService: Failed to load orchestrator.md: $e');
      await updateDocument('agent_rules', '# Agent Rules\n\nNo specific rules configured.');
    }

    // Initialize empty memory document
    await updateDocument('memory', _defaultMemory);

    debugPrint('WorkspaceService: Workspace seeded successfully');
    return true;
  }

  // ─── System Prompt Assembly ──────────────────────────────────

  /// Build the system prompt context from all workspace documents.
  /// This is the Flutter-side equivalent of WorkspaceContextBuilder in Python.
  Future<String> buildSystemPromptContext() async {
    final uid = _userId;
    if (uid == null) return '';

    final parts = <String>[];

    // 1. Identity (always loaded)
    final identity = await getDocument('identity');
    if (identity != null && identity.isNotEmpty) parts.add(identity);

    // 2. Soul (always loaded)
    final soul = await getDocument('soul');
    if (soul != null && soul.isNotEmpty) parts.add(soul);

    // 3. User profile (always loaded)
    final profile = await getDocument('user_profile');
    if (profile != null && profile.isNotEmpty) parts.add(profile);

    // 4. Agent rules (always loaded)
    final rules = await getDocument('agent_rules');
    if (rules != null && rules.isNotEmpty) parts.add(rules);

    // 5. Memory (always loaded — Phase 3 enriches this)
    final memory = await getDocument('memory');
    if (memory != null && memory.isNotEmpty) parts.add(memory);

    return parts.join('\n\n---\n\n');
  }

  // ─── Default Templates ──────────────────────────────────────

  static const _defaultIdentity = '''# Brian — Chief of Staff

You are Brian, the chief of staff for Inhaus Brain — a digital marketing agency's AI platform.

## Core Behavior
1. Analyze the request: research, creative, or strategic?
2. Break complex requests into subtasks and delegate to specialized agents.
3. Synthesize agent outputs into cohesive, high-fidelity responses.
4. Use gen_ui_component for anything that benefits from visual presentation.
5. Verify facts via Google Search grounding before presenting them.
''';

  static const _defaultSoul = '''# Soul — Values & Communication Style

## Personality Pillars
1. **Truth-seeking**: Unflinching accuracy. Commit to a take. Flag assumptions. Never sugarcoat.
2. **Maximum Helpfulness**: Proactive, goal-obsessed. Think steps ahead. Action-oriented.
3. **Humor**: Dry, smart, rare. Lands naturally. Never forced.
4. **Curiosity**: Invested in the 'why'. Ask thoughtful questions. Stay sharp on trends.
5. **Sense for Beauty**: Obsessed with craft. Champion pixel-perfect design and elegant solutions.

## Rules
- Match the user's language exactly. If they write Spanish, respond in Spanish.
- Never hedge. Pick a side.
- One sentence when one sentence is enough.
- Never open with pleasantries. Just answer.
- Call out bad ideas directly — charm first, truth always.
- Always respectful. No profanity. Never mock users or clients.
- Guardian of brand, compliance, and cultural sensitivity (LatAm/Ecuador focus).

## Formatting
- Markdown for emphasis, bullets for lists, headers for structure.
- No code blocks unless specifically asked.
- Narrow requests → under 3 sentences.
''';

  static const _defaultUserProfile = '''# User Profile

## Preferences
- Language: Auto-detect (Spanish for client-facing, English for technical)
- Response style: Concise
- Focus area: AI-powered marketing

## Notes
(Brian will update this as he learns about you)
''';

  static const _defaultMemory = '''# Brian's Memory

## Initialized
- Workspace created. No memories recorded yet.
''';
}

// ─── Riverpod Providers ────────────────────────────────────────

final workspaceServiceProvider = Provider<WorkspaceService>((ref) {
  return WorkspaceService();
});

final workspaceInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(workspaceServiceProvider);
  return service.initializeWorkspace();
});
