import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/knowledge_api_models.dart';

/// Service for Knowledge Base API operations
/// Based on INHAUS BRAIN API specification
class KnowledgeApiService {
  final http.Client _client;
  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  KnowledgeApiService({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 30);
  static const _cacheDuration = Duration(minutes: 5);
  final _cache = <String, dynamic>{};
  final _cacheTime = <String, DateTime>{};

  // ==================== Knowledge Base Operations ====================

  /// Create an empty knowledge base
  Future<KnowledgeBase> createKnowledgeBase({
    required String name,
    String? description,
    String permission = 'only_me',
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets');
    final headers = await _buildHeaders();
    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'name': name,
            if (description != null) 'description': description,
            'permission': permission,
          }),
        )
        .timeout(_timeout);

    _checkResponse(response);
    return KnowledgeBase.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Get list of knowledge bases
  Future<List<KnowledgeBase>> listKnowledgeBases({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'datasets_p${page}_l$limit';
    
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<KnowledgeBase>;
    }

    final uri = Uri.parse('$baseUrl/v1/datasets').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final headers = await _buildHeaders();
    final response = await _client
        .get(uri, headers: headers)
        .timeout(_timeout);

    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List;
    final result = data.map((item) => KnowledgeBase.fromJson(item as Map<String, dynamic>)).toList();
    
    _setCache(cacheKey, result);
    return result;
  }

  /// Delete a knowledge base
  Future<void> deleteKnowledgeBase(String datasetId) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId');
    final headers = await _buildHeaders();
    final response = await _client
        .delete(uri, headers: headers)
        .timeout(_timeout);

    if (response.statusCode != 204) {
      _checkResponse(response);
    }
  }

  // ==================== Document Operations ====================

  /// Create a document from text
  Future<KnowledgeDocument> createDocumentFromText({
    required String datasetId,
    required String name,
    required String text,
    String indexingTechnique = 'high_quality',
    Map<String, dynamic>? processRule,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/document/create_by_text');
    final headers = await _buildHeaders();
    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'name': name,
            'text': text,
            'indexing_technique': indexingTechnique,
            'process_rule': processRule ?? {'mode': 'automatic'},
          }),
        )
        .timeout(_timeout);

    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KnowledgeDocument.fromJson(json['document'] as Map<String, dynamic>);
  }

  /// Create a document from file or bytes
  Future<KnowledgeDocument> createDocumentFromFile({
    required String datasetId,
    File? file,
    List<int>? bytes,
    String? filename,
    String indexingTechnique = 'high_quality',
    Map<String, dynamic>? processRule,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/document/create-by-file');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _buildHeaders(includeContentType: false);
    request.headers.addAll(headers);

    // Add file
    if (bytes != null && filename != null) {
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    } else if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    } else {
      throw ArgumentError('Either file or bytes+filename must be provided');
    }

    // Add data
    request.fields['data'] = jsonEncode({
      'indexing_technique': indexingTechnique,
      'process_rule': processRule ?? {'mode': 'automatic'},
    });

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);

    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KnowledgeDocument.fromJson(json['document'] as Map<String, dynamic>);
  }

  /// Update a document with text
  Future<KnowledgeDocument> updateDocumentWithText({
    required String datasetId,
    required String documentId,
    required String name,
    required String text,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/documents/$documentId/update_by_text');
    final headers = await _buildHeaders();
    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'name': name,
            'text': text,
          }),
        )
        .timeout(_timeout);

    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KnowledgeDocument.fromJson(json['document'] as Map<String, dynamic>);
  }

  /// Update a document with file or bytes
  Future<KnowledgeDocument> updateDocumentWithFile({
    required String datasetId,
    required String documentId,
    File? file,
    List<int>? bytes,
    String? filename,
    String? name,
    String indexingTechnique = 'high_quality',
    Map<String, dynamic>? processRule,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/documents/$documentId/update-by-file');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _buildHeaders(includeContentType: false);
    request.headers.addAll(headers);

    if (bytes != null && filename != null) {
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    } else if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    } else {
      throw ArgumentError('Either file or bytes+filename must be provided');
    }

    request.fields['data'] = jsonEncode({
      if (name != null) 'name': name,
      'indexing_technique': indexingTechnique,
      'process_rule': processRule ?? {'mode': 'automatic'},
    });

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);

    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KnowledgeDocument.fromJson(json['document'] as Map<String, dynamic>);
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String datasetId,
    required String documentId,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/documents/$documentId');
    final headers = await _buildHeaders();
    final response = await _client
        .delete(uri, headers: headers)
        .timeout(_timeout);

    _checkResponse(response);
  }

  /// Get list of documents in a knowledge base
  Future<List<KnowledgeDocument>> listDocuments({
    required String datasetId,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/documents').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final headers = await _buildHeaders();
    final response = await _client
        .get(uri, headers: headers)
        .timeout(_timeout);

    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List;
    return data.map((item) => KnowledgeDocument.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Get document indexing status
  Future<List<IndexingStatus>> getIndexingStatus({
    required String datasetId,
    required String batch,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/documents/$batch/indexing-status');
    final headers = await _buildHeaders();
    final response = await _client
        .get(uri, headers: headers)
        .timeout(_timeout);

    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List;
    return data.map((item) => IndexingStatus.fromJson(item as Map<String, dynamic>)).toList();
  }

  // ==================== Chunk (Segment) Operations ====================

  /// Add chunks to a document
  Future<List<DocumentChunk>> addChunks({
    required String datasetId,
    required String documentId,
    required List<Map<String, dynamic>> segments,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/documents/$documentId/segments');
    final headers = await _buildHeaders();
    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode({'segments': segments}),
        )
        .timeout(_timeout);

    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List;
    return data.map((item) => DocumentChunk.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Get chunks from a document
  Future<List<DocumentChunk>> getChunks({
    required String datasetId,
    required String documentId,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/documents/$documentId/segments');
    final headers = await _buildHeaders();
    final response = await _client
        .get(uri, headers: headers)
        .timeout(_timeout);

    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List;
    return data.map((item) => DocumentChunk.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Update a chunk
  Future<DocumentChunk> updateChunk({
    required String datasetId,
    required String documentId,
    required String segmentId,
    required Map<String, dynamic> segment,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/documents/$documentId/segments/$segmentId');
    final headers = await _buildHeaders();
    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode({'segment': segment}),
        )
        .timeout(_timeout);

    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List;
    return DocumentChunk.fromJson(data.first as Map<String, dynamic>);
  }

  /// Delete a chunk
  Future<void> deleteChunk({
    required String datasetId,
    required String documentId,
    required String segmentId,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/documents/$documentId/segments/$segmentId');
    final headers = await _buildHeaders();
    final response = await _client
        .delete(uri, headers: headers)
        .timeout(_timeout);

    _checkResponse(response);
  }

  // ==================== Metadata Operations ====================

  /// Add metadata field to knowledge base
  Future<MetadataField> addMetadataField({
    required String datasetId,
    required String type,
    required String name,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/metadata');
    final headers = await _buildHeaders();
    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'type': type,
            'name': name,
          }),
        )
        .timeout(_timeout);

    _checkResponse(response);
    return MetadataField.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Update metadata field
  Future<MetadataField> updateMetadataField({
    required String datasetId,
    required String metadataId,
    required String name,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/metadata/$metadataId');
    final headers = await _buildHeaders();
    final response = await _client
        .patch(
          uri,
          headers: headers,
          body: jsonEncode({'name': name}),
        )
        .timeout(_timeout);

    _checkResponse(response);
    return MetadataField.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Delete metadata field
  Future<void> deleteMetadataField({
    required String datasetId,
    required String metadataId,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/metadata/$metadataId');
    final headers = await _buildHeaders();
    final response = await _client
        .delete(uri, headers: headers)
        .timeout(_timeout);

    _checkResponse(response);
  }

  /// Enable/disable built-in metadata fields
  Future<void> toggleBuiltInFields({
    required String datasetId,
    required String action, // 'enable' or 'disable'
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/metadata/built-in/$action');
    final headers = await _buildHeaders();
    final response = await _client
        .delete(uri, headers: headers)
        .timeout(_timeout);

    _checkResponse(response);
  }

  /// Update document metadata
  Future<void> updateDocumentMetadata({
    required String datasetId,
    required List<Map<String, dynamic>> operationData,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/documents/metadata');
    final headers = await _buildHeaders();
    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode({'operation_data': operationData}),
        )
        .timeout(_timeout);

    _checkResponse(response);
  }

  /// Get metadata list
  Future<Map<String, dynamic>> listMetadata({
    required String datasetId,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/metadata');
    final headers = await _buildHeaders();
    final response = await _client
        .get(uri, headers: headers)
        .timeout(_timeout);

    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ==================== Retrieval Operations ====================

  /// Retrieve chunks from knowledge base
  Future<Map<String, dynamic>> retrieveChunks({
    required String datasetId,
    required String query,
    required Map<String, dynamic> retrievalModel,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/datasets/$datasetId/retrieve');
    final headers = await _buildHeaders();
    final response = await _client
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'query': query,
            'retrieval_model': retrievalModel,
          }),
        )
        .timeout(_timeout);

    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ==================== Helper Methods ====================

  Future<Map<String, String>> _buildHeaders({bool includeContentType = true}) async {
    final token = await tokenProvider();
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    try {
      final error = KnowledgeApiError.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      throw KnowledgeApiException(error);
    } catch (e) {
      if (e is KnowledgeApiException) rethrow;
      throw KnowledgeApiException(
        KnowledgeApiError(
          code: 'unknown_error',
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          status: response.statusCode,
        ),
      );
    }
  }

  void _setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTime[key] = DateTime.now();
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final time = _cacheTime[key];
    if (time == null) return false;
    return DateTime.now().difference(time) < _cacheDuration;
  }

  void dispose() {
    _client.close();
    _cache.clear();
    _cacheTime.clear();
  }
}

/// Exception for Knowledge API errors
class KnowledgeApiException implements Exception {
  final KnowledgeApiError error;

  KnowledgeApiException(this.error);

  @override
  String toString() => 'KnowledgeApiException: ${error.message} (${error.code})';
}
