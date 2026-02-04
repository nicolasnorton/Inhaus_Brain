import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../auth/secret_vault_service.dart';

class PineconeService {
  final SecretVaultService _vault;
  final http.Client _client;
  
  // Cache the host url if possible
  String? _cachedHost;

  PineconeService(this._vault, {http.Client? client}) 
      : _client = client ?? http.Client();

  Future<String?> _getApiKey() async => await _vault.getSecret('PINECONE_API_KEY');
  Future<String?> _getIndexHost() async => await _vault.getSecret('PINECONE_INDEX_HOST'); // e.g. https://index-name-project.svc.environment.pinecone.io

  /// Upsert vectors to Pinecone
  Future<void> upsertVectors({
    required List<Map<String, dynamic>> vectors, // [{id: 'id', values: [0.1...], metadata: {...}}]
    String namespace = '',
  }) async {
    final apiKey = await _getApiKey();
    final host = await _getIndexHost();

    if (apiKey == null || host == null) {
      debugPrint('PineconeService: Missing API Key or Index Host');
      return; 
    }

    final url = Uri.parse('$host/vectors/upsert');
    
    try {
      final response = await _client.post(
        url,
        headers: {
          'Api-Key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'vectors': vectors,
          'namespace': namespace,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Pinecone Upsert Failed: ${response.statusCode} ${response.body}');
      }
      
      debugPrint('PineconeService: Successfully upserted ${vectors.length} vectors.');
    } catch (e) {
      debugPrint('PineconeService Error: $e');
      rethrow;
    }
  }

  /// Query vectors
  Future<List<Map<String, dynamic>>> queryVectors({
    required List<double> vector,
    int topK = 10,
    String namespace = '',
    Map<String, dynamic>? filter,
    bool includeMetadata = true,
  }) async {
    final apiKey = await _getApiKey();
    final host = await _getIndexHost();

    if (apiKey == null || host == null) {
      debugPrint('PineconeService: Missing API Key or Index Host');
      return []; 
    }

    final url = Uri.parse('$host/query');
    
    try {
      final body = {
        'vector': vector,
        'topK': topK,
        'namespace': namespace,
        'includeMetadata': includeMetadata,
      };
      
      if (filter != null) {
        body['filter'] = filter;
      }

      final response = await _client.post(
        url,
        headers: {
          'Api-Key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Pinecone Query Failed: ${response.statusCode} ${response.body}');
      }
      
      final data = jsonDecode(response.body);
      final matches = (data['matches'] as List).cast<Map<String, dynamic>>();
      
      return matches;
    } catch (e) {
      debugPrint('PineconeService Query Error: $e');
      rethrow;
    }
  }
}
