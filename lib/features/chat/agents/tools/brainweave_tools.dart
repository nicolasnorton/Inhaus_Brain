import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/mcp/agent_tool.dart';
import '../../../../core/services/vertex_ai_service.dart';
import '../../../knowledge/providers/knowledge_provider.dart';
import '../../../clients/providers/client_provider.dart';
import '../../../brainweave/services/brainweave_mcp_client.dart';

final _mcpClient = BrainWeaveMcpClient();

/// Semantic search implementation exposed to Agents
class QueryBrainWeaveTool extends AgentTool {
  QueryBrainWeaveTool()
      : super(
          name: 'query_brainweave',
          description: 'Search the BrainWeave semantic knowledge graph for conceptual or factual matches.',
          inputSchema: {
            'query': {
              'type': 'string',
              'description': 'The natural language search query.',
            },
            'limit': {
              'type': 'integer',
              'description': 'Maximum number of results to return (default 5).',
            },
            'scope': {
              'type': 'string',
              'description': 'Optional. Can be PRIVATE, CLIENT, or AGENCY. If omitted, searches all scopes the agent has access to.',
              'enum': ['PRIVATE', 'CLIENT', 'AGENCY']
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final query = parameters['query'] as String?;
    final limit = parameters['limit'] as int? ?? 5;

    if (query == null || query.isEmpty) {
      return ToolResult.failure('Missing query parameter');
    }

    // ─── V2 Path: Cloud Spanner via MCP API ──────────────
    if (AppConfig.brainweaveV2Enabled) {
      try {
        final requestedScope = parameters['scope'] as String?;
        final results = await _mcpClient.graphQuery(
          query: query,
          scope: requestedScope,
          limit: limit,
        );
        return ToolResult.success({'results': results});
      } catch (e) {
        return ToolResult.failure('V2 search failed: $e');
      }
    }

    // ─── V1 Path: Firestore + client-side cosine ─────────
    if (ref == null) return ToolResult.failure('Riverpod ref is required');

    try {
      final vertexAi = ref.read(vertexApiServiceProvider);
      final activeClientId = ref.read(clientProvider).selectedClientId;
      final requestedScope = parameters['scope'] as String?;
      
      final embeddings = await vertexAi.getEmbeddings([query]);
      if (embeddings.isEmpty) {
        return ToolResult.failure('Failed to generate embedding for query');
      }

      final results = await vertexAi.searchVectorIndex(
        queryVector: embeddings.first,
        neighborCount: limit,
        filter: {
          if (requestedScope != null) 'scope': requestedScope,
          if (activeClientId != null) 'clientId': activeClientId,
        },
      );

      return ToolResult.success({'results': results});
    } catch (e) {
      return ToolResult.failure('Search failed: $e');
    }
  }
}

/// Fetch full context of a specific node
class GetNodeContextTool extends AgentTool {
  GetNodeContextTool()
      : super(
          name: 'get_node_context',
          description: 'Retrieve the complete content and associated topic linkages for a specific BrainWeave node by ID.',
          inputSchema: {
            'nodeId': {
              'type': 'string',
              'description': 'The exact ID of the node to retrieve.',
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final nodeId = parameters['nodeId'] as String?;
    if (nodeId == null || nodeId.isEmpty) {
      return ToolResult.failure('Missing nodeId parameter');
    }

    // ─── V2 Path ──────────────────────────────────────────
    if (AppConfig.brainweaveV2Enabled) {
      try {
        final result = await _mcpClient.context(nodeId: nodeId);
        return ToolResult.success(result);
      } catch (e) {
        return ToolResult.failure('V2 context failed: $e');
      }
    }

    // ─── V1 Path ──────────────────────────────────────────
    try {
      final doc = await FirebaseFirestore.instance
          .collection('brainweave_nodes')
          .doc(nodeId)
          .get();

      if (!doc.exists) {
        return ToolResult.failure('Node not found');
      }

      final data = doc.data()!;
      data.remove('embedding');

      final edgesSnapshot = await FirebaseFirestore.instance
          .collection('brainweave_links')
          .where('sourceId', isEqualTo: nodeId)
          .get();
          
      final targetEdgesSnapshot = await FirebaseFirestore.instance
          .collection('brainweave_links')
          .where('targetId', isEqualTo: nodeId)
          .get();

      final edges = [
        ...edgesSnapshot.docs.map((d) => d.data()),
        ...targetEdgesSnapshot.docs.map((d) => d.data()),
      ];

      return ToolResult.success({
        'node': data,
        'edges': edges,
      });
    } catch (e) {
      return ToolResult.failure('Failed to get node context: $e');
    }
  }
}

/// Allows agents to autonomously insert knowledge into BrainWeave
class CreateAtomicNodeTool extends AgentTool {
  CreateAtomicNodeTool()
      : super(
          name: 'create_atomic_node',
          description: 'Insert a new verified fact or observation into the BrainWeave graph.',
          inputSchema: {
            'title': {
              'type': 'string',
              'description': 'A short, declarative title for the node.',
            },
            'description': {
              'type': 'string',
              'description': 'A 1-2 sentence summary.',
            },
            'content': {
              'type': 'string',
              'description': 'The full detailed content of the insight.',
            },
            'topics': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of categorical topics to group this node.',
            },
            'scope': {
              'type': 'string',
              'description': 'The visibility scope of the node (PRIVATE, CLIENT, AGENCY). Defaults to PRIVATE.',
              'enum': ['PRIVATE', 'CLIENT', 'AGENCY']
            },
            'type': {
              'type': 'string',
              'description': 'The type of node (e.g., atomic, research, entity, claim). Defaults to atomic.',
            },
            'metadata': {
              'type': 'object',
              'description': 'Optional JSON object for storing extra metadata like URLs, confidence scores, etc.',
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return ToolResult.failure('No authenticated user');

    final title = parameters['title'] as String?;
    final description = parameters['description'] as String?;
    final content = parameters['content'] as String?;
    final topics = (parameters['topics'] as List?)?.cast<String>() ?? [];
    final scope = parameters['scope'] as String? ?? 'PRIVATE';
    final nodeType = parameters['type'] as String? ?? 'atomic';
    final metadata = parameters['metadata'] as Map<String, dynamic>?;

    if (title == null || content == null) {
      return ToolResult.failure('Missing required title or content');
    }

    // ─── V2 Path ──────────────────────────────────────────
    if (AppConfig.brainweaveV2Enabled) {
      try {
        final result = await _mcpClient.create(
          title: title,
          description: description ?? '',
          content: content,
          nodeType: nodeType,
          topics: topics,
          scope: scope,
          sourceAgent: 'chat_agent',
          metadata: metadata,
        );
        return ToolResult.success(result);
      } catch (e) {
        return ToolResult.failure('V2 create failed: $e');
      }
    }

    // ─── V1 Path ──────────────────────────────────────────
    if (ref == null) return ToolResult.failure('Riverpod ref is required');

    try {
      final vertexAi = ref.read(vertexApiServiceProvider);
      final activeClientId = ref.read(clientProvider).selectedClientId;
      
      final textToEmbed = "$title $description $content";
      final embeddings = await vertexAi.getEmbeddings([textToEmbed]);
      List<double>? embedding = embeddings.isNotEmpty ? embeddings.first : null;

      final nodeData = {
        'clientId': activeClientId ?? 'user_$userId',
        'projectId': 'default',
        'ownerId': userId,
        'title': title,
        'description': description ?? '',
        'content': content,
        'type': 'atomic',
        'topics': topics,
        'scope': scope,
        'embedding': embedding,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('brainweave_nodes')
          .add(nodeData);

      return ToolResult.success({
        'status': 'Node created successfully',
        'nodeId': docRef.id,
      });
    } catch (e) {
      return ToolResult.failure('Failed to create node: $e');
    }
  }
}

/// Allows KnowledgeLibrarian to propose a node promotion to AGENCY scope
class PromoteNodeTool extends AgentTool {
  PromoteNodeTool()
      : super(
          name: 'promote_node',
          description: 'Propose an existing node to be promoted to AGENCY scope. This creates a pending review for humans to approve.',
          inputSchema: {
            'nodeId': {
              'type': 'string',
              'description': 'The exact ID of the node to promote.',
            },
            'reason': {
              'type': 'string',
              'description': 'The rationale for why this should be agency-wide knowledge.',
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final nodeId = parameters['nodeId'] as String?;
    final reason = parameters['reason'] as String?;

    if (nodeId == null || nodeId.isEmpty) {
      return ToolResult.failure('Missing nodeId parameter');
    }
    if (reason == null || reason.isEmpty) {
      return ToolResult.failure('Missing reason parameter');
    }

    // ─── V2 Path ──────────────────────────────────────────
    if (AppConfig.brainweaveV2Enabled) {
      try {
        final result = await _mcpClient.promote(nodeId: nodeId, reason: reason);
        return ToolResult.success(result);
      } catch (e) {
        return ToolResult.failure('V2 promote failed: $e');
      }
    }

    // ─── V1 Path ──────────────────────────────────────────
    try {
      final doc = await FirebaseFirestore.instance.collection('brainweave_nodes').doc(nodeId).get();
      if (!doc.exists) return ToolResult.failure('Node not found');
      
      final currentScope = doc.data()?['scope'] ?? 'PRIVATE';
      if (currentScope == 'AGENCY') return ToolResult.failure('Node is already AGENCY scope');

      await FirebaseFirestore.instance.collection('pending_promotions').add({
        'nodeId': nodeId,
        'title': doc.data()?['title'] ?? 'Untitled Node',
        'reason': reason,
        'requestedBy': FirebaseAuth.instance.currentUser?.uid ?? 'system',
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'PENDING',
      });

      return ToolResult.success({
        'status': 'Promotion request created successfully. Waiting for human approval.'
      });
    } catch (e) {
      return ToolResult.failure('Failed to request promotion: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════
// BrainWeave 2.0 — New Tools (V2 Only)
// ═══════════════════════════════════════════════════════════

/// N-hop impact analysis from a given node
class ImpactAnalysisTool extends AgentTool {
  ImpactAnalysisTool()
      : super(
          name: 'brainweave_impact',
          description: 'Analyze the ripple effect of changes to a knowledge node. '
              'Shows all connected nodes that would be affected, with confidence scores.',
          inputSchema: {
            'nodeId': {
              'type': 'string',
              'description': 'The ID of the node to analyze impact for.',
            },
            'maxDepth': {
              'type': 'integer',
              'description': 'Maximum hops to traverse (default 3).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    if (!AppConfig.brainweaveV2Enabled) {
      return ToolResult.failure('Impact analysis requires BrainWeave 2.0 (Spanner Graph). Enable brainweaveV2Enabled.');
    }

    final nodeId = parameters['nodeId'] as String?;
    if (nodeId == null) return ToolResult.failure('Missing nodeId');

    try {
      final result = await _mcpClient.impact(
        nodeId: nodeId,
        maxDepth: parameters['maxDepth'] as int? ?? 3,
      );
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Impact analysis failed: $e');
    }
  }
}

/// Community detection across the knowledge graph
class ClusterAnalysisTool extends AgentTool {
  ClusterAnalysisTool()
      : super(
          name: 'brainweave_cluster',
          description: 'Discover communities and clusters of related knowledge nodes.',
          inputSchema: {
            'scope': {
              'type': 'string',
              'description': 'Optional. Filter clusters by scope.',
              'enum': ['PRIVATE', 'CLIENT', 'AGENCY'],
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    if (!AppConfig.brainweaveV2Enabled) {
      return ToolResult.failure('Cluster analysis requires BrainWeave 2.0.');
    }

    try {
      final clusters = await _mcpClient.cluster(
        scope: parameters['scope'] as String?,
      );
      return ToolResult.success({'clusters': clusters, 'count': clusters.length});
    } catch (e) {
      return ToolResult.failure('Cluster analysis failed: $e');
    }
  }
}

/// Detect recently changed nodes and assess ripple impact
class DetectChangesTool extends AgentTool {
  DetectChangesTool()
      : super(
          name: 'brainweave_detect_changes',
          description: 'Find knowledge nodes modified since a given time. '
              'Useful for detecting what has changed and needs review.',
          inputSchema: {
            'sinceMinutesAgo': {
              'type': 'integer',
              'description': 'Number of minutes to look back (default 60).',
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    if (!AppConfig.brainweaveV2Enabled) {
      return ToolResult.failure('Change detection requires BrainWeave 2.0.');
    }

    final minutes = parameters['sinceMinutesAgo'] as int? ?? 60;
    final since = DateTime.now().subtract(Duration(minutes: minutes));

    try {
      final changed = await _mcpClient.detectChanges(since: since);
      return ToolResult.success({'changed': changed, 'count': changed.length});
    } catch (e) {
      return ToolResult.failure('Change detection failed: $e');
    }
  }
}

/// GraphRAG: ANN search → subgraph expansion → Gemini answer
class GraphRagTool extends AgentTool {
  GraphRagTool()
      : super(
          name: 'brainweave_graphrag',
          description: 'Ask a question grounded in the full knowledge graph. '
              'Uses vector search + graph traversal + Gemini for deep answers.',
          inputSchema: {
            'query': {
              'type': 'string',
              'description': 'The natural language question to answer.',
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    if (!AppConfig.brainweaveV2Enabled) {
      return ToolResult.failure('GraphRAG requires BrainWeave 2.0.');
    }

    final query = parameters['query'] as String?;
    if (query == null || query.isEmpty) {
      return ToolResult.failure('Missing query parameter');
    }

    try {
      final result = await _mcpClient.graphRag(query: query);
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('GraphRAG failed: $e');
    }
  }
}


// ═══════════════════════════════════════════════════════════
// BrainWeave GSD + ECC Upgrade Tools (behind brainweave_gsd_ecc_enabled)
// ═══════════════════════════════════════════════════════════

/// GSD Plan Phase: Generate XML task spec with acceptance criteria
class PlanPhaseTool extends AgentTool {
  PlanPhaseTool()
      : super(
          name: 'brainweave_plan_phase',
          description: 'Generate a structured XML task specification with acceptance criteria '
              'from requirements and context. GSD Discuss→Plan pattern.',
          inputSchema: {
            'requirements': {
              'type': 'string',
              'description': 'The requirements to plan for.',
            },
            'context': {
              'type': 'string',
              'description': 'Optional context (e.g. from CONTEXT.md).',
            },
            'phaseNumber': {
              'type': 'integer',
              'description': 'Phase number in the roadmap (default 1).',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final requirements = parameters['requirements'] as String?;
    if (requirements == null || requirements.isEmpty) {
      return ToolResult.failure('Missing requirements parameter');
    }
    try {
      final result = await _mcpClient.planPhase(
        requirements: requirements,
        context: parameters['context'] as String? ?? '',
        phaseNumber: parameters['phaseNumber'] as int? ?? 1,
      );
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Plan phase failed: $e');
    }
  }
}

/// GSD Verify: Validate plan against requirements
class VerifyRequirementsTool extends AgentTool {
  VerifyRequirementsTool()
      : super(
          name: 'brainweave_verify_requirements',
          description: 'Validate an XML task plan against requirements. '
              'Returns pass/fail with gap analysis.',
          inputSchema: {
            'planXml': {
              'type': 'string',
              'description': 'The XML plan to verify.',
            },
            'requirements': {
              'type': 'string',
              'description': 'The requirements to verify against.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final planXml = parameters['planXml'] as String?;
    final requirements = parameters['requirements'] as String?;
    if (planXml == null || requirements == null) {
      return ToolResult.failure('Missing planXml or requirements');
    }
    try {
      final result = await _mcpClient.verifyRequirements(
        planXml: planXml,
        requirements: requirements,
      );
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Verify requirements failed: $e');
    }
  }
}

/// ECC Quality Gate: Check agent output before commit
class QualityGateTool extends AgentTool {
  QualityGateTool()
      : super(
          name: 'brainweave_quality_gate',
          description: 'Run quality checks on agent output against acceptance criteria. '
              'Returns pass/fail with score and recommendations.',
          inputSchema: {
            'output': {
              'type': 'string',
              'description': 'The agent output to evaluate.',
            },
            'acceptanceCriteria': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'List of criteria to check against.',
            },
            'taskName': {
              'type': 'string',
              'description': 'Name of the task being evaluated.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final output = parameters['output'] as String?;
    if (output == null || output.isEmpty) {
      return ToolResult.failure('Missing output parameter');
    }
    try {
      final result = await _mcpClient.qualityGate(
        output: output,
        acceptanceCriteria: (parameters['acceptanceCriteria'] as List?)?.cast<String>() ?? [],
        taskName: parameters['taskName'] as String? ?? 'unknown',
      );
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Quality gate failed: $e');
    }
  }
}

/// GSD: Load minimal context (PROJECT.md, STATE.md, etc.)
class LoadMinimalContextTool extends AgentTool {
  LoadMinimalContextTool()
      : super(
          name: 'brainweave_load_minimal_context',
          description: 'Load GSD-style persistent context files (PROJECT.md, '
              'REQUIREMENTS.md, STATE.md, CONTEXT.md) from the knowledge graph.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    try {
      final result = await _mcpClient.loadMinimalContext();
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Load context failed: $e');
    }
  }
}

/// ECC: Show learned instincts with confidence
class InstinctStatusTool extends AgentTool {
  InstinctStatusTool()
      : super(
          name: 'brainweave_instinct_status',
          description: 'Show learned instincts grouped by category with confidence scores. '
              'Part of the ECC continuous learning system.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    try {
      final result = await _mcpClient.instinctStatus();
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Instinct status failed: $e');
    }
  }
}

/// ECC: Evolve instincts into skills
class EvolveTool extends AgentTool {
  EvolveTool()
      : super(
          name: 'brainweave_evolve',
          description: 'Cluster related instincts into reusable skills. '
              'Uses Gemini to identify patterns and create skill nodes.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    try {
      final result = await _mcpClient.evolve();
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Evolve failed: $e');
    }
  }
}

/// GSD Brownfield Mapping: Map existing knowledge base
class MapKnowledgeBaseTool extends AgentTool {
  MapKnowledgeBaseTool()
      : super(
          name: 'brainweave_map_knowledge_base',
          description: 'Analyze and map the existing knowledge base. '
              'Produces architecture, patterns, conventions, gaps, and recommendations.',
          inputSchema: {},
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    try {
      final result = await _mcpClient.mapKnowledgeBase();
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Knowledge base mapping failed: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════
// BrainWeave Context-Hub Upgrades Tools
// ═══════════════════════════════════════════════════════════

/// Context-Hub: Meeting Sync
class MeetingSyncTool extends AgentTool {
  MeetingSyncTool()
      : super(
          name: 'brainweave_meeting_sync',
          description: 'Extract decisions, claims, action items, and topic nodes '
              'from a meeting transcript (Zoom, Meet, etc.) into the knowledge graph.',
          inputSchema: {
            'transcript': {
              'type': 'string',
              'description': 'The full text transcript of the meeting.',
            },
            'clientId': {
              'type': 'string',
              'description': 'Optional. Link knowledge to a specific client profile.',
            },
            'scope': {
              'type': 'string',
              'description': 'Scope of the generated nodes. Defaults to PRIVATE.',
              'enum': ['PRIVATE', 'CLIENT', 'AGENCY']
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final transcript = parameters['transcript'] as String?;
    if (transcript == null || transcript.isEmpty) {
      return ToolResult.failure('Missing transcript parameter');
    }

    try {
      final result = await _mcpClient.meetingSync(
        transcript: transcript,
        clientId: parameters['clientId'] as String?,
        scope: parameters['scope'] as String?,
      );
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Meeting sync failed: $e');
    }
  }
}

/// Context-Hub: Annotate
class AnnotateTool extends AgentTool {
  AnnotateTool()
      : super(
          name: 'brainweave_annotate',
          description: 'Append an annotation or context note to an existing knowledge node.',
          inputSchema: {
            'nodeId': {
              'type': 'string',
              'description': 'The ID of the node to annotate.',
            },
            'text': {
              'type': 'string',
              'description': 'The annotation text to add.',
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final nodeId = parameters['nodeId'] as String?;
    final text = parameters['text'] as String?;
    
    if (nodeId == null || text == null) {
      return ToolResult.failure('Missing nodeId or text');
    }

    try {
      final result = await _mcpClient.annotate(nodeId: nodeId, text: text);
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Annotation failed: $e');
    }
  }
}

/// Context-Hub: Feedback
class FeedbackTool extends AgentTool {
  FeedbackTool()
      : super(
          name: 'brainweave_feedback',
          description: 'Upvote or downvote a node or annotation to provide feedback '
              'to the Evolution loop. Use 1 for upvote, -1 for downvote.',
          inputSchema: {
            'targetId': {
              'type': 'string',
              'description': 'The ID of the node or annotation to provide feedback on.',
            },
            'vote': {
              'type': 'integer',
              'description': '1 for upvote, -1 for downvote.',
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final targetId = parameters['targetId'] as String?;
    final vote = parameters['vote'] as int?;
    
    if (targetId == null || vote == null || (vote != 1 && vote != -1)) {
      return ToolResult.failure('Valid targetId and vote (1 or -1) required');
    }

    try {
      final result = await _mcpClient.feedback(targetId: targetId, vote: vote);
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Feedback failed: $e');
    }
  }
}

/// Context-Hub: Get External Doc
class GetExternalDocTool extends AgentTool {
  GetExternalDocTool()
      : super(
          name: 'brainweave_get_external_doc',
          description: 'Fetch an external Markdown document via URL and store it as a versioned node '
              'in the BrainWeave graph.',
          inputSchema: {
            'url': {
              'type': 'string',
              'description': 'The full HTTP/HTTPS URL of the Markdown document.',
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final url = parameters['url'] as String?;
    if (url == null || url.isEmpty) {
      return ToolResult.failure('Missing url parameter');
    }

    try {
      final result = await _mcpClient.getExternalDoc(url: url);
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Get external doc failed: $e');
    }
  }
}

/// GitNexus: Generate Wiki from subgraph
class WikiGenerateTool extends AgentTool {
  WikiGenerateTool()
      : super(
          name: 'brainweave_wiki',
          description: 'Transforms a disorganized subgraph around a specific node into a highly structured '
              'Markdown Wiki page. Useful for consolidating knowledge into a single document.',
          inputSchema: {
            'nodeId': {
              'type': 'string',
              'description': 'The exact ID of the central node for the wiki generation.',
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final nodeId = parameters['nodeId'] as String?;
    if (nodeId == null || nodeId.isEmpty) {
      return ToolResult.failure('Missing nodeId parameter');
    }

    try {
      final result = await _mcpClient.wikiGenerate(nodeId: nodeId);
      return ToolResult.success(result);
    } catch (e) {
      return ToolResult.failure('Wiki generation failed: $e');
    }
  }
}
