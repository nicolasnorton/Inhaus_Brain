import 'dart:convert';
// import 'dart:io'; // Removed for web compatibility
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // Kept for file upload if needed, or remove if unused
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart'; // Unused
import '../../../core/services/vertex_ai_service.dart';
import '../../../core/auth/secret_vault_service.dart';
import '../../../core/services/semantic_cache_service.dart';
import '../../../core/utils/security_utils.dart';
import '../../../core/services/pinecone_service.dart'; // Pinecone integration
import 'package:syncfusion_flutter_pdf/pdf.dart'; // PDF Parsing
import '../models/knowledge_api_models.dart';

/// Service for Knowledge Base operations (Native Vertex + Firestore)
class KnowledgeApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VertexApiService _vertexService;
  final SecretVaultService _vault;
  final SemanticCacheService? _cache;
  final PineconeService? _pineconeService; // Added Pinecone
  final Future<String?> Function() tokenProvider; // Kept for interface compatibility, though Firestore handles auth natively

  KnowledgeApiService({
    required VertexApiService vertexService,
    required SecretVaultService vault,
    required this.tokenProvider,
    SemanticCacheService? cache,
    PineconeService? pineconeService, // Added
    String? baseUrl, // Deprecated, kept for signature compatibility
    http.Client? client,
  }) : _vertexService = vertexService, _vault = vault, _cache = cache, _pineconeService = pineconeService;

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

    return snapshot.docs.map((doc) {
      try {
        return KnowledgeBase.fromJson(doc.data());
      } catch (e) {
        debugPrint('KnowledgeApi: Failed to parse KB ${doc.id}: ${_safeError(e)}');
        // Return a mock/safe KB if parsing fails to avoid crashing the whole list
        return KnowledgeBase(
          id: doc.id,
          name: 'Corrupted Knowledge Base',
          provider: 'unknown',
          permission: 'only_me',
          appCount: 0,
          documentCount: 0,
          wordCount: 0,
          createdBy: 'system',
          createdAt: 0,
          updatedBy: 'system',
          updatedAt: 0,
        );
      }
    }).toList();
  }

  /// Delete a knowledge base
  Future<void> deleteKnowledgeBase(String datasetId) async {
    await _firestore.collection(_collectionDatasets).doc(datasetId).delete();
    // Note: Subcollections (documents) are not auto-deleted in Firestore. 
    // In a production app, use a Cloud Function to recursive delete.
  }

  // ==================== Document Operations ====================


// Top-level function for Isolate
Map<String, dynamic> _processTextInIsolate(Map<String, dynamic> args) {
  final text = args['text'] as String;
  final chunkSize = args['chunkSize'] as int;
  final scrub = args['scrub'] as bool;
  
  // 1. Scrub PII (if enabled)
  final processedText = scrub ? SecurityUtils.scrubPII(text) : text;
  
  // 2. Split Text
  if (processedText.isEmpty) {
     return {'chunks': <String>[], 'wordCount': 0, 'tokenCount': 0};
  }
  
  List<String> chunks = [];
  for (int i = 0; i < processedText.length; i += chunkSize) {
    int end = (i + chunkSize < processedText.length) ? i + chunkSize : processedText.length;
    chunks.add(processedText.substring(i, end));
  }
  
  return {
    'chunks': chunks,
    'wordCount': processedText.split(RegExp(r'\s+')).length,
    'tokenCount': (processedText.length / 4).ceil(),
  };
}

  /// Create a document from text (Ingestion Pipeline)
  Future<KnowledgeDocument> createDocumentFromText({
    required String datasetId,
    required String name,
    required String text,
    int chunkSize = 500,
    String indexingTechnique = 'high_quality',
    Map<String, dynamic>? processRule,
    bool scrubPII = true, 
  }) async {
    // Run CPU-intensive string processing in an Isolate to prevent UI jank
    final result = await compute(_processTextInIsolate, {
      'text': text,
      'chunkSize': chunkSize,
      'scrub': scrubPII,
    });
    
    final chunks = result['chunks'] as List<String>;
    final wordCount = result['wordCount'] as int;
    final totalTokens = result['tokenCount'] as int;

    // 1. Create Document Record
    final docRef = _firestore
        .collection(_collectionDatasets)
        .doc(datasetId)
        .collection(_collectionDocuments)
        .doc();
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final docId = docRef.id;

       // 3. Embeddings via Vertex AI
    List<List<double>> embeddings = [];
    try {
      // Strategy: Try Vertex (OAuth) first, then fallback to Gemini Key (API Key)
      
      // Attempt 1: Vertex Token
      String? vertexKey = await _vault.getVertexKey();
      
      // If no vertex key in vault, fall back to our token provider which might have one
      if (vertexKey == null) {
          final t = await tokenProvider();
          if (t != null && (t.startsWith('ya29.') || t.startsWith('AQ.'))) {
             vertexKey = t;
          }
      }
      
      try {
         if (vertexKey != null) {
            // Check if it's an API Key (AQ.) or OAuth Token (ya29.)
            final isApiKey = vertexKey.startsWith('AQ.');
            
            embeddings = await _vertexService.getEmbeddings(
              chunks, 
              accessToken: isApiKey ? null : vertexKey,
              apiKey: isApiKey ? vertexKey : null,
            );
         } else {
           throw Exception('No Vertex Token available for initial attempt');
         }
      } catch (e) {
         final errStr = _safeError(e);
         
         if (errStr.contains('401') || errStr.contains('UNAUTHENTICATED')) {
            debugPrint('KnowledgeApi: Vertex Embedding 401 (Expected with API Key). Fallback to Gemini Key...');
         } else {
            debugPrint('KnowledgeApi: Vertex Embedding failed ($errStr). Attempting fallback to Gemini Key...');
         }
         
         // Attempt 2: Gemini API Key
         final geminiKey = await _vault.getGeminiKey();
         if (geminiKey != null && geminiKey.isNotEmpty) {
            embeddings = await _vertexService.getEmbeddings(
              chunks, 
              apiKey: geminiKey,
            );
         } else {
            // Rethrow original error if no fallback
            throw Exception('Vertex Failed and no Gemini Key found: $errStr');
         }
      }
    } catch (e) {
      final err = _safeError(e);
      debugPrint('Embedding generation failed: $err');
      // For MVP, we might fail or store empty. Let's fail to warn user.
      throw Exception('Failed to generate embeddings: $err');
    }

    // 4. Store Chunks with Vectors
    final batch = _firestore.batch();
    List<Map<String, dynamic>> pineconeVectors = [];

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
        chunkData['embedding_vector'] = embeddings[i]; // Vector field for Firestore backup
        
        // Prepare for Pinecone
        pineconeVectors.add({
          'id': chunkRef.id,
          'values': embeddings[i],
          'metadata': {
            'text': chunks[i],
            'document_id': docId,
            'dataset_id': datasetId,
            'source_name': name,
          }
        });
      }

      batch.set(chunkRef, chunkData);
    }
    
    // Upsert to Pinecone
    if (_pineconeService != null && pineconeVectors.isNotEmpty) {
       try {
         await _pineconeService!.upsertVectors(vectors: pineconeVectors, namespace: datasetId);
       } catch (e) {
         debugPrint('Pinecone Upsert Failed: $e');
         // We don't fail the whole process, but we warn
       }
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
      wordCount: wordCount,
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
    dynamic file,
    List<int>? bytes,
    String? filename,
    String indexingTechnique = 'high_quality',
    Map<String, dynamic>? processRule,
  }) async {
    String textContent = "File content placeholder for ${filename ?? 'file'}";
    if (bytes != null) {
      // 1. Try PDF Extraction
      try {
         if (filename != null && filename.toLowerCase().endsWith('.pdf')) {
            final PdfDocument document = PdfDocument(inputBytes: bytes);
            textContent = PdfTextExtractor(document).extractText();
            document.dispose();
         } else {
            // 2. Try UTF8 decode for text files
            textContent = utf8.decode(bytes, allowMalformed: true);
         }
      } catch (e) {
         debugPrint('Detailed text extraction failed: $e');
         // Fallback to basic decode
         try {
           textContent = utf8.decode(bytes, allowMalformed: true);
         } catch (_) {}
      }
    }
    
    return createDocumentFromText(
      datasetId: datasetId, 
      name: filename ?? 'Uploaded File', 
      text: textContent
    );
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
    dynamic file,
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
  Future<Map<String, dynamic>> retrieveChunks({
    required String datasetId,
    required String query,
    required Map<String, dynamic> retrievalModel,
  }) async {
     final cacheKey = 'retrieve:$datasetId:$query:${jsonEncode(retrievalModel)}';
     
     if (_cache != null) {
       final cachedResponse = await _cache.lookup('knowledge_retrieval', cacheKey);
       if (cachedResponse != null) {
         try {
           return jsonDecode(cachedResponse) as Map<String, dynamic>;
         } catch (_) {}
       }
     }

     // Vector Search Implementation
     if (_pineconeService != null) {
        try {
           // 1. Generate Embedding for Query
           // We reuse the createDocument logic or explicit embedding call. 
           // Since getEmbeddings is on VertexService, we use that.
           
           // Lookup Vertex/Gemini Key again (duplicated logic from create - ideally refactor to helper)
           String? apiKey = await _vault.getVertexKey();
           bool isVertex = true;
           if (apiKey == null) {
              apiKey = await _vault.getGeminiKey();
              isVertex = false;
           }
           
           if (apiKey != null) {
              final embeddings = await _vertexService.getEmbeddings(
                 [query], 
                 accessToken: isVertex && !apiKey.startsWith('AQ.') ? apiKey : null,
                 apiKey: (!isVertex || apiKey.startsWith('AQ.')) ? apiKey : null
              );
              
              if (embeddings.isNotEmpty) {
                 final queryVector = embeddings.first;
                 
                 // 2. Query Pinecone
                 final matches = await _pineconeService!.queryVectors(
                    vector: queryVector,
                    namespace: datasetId,
                    topK: 5,
                    includeMetadata: true,
                 );
                 
                 final result = {
                    'records': matches.map((m) => {
                       'score': m['score'],
                       'segment': {
                          'content': m['metadata']['text'] ?? '',
                          'document_id': m['metadata']['document_id'],
                       }
                    }).toList()
                 };
                 
                 if (_cache != null && apiKey.isNotEmpty) { // Only cache if we succeeded
                    await _cache.store('knowledge_retrieval', cacheKey, jsonEncode(result));
                 }
                 
                 return result;
              }
           }
        } catch (e) {
           debugPrint('Vector Search Failed: $e');
        }
     }

     // TODO: Implement actual Vector Search here
     final result = {'records': []};
     
     if (_cache != null) {
       await _cache.store('knowledge_retrieval', cacheKey, jsonEncode(result));
     }
     
     return result;
  }

  void dispose() {}

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

/// Exception for Knowledge API errors
class KnowledgeApiException implements Exception {
  final KnowledgeApiError error;

  KnowledgeApiException(this.error);

  @override
  String toString() {
    return 'KnowledgeApiException: ${error.message} (${error.code})';
  }
}
