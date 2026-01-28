import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'ai_proxy_service.dart';

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
    // PATH 0: WEB PROXY (Use for all requests on web if possible to avoid CORS/Auth issues)
    if (kIsWeb) {
      try {
        debugPrint('VertexAI: [WEB] Routing Embeddings via Secure Proxy...');
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
        debugPrint('VertexAI: [WEB] Proxy Embeddings failed: $e. Falling back to native if keys exist.');
      }
    }

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

      return _parsePredictions(predictions);
    }

    // PATH 2: Gemini Developer API (Supports API Key)
    if (apiKey != null && apiKey.isNotEmpty) {
      // Primary Attempt: text-embedding-004
      var result = await _callGeminiEmbeddings(texts, apiKey, _embeddingModel);
      
      // Fallback Attempt: embedding-001
      if (result.isEmpty) {
         debugPrint('VertexAI: text-embedding-004 failed (empty). Retrying with embedding-001...');
         result = await _callGeminiEmbeddings(texts, apiKey, 'embedding-001');
      }

      return result;
    }

    throw Exception('VertexApiService: No valid API Key or Access Token provided.');
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
