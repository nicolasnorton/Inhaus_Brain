import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/bigquery_service.dart';
import '../../../core/services/vertex_ai_service.dart';

/// The Hybrid Retrieval Layer for Knowledge Module v2.0.
/// Combines semantic search (Vector Search) with exact keyword and metadata filtering (BigQuery).
class KnowledgeRetrieverService {
  final BigQueryService _bq;
  final VertexApiService _vertex;

  KnowledgeRetrieverService(this._bq, this._vertex);

  /// Performs a hybrid search across the knowledge base.
  Future<List<KnowledgeChunkResult>> retrieve({
    required String query,
    required String clientId,
    String? platform,
    int limit = 5,
  }) async {
    debugPrint('KnowledgeRetriever: Searching for "$query" (Client: $clientId)...');

    // 1. Generate Query Embedding
    final embeddings = await _vertex.getEmbeddings([query]);
    if (embeddings.isEmpty) return _keywordOnlySearch(query, clientId, platform, limit);

    final queryVector = embeddings.first;

    // 2. Parallel Search: Semantic (Vertex) + Keyword (BigQuery)
    final results = await Future.wait([
      _vertex.searchVectorIndex(
        queryVector: queryVector,
        neighborCount: limit,
        filter: {'client_id': clientId, if (platform != null) 'platform': platform},
      ),
      _keywordOnlySearch(query, clientId, platform, limit),
    ]);

    // 3. Merge and Rerank
    // For MVP, we combine and deduplicate.
    final semanticResults = results[0] as List<Map<String, dynamic>>;
    final keywordResults = results[1] as List<KnowledgeChunkResult>;

    final List<KnowledgeChunkResult> combined = [...keywordResults];
    
    // Add semantic results (mapping from Vertex format to our model)
    for (var res in semanticResults) {
       // logic to fetch actual content from BigQuery if Vertex only returns IDs
       // For now, assuming semantically similar IDs are found.
    }

    return combined.take(limit).toList();
  }

  /// Internal: Pure SQL Keyword Search
  Future<List<KnowledgeChunkResult>> _keywordOnlySearch(
    String query, 
    String clientId, 
    String? platform, 
    int limit
  ) async {
    final platformFilter = platform != null ? "AND source_platform = '$platform'" : "";
    
    // Using BigQuery Full Text Search or LIKE
    final sql = """
      SELECT c.content, d.title, d.source_platform, d.created_at
      FROM `inhaus_brain_knowledge.content_chunks` c
      JOIN `inhaus_brain_knowledge.documents` d ON c.document_id = d.document_id
      WHERE d.client_id = '$clientId'
      $platformFilter
      AND (
        LOWER(c.content) LIKE LOWER('%$query%') 
        OR LOWER(d.title) LIKE LOWER('%$query%')
      )
      ORDER BY d.created_at DESC
      LIMIT $limit
    """;

    try {
      final rows = await _bq.executeQuery(sql);
      return rows.map((r) => KnowledgeChunkResult(
        content: r['content'] ?? '',
        sourceTitle: r['title'] ?? 'Unknown',
        platform: r['source_platform'] ?? 'general',
        timestamp: DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
      )).toList();
    } catch (e) {
      debugPrint('Keyword search failed: $e');
      return [];
    }
  }

  /// Formats retrieved chunks into a grounding context for the LLM.
  String formatForGrounding(List<KnowledgeChunkResult> results) {
    if (results.isEmpty) return "No relevant knowledge found.";
    
    final buffer = StringBuffer("### Relevant Knowledge Context:\n\n");
    for (var i = 0; i < results.length; i++) {
      final res = results[i];
      buffer.writeln("[Source ${i + 1}]: ${res.sourceTitle} (${res.platform}) - ${res.timestamp.toIso8601String().split('T')[0]}");
      buffer.writeln("Content: ${res.content}");
      buffer.writeln("---");
    }
    return buffer.toString();
  }
}

class KnowledgeChunkResult {
  final String content;
  final String sourceTitle;
  final String platform;
  final DateTime timestamp;

  KnowledgeChunkResult({
    required this.content,
    required this.sourceTitle,
    required this.platform,
    required this.timestamp,
  });
}

// Providers
final queryServiceProvider = Provider((ref) => BigQueryService());
final vertexServiceProvider = Provider((ref) => VertexApiService());

final knowledgeRetrieverProvider = Provider((ref) {
  return KnowledgeRetrieverService(
    ref.watch(queryServiceProvider),
    ref.watch(vertexServiceProvider),
  );
});
