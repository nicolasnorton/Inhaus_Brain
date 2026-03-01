import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mcp/agent_tool.dart';
import '../../../../core/services/vertex_ai_service.dart';
import '../../../knowledge/providers/knowledge_provider.dart';

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
    if (ref == null) return ToolResult.failure('Riverpod ref is required');

    try {
      final vertexAi = ref.read(vertexApiServiceProvider);
      final embeddings = await vertexAi.getEmbeddings([query]);
      if (embeddings.isEmpty) {
        return ToolResult.failure('Failed to generate embedding for query');
      }

      final results = await vertexAi.searchVectorIndex(
        queryVector: embeddings.first,
        neighborCount: limit,
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

    try {
      final doc = await FirebaseFirestore.instance
          .collection('brainweave_nodes')
          .doc(nodeId)
          .get();

      if (!doc.exists) {
        return ToolResult.failure('Node not found');
      }

      final data = doc.data()!;
      // Filter out embedding to save token space
      data.remove('embedding');

      // Also fetch related edges (links) to provide context on connections
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
            }
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return ToolResult.failure('No authenticated user');
    if (ref == null) return ToolResult.failure('Riverpod ref is required');

    final title = parameters['title'] as String?;
    final description = parameters['description'] as String?;
    final content = parameters['content'] as String?;
    final topics = (parameters['topics'] as List?)?.cast<String>() ?? [];

    if (title == null || content == null) {
      return ToolResult.failure('Missing required title or content');
    }

    try {
      final vertexAi = ref.read(vertexApiServiceProvider);
      
      // Generate embedding for semantic search
      final textToEmbed = "\$title \$description \$content";
      final embeddings = await vertexAi.getEmbeddings([textToEmbed]);
      List<double>? embedding = embeddings.isNotEmpty ? embeddings.first : null;

      final nodeData = {
        'clientId': 'user_\$userId',
        'projectId': 'default',
        'ownerId': userId,
        'title': title,
        'description': description ?? '',
        'content': content,
        'type': 'atomic',
        'topics': topics,
        'embedding': embedding,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('brainweave_nodes')
          .add(nodeData);

      // Triggering backend link generation isn't strictly necessary here if we just inserted
      // an isolated node, but for a true graph we should link it. 
      // For Phase 1, the LLM creates the node. We will rely on the pipeline for backward-links later.

      return ToolResult.success({
        'status': 'Node created successfully',
        'nodeId': docRef.id,
      });
    } catch (e) {
      return ToolResult.failure('Failed to create node: $e');
    }
  }
}
