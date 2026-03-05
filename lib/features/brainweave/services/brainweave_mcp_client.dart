import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Central HTTP client for the BrainWeave 2.0 MCP API (Cloud Run).
/// Wraps all 8 MCP tools + GraphRAG endpoint.
class BrainWeaveMcpClient {
  // TODO: Replace with your actual Cloud Run URL after deployment
  static const _baseUrl = String.fromEnvironment(
    'BRAINWEAVE_MCP_URL',
    defaultValue: 'https://brainweave-mcp-1096509611056.us-central1.run.app',
  );

  final FirebaseAuth _auth;

  BrainWeaveMcpClient({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// Get Firebase ID token for authenticated requests.
  Future<Map<String, String>> _headers() async {
    final token = await _auth.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'X-Owner-Id': _auth.currentUser?.uid ?? 'dev-user',
    };
  }

  /// Generic POST helper.
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: await _headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint('MCP API error ($endpoint): ${response.statusCode} ${response.body}');
        throw Exception('MCP API error: ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('MCP API call failed ($endpoint): $e');
      rethrow;
    }
  }

  // ─── Tool 1: graph_query (semantic search) ────────────────────────────────

  /// Semantic vector search across the knowledge graph.
  Future<List<Map<String, dynamic>>> graphQuery({
    required String query,
    String? scope,
    int limit = 5,
  }) async {
    final result = await _post('brainweave_graph_query', {
      'query': query,
      if (scope != null) 'scope': scope,
      'limit': limit,
    });
    return List<Map<String, dynamic>>.from(result['results'] ?? []);
  }

  // ─── Tool 2: impact (N-hop analysis) ──────────────────────────────────────

  /// Find all nodes affected by changes to a given node.
  Future<Map<String, dynamic>> impact({
    required String nodeId,
    int maxDepth = 3,
    double minConfidence = 0.5,
  }) async {
    return await _post('brainweave_impact', {
      'node_id': nodeId,
      'max_depth': maxDepth,
      'min_confidence': minConfidence,
    });
  }

  // ─── Tool 3: cluster (community detection) ────────────────────────────────

  /// Find connected components / communities in the graph.
  Future<List<Map<String, dynamic>>> cluster({String? scope}) async {
    final result = await _post('brainweave_cluster', {
      if (scope != null) 'scope': scope,
    });
    return List<Map<String, dynamic>>.from(result['clusters'] ?? []);
  }

  // ─── Tool 4: context (360° view) ──────────────────────────────────────────

  /// Get full context for a node: content + incoming + outgoing edges.
  Future<Map<String, dynamic>> context({required String nodeId}) async {
    return await _post('brainweave_context', {
      'node_id': nodeId,
    });
  }

  // ─── Tool 5: create (with auto-linking) ───────────────────────────────────

  /// Create a new node and auto-link to similar nodes via ANN.
  Future<Map<String, dynamic>> create({
    required String title,
    String description = '',
    String content = '',
    String nodeType = 'atomic',
    List<String> topics = const [],
    String scope = 'PRIVATE',
    String? clientId,
    String? sourceAgent,
    Map<String, dynamic>? metadata,
  }) async {
    return await _post('brainweave_create', {
      'title': title,
      'description': description,
      'content': content,
      'node_type': nodeType,
      'topics': topics,
      'scope': scope,
      if (clientId != null) 'client_id': clientId,
      if (sourceAgent != null) 'source_agent': sourceAgent,
      if (metadata != null) 'metadata': metadata,
    });
  }

  // ─── Tool 6: reweave (backward update) ────────────────────────────────────

  /// Propagate new knowledge from a node to its connected neighbors.
  Future<Map<String, dynamic>> reweave({required String nodeId}) async {
    return await _post('brainweave_reweave', {
      'node_id': nodeId,
    });
  }

  // ─── Tool 7: detect_changes (diff-based) ──────────────────────────────────

  /// Find nodes modified since a given timestamp.
  Future<List<Map<String, dynamic>>> detectChanges({
    required DateTime since,
  }) async {
    final result = await _post('brainweave_detect_changes', {
      'since': since.toIso8601String(),
    });
    return List<Map<String, dynamic>>.from(result['changed'] ?? []);
  }

  // ─── Tool 8: promote (scope elevation) ────────────────────────────────────

  /// Propose a node for promotion to CLIENT or AGENCY scope.
  Future<Map<String, dynamic>> promote({
    required String nodeId,
    String reason = '',
    String targetScope = 'AGENCY',
  }) async {
    return await _post('brainweave_promote', {
      'node_id': nodeId,
      'reason': reason,
      'target_scope': targetScope,
    });
  }

  // ─── GraphRAG ─────────────────────────────────────────────────────────────

  /// Full GraphRAG query: ANN search → subgraph expansion → Gemini answer.
  Future<Map<String, dynamic>> graphRag({required String query}) async {
    return await _post('brainweave_graphrag', {
      'query': query,
    });
  }

  // ─── Graph Data (V2) ──────────────────────────────────────────────────────

  /// Fetch all nodes and edges for the graph explorer.
  Future<Map<String, dynamic>> getGraphData() async {
    return await _post('brainweave_graph_data', {});
  }

  // ─── Agency Graph (Superadmin Only) ───────────────────────────────────────

  /// Fetch agency-wide graph data (CLIENT + AGENCY scope nodes). Requires superadmin.
  Future<Map<String, dynamic>> getAgencyGraphData() async {
    return await _post('brainweave_agency_graph', {});
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  /// Get graph stats: node/edge counts, daily interactions, estimated cost.
  Future<Map<String, dynamic>> getStats() async {
    return await _post('brainweave_stats', {});
  }
}
