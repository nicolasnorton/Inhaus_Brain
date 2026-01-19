import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // Kept for file upload if needed, or remove if unused
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/vertex_ai_service.dart';
import '../models/knowledge_api_models.dart';

/// Service for Knowledge Base operations (Native Vertex + Firestore)
class KnowledgeApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VertexApiService _vertexService;
  final Future<String?> Function() tokenProvider; // Kept for interface compatibility, though Firestore handles auth natively

  KnowledgeApiService({
    required VertexApiService vertexService,
    required this.tokenProvider,
    String? baseUrl, // Deprecated, kept for signature compatibility
    http.Client? client,
  }) : _vertexService = vertexService;

  static const String _collectionDatasets = 'knowledge_datasets';
  static const String _collectionDocuments = 'documents';
  static const String _collectionChunks = 'chunks';

  // ==================== Knowledge Base Operations ====================

  /// Create an empty knowledge base (Dataset)
  Future<KnowledgeBase> createKnowledgeBase({
    required String name,
    String? description,
    String permission = 'only_me',
  }) async {
    final docRef = _firestore.collection(_collectionDatasets).doc();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final kb = KnowledgeBase(
      id: docRef.id,
      name: name,
      description: description,
      provider: 'vertex_ai',
      permission: permission,
      dataSourceType: 'native',
      indexingTechnique: 'high_quality',
      appCount: 0,
      documentCount: 0,
      wordCount: 0,
      createdBy: 'user', // In real app, get from Auth
      createdAt: now,
      updatedBy: 'user',
      updatedAt: now,
      embeddingModel: 'text-embedding-004',
      embeddingModelProvider: 'google',
      embeddingAvailable: true,
    );

    // Convert to JSON but remove fields that might be null if not handled by toJson properly or strict
    // leveraging the model's toJson should be fine.
    await docRef.set(kb.toJson());
    return kb;
  }

  /// Get list of knowledge bases
  Future<List<KnowledgeBase>> listKnowledgeBases({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    // Basic implementation: retrieve all (pagination in Firestore requires cursors)
    final snapshot = await _firestore
        .collection(_collectionDatasets)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => KnowledgeBase.fromJson(doc.data())).toList();
  }

  /// Delete a knowledge base
  Future<void> deleteKnowledgeBase(String datasetId) async {
    await _firestore.collection(_collectionDatasets).doc(datasetId).delete();
    // Note: Subcollections (documents) are not auto-deleted in Firestore. 
    // In a production app, use a Cloud Function to recursive delete.
  }

  // ==================== Document Operations ====================

  /// Create a document from text (Ingestion Pipeline)
  Future<KnowledgeDocument> createDocumentFromText({
    required String datasetId,
    required String name,
    required String text,
    String indexingTechnique = 'high_quality',
    Map<String, dynamic>? processRule,
  }) async {
    // 1. Create Document Record
    final docRef = _firestore
        .collection(_collectionDatasets)
        .doc(datasetId)
        .collection(_collectionDocuments)
        .doc();
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final docId = docRef.id;

    // 2. Chunking (Simple Splitter for MVP)
    final chunks = _splitText(text, 500); // ~500 chars per chunk
    int totalTokens = text.split(' ').length; // Rough estimate

    // 3. Embeddings via Vertex AI
    List<List<double>> embeddings = [];
    try {
      // Get auth token (API Key or Bearer)
      final token = await tokenProvider();
      
      // Determine if it's an API Key or Access Token
      String? apiKey;
      String? accessToken;
      if (token != null && !token.startsWith('ya29.')) {
        apiKey = token;
      } else {
        accessToken = token;
      }
      
      embeddings = await _vertexService.getEmbeddings(
        chunks, 
        apiKey: apiKey,
        accessToken: accessToken,
      );
    } catch (e) {
      debugPrint('Embedding generation failed: $e');
      // Continue without embeddings? Or fail? 
      // For MVP, we might fail or store empty. Let's fail to warn user.
      throw Exception('Failed to generate embeddings: $e');
    }

    // 4. Store Chunks with Vectors
    final batch = _firestore.batch();
    for (int i = 0; i < chunks.length; i++) {
      final chunkRef = docRef.collection(_collectionChunks).doc();
      final chunkData = DocumentChunk(
        id: chunkRef.id,
        position: i + 1,
        documentId: docId,
        content: chunks[i],
        wordCount: chunks[i].split(' ').length,
        tokens: (chunks[i].length / 4).ceil(), // rough est
        keywords: [],
        indexNodeId: '',
        indexNodeHash: '',
        hitCount: 0,
        enabled: true,
        status: 'completed',
        createdBy: 'system',
        createdAt: now,
        indexingAt: now,
        completedAt: now,
      ).toJson();

      // Add Vector Field (native Firestore vector support requires specific format, usually List<double>)
      if (i < embeddings.length) {
        chunkData['embedding_vector'] = embeddings[i]; // Vector field
      }

      batch.set(chunkRef, chunkData);
    }

    // 5. Save Document Metadata
    final doc = KnowledgeDocument(
      id: docId,
      position: 1,
      dataSourceType: 'text',
      name: name,
      createdFrom: 'api',
      createdBy: 'user',
      createdAt: now,
      tokens: totalTokens,
      indexingStatus: 'completed',
      enabled: true,
      archived: false,
      displayStatus: 'normal',
      wordCount: text.split(' ').length,
      hitCount: 0,
      docForm: 'text_model',
    );
    
    batch.set(docRef, doc.toJson());
    await batch.commit();

    return doc;
  }

  /// Create a document from file (Mock parsing for now)
  Future<KnowledgeDocument> createDocumentFromFile({
    required String datasetId,
    File? file,
    List<int>? bytes,
    String? filename,
    String indexingTechnique = 'high_quality',
    Map<String, dynamic>? processRule,
  }) async {
    String textContent = "File content placeholder for ${filename ?? 'file'}";
    if (bytes != null) {
      // Try to decode utf8 if text file
      try {
        textContent = utf8.decode(bytes, allowMalformed: true);
      } catch (_) {}
    }
    
    return createDocumentFromText(
      datasetId: datasetId, 
      name: filename ?? 'Uploaded File', 
      text: textContent
    );
  }

  // --- Helpers ---
  List<String> _splitText(String text, int chunkSize) {
    if (text.isEmpty) return [];
    List<String> chunks = [];
    for (int i = 0; i < text.length; i += chunkSize) {
      int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      chunks.add(text.substring(i, end));
    }
    return chunks;
  }

  /// Update a document with text (Re-index)
  Future<KnowledgeDocument> updateDocumentWithText({
    required String datasetId,
    required String documentId,
    required String name,
    required String text,
  }) async {
    // For MVP transparency: Delete and Re-create logic or similar
    await deleteDocument(datasetId: datasetId, documentId: documentId);
    return createDocumentFromText(datasetId: datasetId, name: name, text: text);
  }
  
  // Stubs for other methods to match interface, can function similarly
  
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
      await deleteDocument(datasetId: datasetId, documentId: documentId);
      return createDocumentFromFile(
        datasetId: datasetId, 
        file: file, 
        bytes: bytes, 
        filename: filename ?? name,
      );
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String datasetId,
    required String documentId,
  }) async {
    final docRef = _firestore
        .collection(_collectionDatasets)
        .doc(datasetId)
        .collection(_collectionDocuments)
        .doc(documentId);
        
    await docRef.delete();
    // In production, delete chunks subcollection too
  }

  /// Get list of documents in a knowledge base
  Future<List<KnowledgeDocument>> listDocuments({
    required String datasetId,
    int page = 1,
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection(_collectionDatasets)
        .doc(datasetId)
        .collection(_collectionDocuments)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => KnowledgeDocument.fromJson(doc.data())).toList();
  }

  /// Get document indexing status (Mock for Firestore)
  Future<List<IndexingStatus>> getIndexingStatus({
    required String datasetId,
    required String batch,
  }) async {
    // Return empty or mock status as we don't have a separate indexing status collection yet
    return []; 
  }

  // ==================== Chunk (Segment) Operations ====================

  /// Add chunks to a document
  Future<List<DocumentChunk>> addChunks({
    required String datasetId,
    required String documentId,
    required List<Map<String, dynamic>> segments,
  }) async {
     // Not heavily used in manual create, usually internal.
     return [];
  }

  /// Get chunks from a document
  Future<List<DocumentChunk>> getChunks({
    required String datasetId,
    required String documentId,
  }) async {
    final snapshot = await _firestore
        .collection(_collectionDatasets)
        .doc(datasetId)
        .collection(_collectionDocuments)
        .doc(documentId)
        .collection(_collectionChunks)
        .orderBy('position')
        .get();

    return snapshot.docs.map((doc) => DocumentChunk.fromJson(doc.data())).toList();
  }

  /// Update a chunk
  Future<DocumentChunk> updateChunk({
    required String datasetId,
    required String documentId,
    required String segmentId,
    required Map<String, dynamic> segment,
  }) async {
     // Stub
    throw UnimplementedError();
  }

  /// Delete a chunk
  Future<void> deleteChunk({
    required String datasetId,
    required String documentId,
    required String segmentId,
  }) async {
     final ref = _firestore
        .collection(_collectionDatasets)
        .doc(datasetId)
        .collection(_collectionDocuments)
        .doc(documentId)
        .collection(_collectionChunks)
        .doc(segmentId);
     await ref.delete();
  }

  // ==================== Metadata Operations ====================
  // Stubs to satisfy interface if called, or throw Unimplemented
  
  Future<MetadataField> addMetadataField({
    required String datasetId,
    required String type,
    required String name,
  }) async {
      throw UnimplementedError('Metadata operations not supported in native mode yet.');
  }

  Future<MetadataField> updateMetadataField({
    required String datasetId,
    required String metadataId,
    required String name,
  }) async => throw UnimplementedError();

  Future<void> deleteMetadataField({
    required String datasetId,
    required String metadataId,
  }) async => throw UnimplementedError();

  Future<void> toggleBuiltInFields({
    required String datasetId,
    required String action,
  }) async {} // No-op

  Future<void> updateDocumentMetadata({
    required String datasetId,
    required List<Map<String, dynamic>> operationData,
  }) async {} // No-op

  Future<Map<String, dynamic>> listMetadata({
    required String datasetId,
  }) async => {};

  // ==================== Retrieval Operations ====================
  // This would ideally do Vector Search using Firestore Vector Search
  Future<Map<String, dynamic>> retrieveChunks({
    required String datasetId,
    required String query,
    required Map<String, dynamic> retrievalModel,
  }) async {
     // TODO: Implement actual Vector Search here
     return {'records': []};
  }

  void dispose() {}
}

/// Exception for Knowledge API errors
class KnowledgeApiException implements Exception {
  final KnowledgeApiError error;

  KnowledgeApiException(this.error);

  @override
  String toString() => 'KnowledgeApiException: ${error.message} (${error.code})';
}
