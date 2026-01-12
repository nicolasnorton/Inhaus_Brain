import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/external_knowledge_models.dart';

/// Service for managing external knowledge API connections and queries
class ExternalKnowledgeService {
  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  ExternalKnowledgeService({http.Client? client})
      : _client = client ?? http.Client();

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

  /// Query external knowledge base
  Future<ExternalKnowledgeResponse> queryKnowledge({
    required ExternalKnowledgeRequest request,
    required String endpoint,
    String? apiKey,
  }) async {
    int retries = 0;

    while (retries < _maxRetries) {
      try {
        final uri = _buildUri(endpoint);
        final headers = _buildHeaders(apiKey, includeJson: true);
        final body = jsonEncode(request.toJson());

        final response = await _client
            .post(uri, headers: headers, body: body)
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
          
          if (!validateResponse(jsonResponse)) {
            throw FormatException('Invalid response format from external API');
          }

          return ExternalKnowledgeResponse.fromJson(jsonResponse);
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
      } on SocketException {
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
      } on TimeoutException {
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
      } on ExternalKnowledgeException {
        rethrow;
      } catch (e) {
        throw ExternalKnowledgeException(
          ExternalKnowledgeError(
            errorCode: 0,
            errorMsg: 'Unexpected error: $e',
          ),
        );
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
