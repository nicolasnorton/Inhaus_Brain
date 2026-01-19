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
    if ((apiKey == null || apiKey.isEmpty) && (accessToken == null || accessToken.isEmpty)) {
      throw Exception('VertexApiService: Either API Key or Access Token is required.');
    }

    final isApiKey = apiKey != null && apiKey.isNotEmpty;
    final baseUrl = 'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/google/models/$_embeddingModel:predict';
    final uri = Uri.parse(isApiKey ? '$baseUrl?key=$apiKey' : baseUrl);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (!isApiKey && accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    // Vertex AI expects "instances": [{ "content": "text" }, ...] for text-embedding-004
    // Note: Previous models used "content", 004 might use "text" or "content". 
    // Checking standard: "content" is usually safe for Gecko, let's try "content".
    // 004 task_type defaults to RETRIEVAL_DOCUMENT for ingestion usually.
    final instances = texts.map((t) => {
      'content': t,
      'task_type': 'RETRIEVAL_DOCUMENT', 
    }).toList();

    debugPrint('VertexAI: Calls Embedding API ($uri)');

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

    // structure: predictions[i].embeddings.values (list of doubles)
    return predictions.map((p) {
      final values = (p['embeddings']['values'] as List).cast<double>();
      return values;
    }).toList();
  }
}
