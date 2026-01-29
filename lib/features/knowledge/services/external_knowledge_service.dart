import 'dart:convert';
// import 'dart:io'; // Removed for web compatibility
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../../core/services/semantic_cache_service.dart';
import '../models/external_knowledge_models.dart';

/// Service for managing external knowledge API connections and queries
class ExternalKnowledgeService {
  final http.Client _client;
  final SemanticCacheService? _cache;
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  ExternalKnowledgeService({http.Client? client, SemanticCacheService? cache})
      : _client = client ?? http.Client(),
        _cache = cache;

  /// Test connection to external knowledge API (health check)
  /// Sends a non-JSON request and expects 200 response
  Future<bool> testConnection(String endpoint, String? apiKey) async {
    try {
      final uri = _buildUri(endpoint);
      final headers = _buildHeaders(apiKey, includeJson: false);

      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Query external knowledge base with optional Intent-based filtering (JIT Context)
  Future<ExternalKnowledgeResponse> queryKnowledge({
    required ExternalKnowledgeRequest request,
    required String endpoint,
    String? apiKey,
    String? intent, // RouterIntent name (e.g., 'research', 'creative')
  }) async {
    // Just-in-Time Context Injection
    ExternalKnowledgeRequest finalRequest = request;
    
    if (intent != null) {
      // Map Intent to Metadata Filters
      final conditionName = intent.toLowerCase() == 'research' ? 'category' : 
                            intent.toLowerCase() == 'creative' ? 'type' : null;
      final conditionValue = intent.toLowerCase() == 'research' ? 'pdf' : 
                             intent.toLowerCase() == 'creative' ? 'image' : null;

      if (conditionName != null && conditionValue != null) {
         final filter = MetadataCondition(
           logicalOperator: 'and',
           conditions: [
             Condition(
               name: [conditionName], 
               comparisonOperator: '==', 
               value: conditionValue
             )
           ]
         );
         
         // Create a new request with the filter injected
         finalRequest = ExternalKnowledgeRequest(
           knowledgeId: request.knowledgeId,
           query: request.query,
           retrievalSetting: request.retrievalSetting,
           metadataCondition: filter // Override or merge could be better, but override for safety here
         );
      }
    }
    
    final cacheKey = 'external:${finalRequest.knowledgeId}:${finalRequest.query}:$endpoint:$intent';
    
    if (_cache != null) {
      final cachedResponse = await _cache!.lookup('external_knowledge', cacheKey);
      if (cachedResponse != null) {
        try {
          return ExternalKnowledgeResponse.fromJson(jsonDecode(cachedResponse) as Map<String, dynamic>);
        } catch (_) {}
      }
    }

    int retries = 0;

    while (retries < _maxRetries) {
      try {
        final uri = _buildUri(endpoint);
        final headers = _buildHeaders(apiKey, includeJson: true);
        final body = jsonEncode(finalRequest.toJson());

        final response = await _client
            .post(uri, headers: headers, body: body)
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
          
          if (!validateResponse(jsonResponse)) {
            throw FormatException('Invalid response format from external API');
          }

          final responseData = ExternalKnowledgeResponse.fromJson(jsonResponse);
          
          if (_cache != null) {
            await _cache!.store('external_knowledge', cacheKey, jsonEncode(jsonResponse));
          }

          return responseData;
        } else if (response.statusCode == 403) {
          throw ExternalKnowledgeException(
            ExternalKnowledgeError(
              errorCode: ExternalKnowledgeError.authFailed,
              errorMsg: 'Authorization failed',
            ),
          );
        } else if (response.statusCode == 500) {
          throw ExternalKnowledgeException(
            ExternalKnowledgeError(
              errorCode: 500,
              errorMsg: 'Internal server error',
            ),
          );
        } else {
          // Try to parse error response
          try {
            final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
            final error = ExternalKnowledgeError.fromJson(errorJson);
            throw ExternalKnowledgeException(error);
          } catch (_) {
            throw ExternalKnowledgeException(
              ExternalKnowledgeError(
                errorCode: response.statusCode,
                errorMsg: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
              ),
            );
          }
        }
      } catch (e) {
        if (e.toString().contains('SocketException') || e.toString().contains('Connection failed')) {
          retries++;
          if (retries >= _maxRetries) {
            throw ExternalKnowledgeException(
              ExternalKnowledgeError(
                errorCode: 0,
                errorMsg: 'Network connection failed after $retries attempts',
              ),
            );
          }
          await Future.delayed(Duration(milliseconds: 500 * retries));
        } else if (e is TimeoutException) {
          retries++;
          if (retries >= _maxRetries) {
            throw ExternalKnowledgeException(
              ExternalKnowledgeError(
                errorCode: 0,
                errorMsg: 'Request timeout after $retries attempts',
              ),
            );
          }
          await Future.delayed(Duration(milliseconds: 500 * retries));
        } else if (e is ExternalKnowledgeException) {
          rethrow;
        } else {
           throw ExternalKnowledgeException(
            ExternalKnowledgeError(
              errorCode: 0,
              errorMsg: 'Unexpected error: $e',
            ),
          );
        }
      }
    }

    throw ExternalKnowledgeException(
      ExternalKnowledgeError(
        errorCode: 0,
        errorMsg: 'Maximum retries exceeded',
      ),
    );
  }

  /// Validate API response format
  bool validateResponse(Map<String, dynamic> response) {
    if (!response.containsKey('records')) return false;
    if (response['records'] is! List) return false;

    final records = response['records'] as List;
    for (final record in records) {
      if (record is! Map<String, dynamic>) return false;
      if (!record.containsKey('content')) return false;
      if (!record.containsKey('score')) return false;
      if (!record.containsKey('title')) return false;
    }

    return true;
  }

  /// Build URI for API endpoint
  Uri _buildUri(String endpoint) {
    // Ensure endpoint ends with /retrieval
    String normalizedEndpoint = endpoint.trim();
    if (!normalizedEndpoint.endsWith('/retrieval')) {
      normalizedEndpoint = '$normalizedEndpoint/retrieval';
    }

    return Uri.parse(normalizedEndpoint);
  }

  /// Build HTTP headers with optional Bearer token
  Map<String, String> _buildHeaders(String? apiKey, {required bool includeJson}) {
    final headers = <String, String>{};

    if (includeJson) {
      headers['Content-Type'] = 'application/json';
    }

    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    return headers;
  }

  /// Generate LlamaCloud endpoint URL based on region
  static String generateLlamaCloudEndpoint(String region) {
    final baseUrl = region.toLowerCase() == 'eu'
        ? 'https://api.cloud.eu.llamaindex.ai'
        : 'https://api.cloud.llamaindex.ai';
    return '$baseUrl/retrieval';
  }

  void dispose() {
    _client.close();
  }
}

/// Exception thrown when external knowledge API returns an error
class ExternalKnowledgeException implements Exception {
  final ExternalKnowledgeError error;

  ExternalKnowledgeException(this.error);

  @override
  String toString() => 'ExternalKnowledgeException: ${error.errorDescription}';
}
