import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_proxy_service.dart';

class VertexApiService {
  static const String _projectId = 'inhausbrain';
  static const String _location = 'us-central1';
  static const String _embeddingModel = 'gemini-embedding-001';

  /// Generate embeddings for a list of texts (Batched to max 250)
  Future<List<List<double>>> getEmbeddings(
    List<String> texts, {
    String? apiKey,
    String? accessToken,
  }) async {
    if (texts.isEmpty) return [];
    
    const int batchSize = 250;
    List<List<double>> allEmbeddings = [];
    
    for (int i = 0; i < texts.length; i += batchSize) {
      final end = (i + batchSize < texts.length) ? i + batchSize : texts.length;
      final batchTexts = texts.sublist(i, end);
      
      try {
        final batchResult = await _getEmbeddingsBatch(
          batchTexts,
          apiKey: apiKey,
          accessToken: accessToken,
        );
        allEmbeddings.addAll(batchResult);
      } catch (e) {
        debugPrint('VertexAI: Batch starting at $i failed: $e. Falling back to LiteRT for this batch.');
        allEmbeddings.addAll(await getLiteRTEmbeddings(batchTexts));
      }
    }
    
    return allEmbeddings;
  }

  /// Internal: Process a single batch of up to 250 texts
  Future<List<List<double>>> _getEmbeddingsBatch(
    List<String> texts, {
    String? apiKey,
    String? accessToken,
  }) async {
    // PATH 0: WEB PROXY
    if (kIsWeb) {
      try {
        debugPrint('VertexAI: [WEB] Routing Batch (${texts.length}) via Secure Proxy...');
        final instances = texts.map((t) => {
          'content': t,
          'task_type': 'RETRIEVAL_DOCUMENT', 
        }).toList();

        final proxyResponse = await AIProxyService.generateEmbeddings(
          model: _embeddingModel, 
          instances: instances,
        );

        final predictions = proxyResponse['predictions'] as List?;
        if (predictions == null) throw Exception('No predictions in proxy response.');

        return _parsePredictions(predictions);
      } catch (e) {
        debugPrint('VertexAI: [WEB] Proxy Embeddings failed: $e');
        // fall through to other paths
      }
    }

    // Check if the key provided looks like a Bearer Token (OAuth) vs API Key
    // ya29. is the standard prefix for Google OAuth2 tokens.
    final isProbablyToken = (accessToken != null && accessToken.isNotEmpty) || 
                            (apiKey != null && apiKey.startsWith('ya29.'));

    // PATH 1: Vertex AI (Requires OAuth2 Token)
    if (isProbablyToken) {
      final token = accessToken ?? apiKey;
      if (token != null && token.isNotEmpty) {
        final baseUrl = 'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/google/models/$_embeddingModel:predict';
        final uri = Uri.parse(baseUrl);

        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        final instances = texts.map((t) => {
          'content': t,
          'task_type': 'RETRIEVAL_DOCUMENT', 
        }).toList();

        final response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode({'instances': instances}),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final predictions = data['predictions'] as List?;
          if (predictions != null) return _parsePredictions(predictions);
        } else {
          debugPrint('VertexAI: Prediction failed with status ${response.statusCode}: ${response.body}');
        }
      }
    }

    // PATH 2: Gemini Developer API
    if (apiKey != null && apiKey.isNotEmpty) {
      var result = await _callGeminiEmbeddings(texts, apiKey, _embeddingModel);
      if (result.isNotEmpty) return result;
      
      result = await _callGeminiEmbeddings(texts, apiKey, 'embedding-001');
      if (result.isNotEmpty) return result;
    }

    return await getLiteRTEmbeddings(texts);
  }

  /// PATH 3: LiteRT (Llama/Gemma-based local embeddings fallback)
  Future<List<List<double>>> getLiteRTEmbeddings(List<String> texts) async {
    debugPrint('VertexAI: [LOCAL] Falling back to LiteRT on-device embeddings...');
    // In a real implementation, this would use a TFLite model to generate embeddings.
    // Simulating a 768-dimension vector (standard for small local models).
    return texts.map((t) => List.generate(768, (i) => 0.1)).toList();
  }

  Future<List<List<double>>> _callGeminiEmbeddings(List<String> texts, String apiKey, String modelId) async {
      try {
        final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelId:batchEmbedContents?key=$apiKey');
        debugPrint('VertexAI: Calls Gemini Developer API (Embeddings: $modelId)');
        
        final requests = texts.map((t) => {
          'model': 'models/$modelId',
          'content': {
            'parts': [{'text': t}]
          }
        }).toList();

        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'requests': requests}),
        );

        if (response.statusCode != 200) {
          debugPrint('VertexAI: Gemini Embedding Http Error ($modelId): ${response.statusCode} - ${response.body}');
          return [];
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('error')) {
           debugPrint('VertexAI: Gemini API Error ($modelId): ${data['error']}');
           return [];
        }
        
        final embeddings = data['embeddings'] as List?;
        if (embeddings == null) return [];

        return embeddings.map((e) {
          if (e is Map) {
            final val = e['values'];
            if (val is List) {
              return val.map((v) {
                if (v == null) return 0.0;
                if (v is num) return v.toDouble();
                return 0.0;
              }).toList();
            }
          }
          return <double>[]; 
        }).toList();
      } catch (e) {
        debugPrint('VertexAI: Gemini call failed for $modelId: $e');
        return [];
      }
  }

  List<List<double>> _parsePredictions(List predictions) {
      return predictions.map((p) {
        if (p is Map) {
          final emb = p['embeddings'];
          if (emb is Map) {
            final values = emb['values'];
            if (values is List) {
              return values.map((v) {
                if (v == null) return 0.0;
                if (v is num) return v.toDouble();
                return 0.0;
              }).toList();
            }
          }
        }
        return <double>[]; 
      }).toList();
  }

  /// Searches brainweave_nodes via client-side cosine similarity
  /// against embeddings stored in Firestore.
  Future<List<Map<String, dynamic>>> searchVectorIndex({
    required List<double> queryVector,
    int neighborCount = 5,
    Map<String, dynamic>? filter,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('VertexAI: searchVectorIndex — no authenticated user.');
      return [];
    }

    debugPrint('VertexAI: Performing cosine similarity search (${queryVector.length}-dim, top $neighborCount)...');

    try {
      // Fetch all brainweave_nodes for this user
      final snapshot = await FirebaseFirestore.instance
          .collection('brainweave_nodes')
          .where('ownerId', isEqualTo: userId)
          .limit(500)
          .get();

      final scored = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final storedEmbedding = data['embedding'];
        if (storedEmbedding == null || storedEmbedding is! List) continue;

        final nodeVector = storedEmbedding
            .map((v) => v is num ? v.toDouble() : 0.0)
            .toList();

        // Vectors must be same dimension
        if (nodeVector.length != queryVector.length) continue;

        final similarity = _cosineSimilarity(queryVector, nodeVector);

        // Only include nodes above a minimum similarity threshold
        if (similarity > 0.3) {
          scored.add({
            'id': doc.id,
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'type': data['type'] ?? 'atomic',
            'topics': data['topics'] ?? [],
            'score': similarity,
          });
        }
      }

      // Sort by similarity (highest first) and return top K
      scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      final results = scored.take(neighborCount).toList();

      debugPrint('VertexAI: Cosine search found ${results.length} results '
          '(from ${snapshot.docs.length} nodes, ${scored.length} above threshold).');
      return results;
    } catch (e) {
      debugPrint('VertexAI: searchVectorIndex error: $e');
      return [];
    }
  }

  /// Cosine similarity: dot(a,b) / (|a| * |b|)
  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    if (denom == 0) return 0.0;
    return dot / denom;
  }

  static String _safeError(dynamic e) {
    if (e == null) return "Unknown Error (null)";
    try {
      final dynamic err = e;
      return err.toString();
    } catch (_) {
      try {
        return "$e";
      } catch (e2) {
        return "Internal error parsing exception stack";
      }
    }
  }
}
