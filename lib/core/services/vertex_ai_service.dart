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
    final isProbablyToken = (apiKey != null && (apiKey.startsWith('ya29.') || apiKey.startsWith('AQ.'))) || 
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
      final predictions = data['predictions'] as List?;
      if (predictions == null) {
        throw Exception('Vertex Embedding Failed: No predictions in response: ${response.body}');
      }

      return predictions.map((p) {
        if (p is Map && p.containsKey('embeddings')) {
          final emb = p['embeddings'] as Map?;
          if (emb != null && emb.containsKey('values')) {
            final values = emb['values'] as List?;
            if (values != null) {
               return values.cast<double>();
            }
          }
        }
        return <double>[]; // Graceful fallback for malformed response
      }).toList();
    }

    // PATH 2: Gemini Developer API (Supports API Key)
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_embeddingModel:batchEmbedContents?key=$apiKey');
        debugPrint('VertexAI: Calls Gemini Developer API (Embeddings)');
        
        final requests = texts.map((t) => {
          'model': 'models/$_embeddingModel',
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
          debugPrint('VertexAI: Gemini Embedding Http Error: ${response.statusCode}');
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
             final val = e['values'];
             if (val is List) return val.cast<double>();
          }
          return <double>[]; 
        }).toList();
      } catch (e) {
        // Safe toString
        String errStr = 'Unknown';
        try {
           if (e != null) errStr = e.toString();
        } catch (_) { errStr = 'Error getting error string'; }
        
        debugPrint('VertexAI: Gemini Fallback crashed: $errStr');
        return <List<double>>[]; // Fail safely by returning empty typed list
      }
    }

    throw Exception('VertexApiService: No valid API Key or Access Token provided.');
  }
}
