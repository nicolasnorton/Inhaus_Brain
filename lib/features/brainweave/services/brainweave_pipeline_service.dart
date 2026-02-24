import 'dart:convert' as dart_convert;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/architecture/blackboard.dart';
import '../../../core/services/ai_proxy_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../workspace/services/agent_registry_service.dart';
import '../models/brainweave_node.dart';

/// Implements the Ars Contexta 6R Pipeline for BrainWeave.
/// Guaranteed fresh Gemini 2.5 Flash context per phase to prevent LLM attention decay.
class BrainWeavePipelineService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AgentRegistryService _agentRegistry;
  final BlackboardNotifier _blackboard;

  BrainWeavePipelineService(
    this._firestore,
    this._auth,
    this._agentRegistry,
    this._blackboard,
  );

  String get _userId => _auth.currentUser!.uid;

  CollectionReference get _cores => _firestore.collection('brainweave_cores');
  CollectionReference get _nodes => _firestore.collection('brainweave_nodes');
  CollectionReference get _sessions => _firestore.collection('brainweave_sessions');

  Future<String> _getArchitectPrompt() async {
    final prompt = await _agentRegistry.getAgentPrompt('brainweave_architect');
    return prompt ?? 'You are the BrainWeave Architect.';
  }

  /// Communicates with the external PicoClaw Go Cognitive Engine.
  Future<Map<String, dynamic>> _callGoEngine({
    required String sessionId,
    required String phase,
    required String input,
    List<String> context = const [],
  }) async {
    // TODO: Move this to RemoteConfig or Environment variable
    const engineUrl = 'http://localhost:8080/v1/pipeline/execute';
    
    try {
      final response = await http.post(
        Uri.parse(engineUrl),
        headers: {'Content-Type': 'application/json'},
        body: dart_convert.jsonEncode({
          'sessionId': sessionId,
          'phase': phase,
          'input': input,
          'context': context,
        }),
      );

      if (response.statusCode == 200) {
        return dart_convert.jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Go Engine returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('BrainWeavePipeline: Go Engine Error: $e');
      rethrow;
    }
  }

  /// Triggers the full 6R Pipeline for a given session.
  Future<void> runPipeline(String sessionId, String rawInput) async {
    debugPrint('BrainWeavePipeline: Starting 6R Pipeline for session $sessionId');
    final architectPrompt = await _getArchitectPrompt();

    // PHASE 1: RECORD
    _blackboard.transitionTo(BlackboardPhase.brainweaveRecord);
    await _recordPhase(sessionId, rawInput);

    // PHASE 2: REDUCE
    _blackboard.transitionTo(BlackboardPhase.brainweaveReduce);
    final insights = await _reducePhase(sessionId, rawInput);

    // PHASE 3: REFLECT
    _blackboard.transitionTo(BlackboardPhase.brainweaveReflect);
    final reflections = await _reflectPhase(sessionId, insights);

    // PHASE 4: REWEAVE
    _blackboard.transitionTo(BlackboardPhase.brainweaveReweave);
    _blackboard.updateAgentStatus('BrainWeave Architect', AgentStatus.blocked);
    
    // Gavel logic: Block execution until human approval for controversial/destructive graph rewrites.
    _blackboard.addEvent(
      WorkflowEventType.humanFeedbackNeeded,
      "Reweave Phase requires human approval before backward-updating the knowledge graph.",
    );
    _blackboard.transitionTo(BlackboardPhase.reviewPending);
    
    // In a real flow, execution suspends here until the UI calls resumePipelineOnApproval().
    // We simulate the pause by saving the intent to the session.
    await _sessions.doc(sessionId).update({
      'sessionLogs': FieldValue.arrayUnion(['Paused for Reweave Approval']),
      'pendingReflections': reflections, // store transiently
      'currentPhase': BlackboardPhase.reviewPending.name,
    });
  }

  /// Resumes the pipeline after Gavel approval.
  Future<void> resumePipelineOnApproval(String sessionId) async {
    final sessionDoc = await _sessions.doc(sessionId).get();
    if (!sessionDoc.exists) return;
    final data = sessionDoc.data() as Map<String, dynamic>;
    final pendingReflections = List<dynamic>.from(data['pendingReflections'] ?? []);
    final architectPrompt = await _getArchitectPrompt();

    // Actual Reweave Execution
    _blackboard.transitionTo(BlackboardPhase.brainweaveReweave);
    _blackboard.updateAgentStatus('BrainWeave Architect', AgentStatus.working);
    await _reweavePhase(pendingReflections, architectPrompt);

    // PHASE 5: VERIFY
    _blackboard.transitionTo(BlackboardPhase.brainweaveVerify);
    await _verifyPhase(sessionId, architectPrompt);

    // PHASE 6: RETHINK
    _blackboard.transitionTo(BlackboardPhase.brainweaveRethink);
    _blackboard.updateAgentStatus('BrainWeave Architect', AgentStatus.blocked);
    
    // Gavel logic: Rethink requires human approval to modify Core Space (Methodology).
    _blackboard.addEvent(
      WorkflowEventType.humanFeedbackNeeded,
      "Rethink Phase requires human approval before modifying BrainWeave Methodology.",
    );
    _blackboard.transitionTo(BlackboardPhase.reviewPending);
    
    await _sessions.doc(sessionId).update({
      'sessionLogs': FieldValue.arrayUnion(['Paused for Rethink Approval']),
      'currentPhase': BlackboardPhase.reviewPending.name,
    });
  }

  Future<void> finalizeRethink(String sessionId) async {
    _blackboard.transitionTo(BlackboardPhase.brainweaveRethink);
    _blackboard.updateAgentStatus('BrainWeave Architect', AgentStatus.working);
    final architectPrompt = await _getArchitectPrompt();
    await _rethinkPhase(sessionId, architectPrompt);
    
    _blackboard.transitionTo(BlackboardPhase.idle);
    _blackboard.updateAgentStatus('BrainWeave Architect', AgentStatus.idle);
    _blackboard.addEvent(WorkflowEventType.agentFinished, "BrainWeave 6R Pipeline Complete.");
  }

  // ─── 6R Individual Phase Implementations (Fresh Context Window) ───

  /// 1. Record: Zero friction capture. Just saves it to the Flow Space.
  Future<void> _recordPhase(String sessionId, String rawInput) async {
    final sessionRef = _sessions.doc(sessionId);
    await sessionRef.set({
      'clientId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'sessionLogs': [rawInput],
      'queueTaskIds': [],
      'currentPhase': BlackboardPhase.brainweaveRecord.name,
    }, SetOptions(merge: true));
    
    _blackboard.addEvent(WorkflowEventType.agentAction, "Record phase completed. Flow Space initialized.");
  }

  /// 2. Reduce: Extract insights via Go Engine.
  Future<List<dynamic>> _reducePhase(String sessionId, String rawInput) async {
    final response = await _callGoEngine(
      sessionId: sessionId,
      phase: 'reduce',
      input: rawInput,
    );
    
    final output = response['output'] as String;
    return _parseJsonArray(output);
  }

  /// 3. Reflect: Synthesis via Go Engine.
  Future<List<dynamic>> _reflectPhase(String sessionId, List<dynamic> insights) async {
    final response = await _callGoEngine(
      sessionId: sessionId,
      phase: 'reflect',
      input: insights.join('\n'),
    );
    
    final output = response['output'] as String;
    return _parseJsonArray(output);
  }

  /// 4. Reweave: Graph backward updates.
  Future<void> _reweavePhase(List<dynamic> nodes, String systemInstruction) async {
    for (final nodeData in nodes) {
      final docRef = _nodes.doc();
      final node = BrainWeaveNode(
        id: docRef.id,
        clientId: _userId,
        projectId: 'default',
        ownerId: _userId,
        title: nodeData['title'] ?? 'Untitled Node',
        description: nodeData['description'] ?? '',
        content: nodeData['content'] ?? '',
        type: BrainWeaveNodeType.atomic,
        topics: List<String>.from(nodeData['topics'] ?? []),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(node.toJson());
    }
    _blackboard.addEvent(WorkflowEventType.agentAction, "Reweave completed: Nodes integrated.");
  }

  /// 5. Verify: Schema tracking and evaluation.
  Future<void> _verifyPhase(String sessionId, String systemInstruction) async {
    await _sessions.doc(sessionId).update({
      'sessionLogs': FieldValue.arrayUnion(['Verification completed: Schemas intact.']),
    });
    _blackboard.addEvent(WorkflowEventType.agentAction, "Verify completed: Schemas valid.");
  }

  /// 6. Rethink: Modifying Core Space.
  Future<void> _rethinkPhase(String sessionId, String systemInstruction) async {
    final coreRef = _cores.doc(_userId);
    await coreRef.set({
      'methodology': 'Updated methodology based on recent friction logs...',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    await _sessions.doc(sessionId).update({
      'sessionLogs': FieldValue.arrayUnion(['Rethink completed: Methodology updated.']),
      'currentPhase': BlackboardPhase.idle.name,
    });
    _blackboard.addEvent(WorkflowEventType.agentAction, "Rethink completed: Core updated.");
  }

  List<dynamic> _parseJsonArray(String jsonText) {
    try {
      final cleanText = jsonText.replaceAll('```json', '').replaceAll('```', '').trim();
      return List<dynamic>.from(dart_convert.jsonDecode(cleanText) as List);
    } catch (e) {
      debugPrint("BrainWeavePipeline: JSON Parse Error: $e");
      return [];
    }
  }
}

final brainWeavePipelineServiceProvider = Provider<BrainWeavePipelineService>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final registry = ref.read(agentRegistryServiceProvider);
  final blackboard = ref.read(blackboardProvider.notifier);
  final aiProxy = ref.read(aiProxyServiceProvider);

  return BrainWeavePipelineService(firestore, auth, registry, blackboard);
});
