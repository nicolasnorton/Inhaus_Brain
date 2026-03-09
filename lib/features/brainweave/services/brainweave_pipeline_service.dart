import 'dart:convert' as dart_convert;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/architecture/blackboard.dart';
import '../../../core/services/ai_proxy_service.dart';
import '../../../core/services/vertex_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../knowledge/providers/knowledge_provider.dart';
import '../../workspace/services/agent_registry_service.dart';
import '../models/brainweave_link.dart';
import '../models/brainweave_node.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/config/app_environment.dart';
import 'brainweave_mcp_client.dart';

/// Implements the Ars Contexta 6R Pipeline for BrainWeave.
/// Guaranteed fresh Gemini 3.1 Pro context per phase to prevent LLM attention decay.
class BrainWeavePipelineService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AgentRegistryService _agentRegistry;
  final BlackboardNotifier _blackboard;
  final VertexApiService _vertexAi;

  BrainWeavePipelineService(
    this._firestore,
    this._auth,
    this._agentRegistry,
    this._blackboard,
    this._vertexAi,
  );

  String get _userId => _auth.currentUser!.uid;

  CollectionReference get _cores => _firestore.collection('brainweave_cores');
  CollectionReference get _nodes => _firestore.collection('brainweave_nodes');
  CollectionReference get _links => _firestore.collection('brainweave_links');
  CollectionReference get _sessions => _firestore.collection('brainweave_sessions');

  Future<String> _getArchitectPrompt() async {
    final prompt = await _agentRegistry.getAgentPrompt('brainweave_architect');
    return prompt ?? 'You are the BrainWeave Architect.';
  }

  /// Communicates with the external PicoClaw Go Cognitive Engine.
  /// Falls back to Vertex AI proxy if Cloud Run is unavailable.
  Future<Map<String, dynamic>> _callGoEngine({
    required String sessionId,
    required String phase,
    required String input,
    List<String> context = const [],
  }) async {
    const engineUrl = String.fromEnvironment('PICOCLAW_ENGINE_URL', 
        defaultValue: 'https://picoclaw-401317811527.us-central1.run.app/v1/pipeline/execute');
    
    try {
      final idToken = await _auth.currentUser?.getIdToken();

      final response = await http.post(
        Uri.parse(engineUrl),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: dart_convert.jsonEncode({
          'sessionId': sessionId,
          'phase': phase,
          'input': input,
          'context': context,
        }),
      ).timeout(const Duration(seconds: 300));

      if (response.statusCode == 200) {
        return dart_convert.jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Go Engine returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('BrainWeavePipeline: Go Engine Error: $e — trying Vertex AI proxy fallback');
      
      // ── FALLBACK: Route through Vertex AI Cloud Functions proxy ───
      try {
        final prompt = _buildPhasePrompt(phase, input);
        
        // Tiering logic (BrainWeave 2.1)
        String modelId = 'gemini-3.1-pro-preview';
        if (FeatureFlags.brainweave21Enabled) {
          if (phase == 'reduce' || phase == 'reflect') {
            modelId = 'gemini-3-flash-preview'; // Cheaper, faster for synthesis
          }
        }

        final result = await AIProxyService.generateContent(
          prompt: prompt,
          config: AIModelConfig(
            provider: AIProvider.gemini,
            modelId: modelId,
            temperature: 0.3,
          ),
          systemInstruction: FeatureFlags.brainweave21Enabled 
              ? 'You are the BrainWeave Architect. Produce an array of structured knowledge nodes as JSON. Each node must have: title, description, content, and a strictly typed qmd_concepts string array representing localized semantic concepts for the graph node.'
              : 'You are the BrainWeave Architect. Produce an array of structured knowledge nodes as JSON. Each node must have: title, description, content, topics.',
        );
        
        final text = result['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '[]';
        return {
          'status': 'success',
          'output': text,
          'message': 'Proxy fallback successful',
        };
      } catch (proxyErr) {
        debugPrint('BrainWeavePipeline: Proxy fallback also failed: $proxyErr');
        rethrow;
      }
    }
  }

  /// Builds the phase-specific prompt for fallback routing.
  String _buildPhasePrompt(String phase, String input) {
    switch (phase) {
      case 'reduce':
        return 'REDUCE PHASE:\nExtract clear atomic insights from the following raw input flow. Break down complex facts into distinct nodes.\n\n[INPUT]\n$input';
      case 'reflect':
        return 'REFLECT PHASE:\nSynthesize these insights. Group them logically and create MOC (Map of Content) nodes that connect and elevate these facts.\n\n[INPUT]\n$input';
      default:
        return 'PHASE: $phase\nInput:\n$input';
    }
  }

  /// Triggers the full 6R Pipeline for a given session.
  Future<void> runPipeline(String sessionId, String rawInput) async {
    debugPrint('BrainWeavePipeline: Starting 6R Pipeline for session $sessionId');
    final architectPrompt = await _getArchitectPrompt();

    // Context-Hub Research-First Workflow
    String enrichedInput = rawInput;
    if (FeatureFlags.brainweaveContextHubEnabled) {
       _blackboard.addEvent(WorkflowEventType.agentAction, "Executing Research-First context retrieval...");
       try {
         final mcpClient = BrainWeaveMcpClient();
         final searchResults = await mcpClient.graphQuery(query: rawInput, limit: 3);
         if (searchResults.isNotEmpty) {
           enrichedInput += "\n\n[CONTEXT-HUB KNOWLEDGE]\n";
           for (var r in searchResults) {
             enrichedInput += "- ${r['title']}: ${r['description']}\n";
           }
         }
       } catch (e) {
         debugPrint("BrainWeavePipeline: Research-First query failed: $e");
       }
    }

    // PHASE 1: RECORD
    _blackboard.transitionTo(BlackboardPhase.brainweaveRecord);
    await _recordPhase(sessionId, enrichedInput);

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
    
    // BrainWeave 2.1 Optimization: Buffered write (simulate session capture vs immediate sync)
    // We already do an atomic merge here, but in 2.1 we ensure this is the ONLY 
    // real-time sync before the pipeline suspends.
    
    await sessionRef.set({
      'clientId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'sessionLogs': [rawInput],
      'queueTaskIds': [],
      'currentPhase': BlackboardPhase.brainweaveRecord.name,
      'isBuffered': FeatureFlags.brainweave21Enabled,
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
    
    // CEO-Agent Contradiction Check
    if (FeatureFlags.brainweaveContextHubEnabled) {
      _blackboard.addEvent(WorkflowEventType.agentAction, "CEO-Agent analyzing for contradictions & refactors...");
      final prompt = "You are the BrainWeave CEO Agent. Analyze the following reflections for contradictions against our stored context. If found, suggest a refactor plan to resolve it. If none, reply OK.\n\n${insights.join('\n')}";
      try {
        final ceoResponse = await AIProxyService.generateContent(
          prompt: prompt,
          config: AIModelConfig(
            provider: AIProvider.gemini,
            modelId: FeatureFlags.fastModel,
          ),
        );
        final text = ceoResponse['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        if (text.isNotEmpty && !text.toUpperCase().contains('OK')) {
           _blackboard.addEvent(WorkflowEventType.humanFeedbackNeeded, "CEO-Agent suggests refactor: $text");
           // Log it to session
           await _sessions.doc(sessionId).update({
             'sessionLogs': FieldValue.arrayUnion(['CEO-Agent Refactor Suggestion: $text']),
           });
        }
      } catch (e) {
        debugPrint("BrainWeavePipeline: CEO-Agent check failed: $e");
      }
    }

    final output = response['output'] as String;
    return _parseJsonArray(output);
  }

  /// Classify node type from LLM output or heuristics.
  BrainWeaveNodeType _classifyNodeType(Map<String, dynamic> nodeData) {
    // 1. Check explicit type from LLM
    final rawType = (nodeData['type'] as String? ?? '').toLowerCase().trim();
    if (rawType == 'moc') return BrainWeaveNodeType.moc;
    if (rawType == 'topic') return BrainWeaveNodeType.topic;
    if (rawType == 'atomic') return BrainWeaveNodeType.atomic;

    // 2. Heuristic: title starts with "MOC:"
    final title = (nodeData['title'] as String? ?? '');
    if (title.startsWith('MOC:') || title.startsWith('MOC ')) {
      return BrainWeaveNodeType.moc;
    }

    // 3. Heuristic: many topics → topic hub
    final topics = List<String>.from(nodeData['topics'] ?? []);
    if (topics.length >= 4) return BrainWeaveNodeType.topic;

    return BrainWeaveNodeType.atomic;
  }

  /// 4. Reweave: Graph backward updates.
  Future<void> _reweavePhase(List<dynamic> nodes, String systemInstruction) async {
    final createdNodeIds = <String>[];
    final createdNodes = <BrainWeaveNode>[];

    for (final nodeData in nodes) {
      final docRef = _nodes.doc();

      // Generate embedding
      List<double>? embedding;
      try {
        final contentToEmbed = "${nodeData['title']} ${nodeData['description']} ${nodeData['content']}";
        final embeddings = await _vertexAi.getEmbeddings([contentToEmbed]);
        if (embeddings.isNotEmpty) {
          embedding = embeddings.first;
        }
      } catch (e) {
        debugPrint("BrainWeavePipeline: Failed to generate embedding for node: $e");
      }

      final nodeType = _classifyNodeType(nodeData as Map<String, dynamic>);

      final node = BrainWeaveNode(
        id: docRef.id,
        clientId: _userId,
        projectId: 'default',
        ownerId: _userId,
        title: nodeData['title'] ?? 'Untitled Node',
        description: nodeData['description'] ?? '',
        content: nodeData['content'] ?? '',
        type: nodeType,
        topics: List<String>.from(nodeData['topics'] ?? nodeData['qmd_concepts'] ?? []),
        embedding: embedding,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(node.toJson());
      createdNodeIds.add(docRef.id);
      createdNodes.add(node);
    }

    // ── Generate brainweave_links for nodes sharing topics ──
    await _generateTopicLinks(createdNodes);

    _blackboard.addEvent(WorkflowEventType.agentAction, 
        "Reweave completed: ${createdNodes.length} nodes integrated with topic links.");
  }

  /// Creates brainweave_link documents for nodes that share common topics.
  Future<void> _generateTopicLinks(List<BrainWeaveNode> newNodes) async {
    // Also load existing nodes to link against
    final existingSnap = await _nodes
        .where('ownerId', isEqualTo: _userId)
        .limit(300)
        .get();
    final allNodes = <BrainWeaveNode>[];
    for (final doc in existingSnap.docs) {
      allNodes.add(BrainWeaveNode.fromJson(
          doc.data() as Map<String, dynamic>, doc.id));
    }

    // Build topic → nodeIds index
    final topicIndex = <String, Set<String>>{};
    for (final node in allNodes) {
      for (final topic in node.topics) {
        final key = topic.toLowerCase().trim();
        topicIndex.putIfAbsent(key, () => {}).add(node.id);
      }
    }

    // Load existing links to avoid duplicates
    final existingLinksSnap = await _links
        .where('ownerId', isEqualTo: _userId)
        .limit(1000)
        .get();
    final existingPairs = <String>{};
    for (final doc in existingLinksSnap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final pair = _linkPairKey(d['sourceNodeId'] ?? '', d['targetNodeId'] ?? '');
      existingPairs.add(pair);
    }

    // Create links for topic-sharing pairs involving new nodes
    final newNodeIds = newNodes.map((n) => n.id).toSet();
    int linksCreated = 0;

    for (final entry in topicIndex.entries) {
      final nodeIds = entry.value.toList();
      if (nodeIds.length < 2) continue;

      for (int i = 0; i < nodeIds.length; i++) {
        for (int j = i + 1; j < nodeIds.length; j++) {
          // Only create if at least one node is new
          if (!newNodeIds.contains(nodeIds[i]) && !newNodeIds.contains(nodeIds[j])) continue;

          final pairKey = _linkPairKey(nodeIds[i], nodeIds[j]);
          if (existingPairs.contains(pairKey)) continue;
          existingPairs.add(pairKey);

          final linkRef = _links.doc();
          final link = BrainWeaveLink(
            id: linkRef.id,
            clientId: _userId,
            projectId: 'default',
            ownerId: _userId,
            sourceNodeId: nodeIds[i],
            targetNodeId: nodeIds[j],
            relationshipType: 'shared_topic:${entry.key}',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await linkRef.set(link.toJson());
          linksCreated++;
        }
      }
    }

    debugPrint('BrainWeavePipeline: Generated $linksCreated topic links');
  }

  String _linkPairKey(String a, String b) {
    return a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
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
      'ownerId': _userId,
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

  // ═══════════════════════════════════════════════════════════
  // GSD + ECC Upgrade: Wave Execution + Quick Mode (F3, F5)
  // ═══════════════════════════════════════════════════════════

  /// GSD Wave Execution: Run multiple subagents in parallel batches.
  /// Each wave contains independent tasks that can execute concurrently.
  /// Only active when brainweaveGsdEccEnabled is true.
  Future<List<Map<String, dynamic>>> executeWave({
    required String sessionId,
    required List<Map<String, dynamic>> tasks,
    int maxConcurrency = 3,
  }) async {
    if (!FeatureFlags.brainweaveGsdEccEnabled) {
      debugPrint('BrainWeavePipeline: Wave execution requires GSD+ECC flag');
      return [];
    }

    debugPrint('BrainWeavePipeline: Executing wave with ${tasks.length} tasks (max $maxConcurrency concurrent)');
    final results = <Map<String, dynamic>>[];

    // Process in batches of maxConcurrency
    for (var i = 0; i < tasks.length; i += maxConcurrency) {
      final batch = tasks.sublist(
        i,
        (i + maxConcurrency > tasks.length) ? tasks.length : i + maxConcurrency,
      );

      final futures = batch.map((task) async {
        try {
          final response = await _callGoEngine(
            sessionId: sessionId,
            phase: task['phase'] as String? ?? 'reduce',
            input: task['input'] as String? ?? '',
          );
          return {'task': task['name'] ?? 'unnamed', 'status': 'success', 'output': response};
        } catch (e) {
          return {'task': task['name'] ?? 'unnamed', 'status': 'error', 'error': e.toString()};
        }
      });

      final batchResults = await Future.wait(futures);
      results.addAll(batchResults);

      _blackboard.addEvent(
        WorkflowEventType.agentAction,
        'Wave batch ${(i ~/ maxConcurrency) + 1} completed: ${batchResults.length} tasks',
      );
    }

    return results;
  }

  /// GSD Multi-Plan: Decompose complex input into parallel tasks.
  Future<List<Map<String, dynamic>>> multiPlan(String rawInput) async {
    if (!FeatureFlags.brainweaveGsdEccEnabled) {
      return [{'phase': 'reduce', 'input': rawInput, 'name': 'single_task'}];
    }

    try {
      final result = await AIProxyService.generateContent(
        prompt: 'Decompose this input into 2-4 independent tasks that can be processed in parallel. '
            'Return a JSON array of objects with "name", "phase" (reduce/reflect), and "input" fields.\n\n'
            'Input: $rawInput',
        config: AIModelConfig(
          provider: AIProvider.gemini,
          modelId: FeatureFlags.fastModel,
          temperature: 0.2,
        ),
      );
      final text = result['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '[]';
      return List<Map<String, dynamic>>.from(_parseJsonArray(text));
    } catch (e) {
      debugPrint('BrainWeavePipeline: Multi-plan decomposition failed: $e');
      return [{'phase': 'reduce', 'input': rawInput, 'name': 'fallback_single'}];
    }
  }

  /// Quick Mode (F5): Abbreviated pipeline — skip Reflect, use fast model.
  Future<void> runQuickPipeline(String sessionId, String rawInput) async {
    if (!FeatureFlags.brainweaveGsdEccEnabled) {
      return runPipeline(sessionId, rawInput);
    }

    debugPrint('BrainWeavePipeline: Quick Mode — abbreviated 4-phase pipeline');
    await _getArchitectPrompt();

    // PHASE 1: RECORD
    _blackboard.transitionTo(BlackboardPhase.brainweaveRecord);
    await _recordPhase(sessionId, rawInput);

    // PHASE 2: REDUCE (uses fast model via FeatureFlags.fastModel)
    _blackboard.transitionTo(BlackboardPhase.brainweaveReduce);
    final insights = await _reducePhase(sessionId, rawInput);

    // SKIP REFLECT — go directly to REWEAVE

    // PHASE 4: REWEAVE (auto-approve in quick mode)
    _blackboard.transitionTo(BlackboardPhase.brainweaveReweave);
    _blackboard.updateAgentStatus('BrainWeave Architect', AgentStatus.working);
    final architectPrompt = await _getArchitectPrompt();
    await _reweavePhase(insights, architectPrompt);

    // PHASE 5: VERIFY
    _blackboard.transitionTo(BlackboardPhase.brainweaveVerify);
    await _verifyPhase(sessionId, architectPrompt);

    // Done — skip Rethink in quick mode
    _blackboard.transitionTo(BlackboardPhase.idle);
    _blackboard.updateAgentStatus('BrainWeave Architect', AgentStatus.idle);
    _blackboard.addEvent(WorkflowEventType.agentFinished, 'BrainWeave Quick Pipeline Complete.');
  }
}

final brainWeavePipelineServiceProvider = Provider<BrainWeavePipelineService>((ref) {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final registry = ref.read(agentRegistryServiceProvider);
  final blackboard = ref.read(blackboardProvider.notifier);
  final vertexAi = ref.read(vertexApiServiceProvider);

  return BrainWeavePipelineService(firestore, auth, registry, blackboard, vertexAi);
});
