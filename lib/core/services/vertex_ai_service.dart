import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class VertexApiService {
  static const String _projectId = 'inhausbrain';
  static const String _location = 'us-central1';
  static const String _embeddingModel = 'text-embedding-004';

  /// Generate embeddings for a list of texts
  Future<List<List<double>>> getEmbeddings(
    List<String> texts, {
    String? apiKey,
    String? accessToken,
  }) async {
    // Check if the key provided looks like a Bearer Token vs API Key
    final isProbablyToken = (apiKey != null && apiKey.startsWith('ya29.')) || 
                            (accessToken != null && accessToken.isNotEmpty);

    // PATH 1: Vertex AI (Requires OAuth Access Token or Token-as-Key)
    if (isProbablyToken) {
      final token = accessToken ?? apiKey;
      if (token == null || token.isEmpty) throw Exception('Token missing');

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

      debugPrint('VertexAI: Calls Vertex API (Embeddings) ($uri)');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'instances': instances}),
      );

      if (response.statusCode != 200) {
        throw Exception('Vertex Embedding Failed: ${response.statusCode} ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List;

      return predictions.map((p) {
        final values = (p['embeddings']['values'] as List).cast<double>();
        return values;
      }).toList();
    }

    // PATH 2: Gemini Developer API (Supports API Key)
    if (apiKey != null && apiKey.isNotEmpty) {
      final baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$_embeddingModel:batchEmbedContents?key=$apiKey';
      final requests = texts.map((t) => {
        'model': 'models/$_embeddingModel',
        'content': {
          'parts': [{'text': t}]
        }
      }).toList();

      debugPrint('VertexAI: Calls Gemini Developer API (Embeddings) ($baseUrl)');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requests': requests}),
      );

      if (response.statusCode != 200) {
        throw Exception('Gemini Embedding Failed: ${response.statusCode} ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('error')) {
         throw Exception('Gemini API Error: ${data['error']}');
      }
      
      final embeddings = data['embeddings'] as List?;
      
      if (embeddings == null) return [];

      return embeddings.map((e) {
        if (e is Map && e.containsKey('values')) {
           return (e['values'] as List).cast<double>();
        }
        return <double>[]; // Return empty vector if malformed to avoid crash
      }).toList();
    }

    throw Exception('VertexApiService: No valid API Key or Access Token provided.');
  }
}
