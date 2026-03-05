import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_proxy_service.dart';

/// Service for interacting with BigQuery (Metadata, Documents, Metrics).
/// Uses a secure Cloud Function proxy to execute queries and ingest data.
class BigQueryService {
  static const String _datasetId = 'inhaus_brain_knowledge';
  
  // Cloud Function URL for BigQuery operations
  static String get _bigQueryProxyUrl {
    // Reusing the same proxy logic as AIProxyService
    if (kDebugMode) {
      return 'https://us-central1-inhausbrain.cloudfunctions.net/bigqueryProxy'; // Assuming we'll deploy this
    }
    return 'https://us-central1-inhausbrain.cloudfunctions.net/bigqueryProxy';
  }

  /// Executes a BigQuery SQL query.
  Future<List<Map<String, dynamic>>> executeQuery(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');
    final idToken = await user.getIdToken();

    try {
      final response = await http.post(
        Uri.parse(_bigQueryProxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'action': 'query',
          'query': query,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['rows'] ?? []);
      } else {
        throw Exception('BigQuery Proxy Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('BigQuery Error: $e');
      rethrow;
    }
  }

  /// Ingests a document and its chunks into BigQuery.
  Future<void> ingestDocument({
    required String documentId,
    required String clientId,
    required String platform,
    required String type,
    required String title,
    required String content,
    required List<List<double>> embeddings,
    Map<String, dynamic>? metadata,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');
    final idToken = await user.getIdToken();

    final chunks = _chunkContent(content);
    
    final body = {
      'action': 'ingest_document',
      'document': {
        'document_id': documentId,
        'client_id': clientId,
        'source_platform': platform,
        'source_type': type,
        'title': title,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      },
      'chunks': List.generate(chunks.length, (i) => {
        'chunk_id': '${documentId}_$i',
        'document_id': documentId,
        'content': chunks[i],
        'embedding': i < embeddings.length ? embeddings[i] : null,
      }),
    };

    final response = await http.post(
      Uri.parse(_bigQueryProxyUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('BigQuery Ingestion Failed: ${response.body}');
    }
  }

  /// Basic recursive character splitter simulation
  List<String> _chunkContent(String content, {int size = 1000}) {
    if (content.length <= size) return [content];
    List<String> result = [];
    for (var i = 0; i < content.length; i += size) {
      result.add(content.substring(i, i + size > content.length ? content.length : i + size));
    }
    return result;
  }

  /// Fetches social/paid media performance metrics.
  Future<List<Map<String, dynamic>>> getMetrics({
    required String clientId,
    required String platform,
    DateTime? start,
    DateTime? end,
  }) async {
    final startStr = (start ?? DateTime.now().subtract(const Duration(days: 30))).toIso8601String().split('T')[0];
    final endStr = (end ?? DateTime.now()).toIso8601String().split('T')[0];
    
    final query = """
      SELECT * FROM `inhaus_brain_knowledge.social_metrics`
      WHERE client_id = '$clientId'
      AND platform = '$platform'
      AND metric_date BETWEEN '$startStr' AND '$endStr'
      ORDER BY metric_date DESC
    """;
    
    return executeQuery(query);
  }

  Future<List<Map<String, dynamic>>> getAiPerformanceMetrics({int days = 7}) async {
    return []; // Stub to fix compile error
  }

  Future<List<Map<String, dynamic>>> getUsageMetrics({int days = 7}) async {
    return []; // Stub to fix compile error
  }
}
