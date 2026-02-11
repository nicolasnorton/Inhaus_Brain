import 'dart:convert';
// import 'dart:io'; // Removed for web compatibility
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // Kept for file upload if needed, or remove if unused
import 'package:inhaus_brain/workflows/sre_incident_workflow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart'; // Unused
import '../../../core/services/vertex_ai_service.dart';
import '../../../core/auth/secret_vault_service.dart';
import '../../../core/services/semantic_cache_service.dart';
import '../../../core/utils/security_utils.dart';
import '../../../core/utils/security_utils.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'; // PDF Parsing
import '../../../core/services/bigquery_service.dart';
import '../models/knowledge_api_models.dart';

/// Service for Knowledge Base operations (Native Vertex + Firestore)
class KnowledgeApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VertexApiService _vertexService;
  final SecretVaultService _vault;
  final BigQueryService? _bq;
  final SemanticCacheService? _cache;
  final String? _userId;
  final Future<String?> Function() tokenProvider; // Kept for interface compatibility, though Firestore handles auth natively

  KnowledgeApiService({
    required VertexApiService vertexService,
    required SecretVaultService vault,
    required this.tokenProvider,
    BigQueryService? bq,
    String? userId,
    SemanticCacheService? cache,
    String? baseUrl, // Deprecated, kept for signature compatibility
    http.Client? client,
  }) : _vertexService = vertexService, _vault = vault, _bq = bq, _cache = cache, _userId = userId;

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
      createdBy: _userId ?? 'system', 
      createdAt: now,
      updatedBy: _userId ?? 'system',
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

  Future<void> _deleteCollection(CollectionReference collection) async {
    final snapshots = await collection.get();
    final batch = _firestore.batch();
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Delete a knowledge base
  Future<void> deleteKnowledgeBase(String datasetId) async {
    final datasetRef = _firestore.collection(_collectionDatasets).doc(datasetId);
    
    // 1. Delete all documents in this dataset
    final docsSnapshot = await datasetRef.collection(_collectionDocuments).get();
    final batch = _firestore.batch();
    for (final doc in docsSnapshot.docs) {
      // Note: This won't delete chunks subcollections deeper down.
      // Recursive delete is best done in Cloud Functions.
      batch.delete(doc.reference);
    }
    
    // 2. Delete the dataset itself
    batch.delete(datasetRef);
    await batch.commit();
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
      // ON WEB: We prefer the Proxy which handles its own auth via Firebase ID Tokens.
      
      if (kIsWeb) {
        debugPrint('KnowledgeApi: [WEB] Delegating embedding generation to VertexApiService (Proxy path).');
        embeddings = await _vertexService.getEmbeddings(chunks);
      } else {
        // Attempt 1: Vertex Token (Native/Desktop)
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
              debugPrint('KnowledgeApi: Vertex Embedding 401. Fallback to Gemini Key...');
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
              // Do NOT rethrow, just log and continue with empty embeddings to avoid crashing the whole pipeline
              debugPrint('KnowledgeApi: ⚠️ CRITICAL - No AI keys found for embeddings. Chunks will be stored without vector data.');
           }
        }
      }
    } catch (e) {
      final err = _safeError(e);
      debugPrint('Embedding generation failed (handled): $err');
      // Continue without embeddings
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

      // Add Vector Field (native Firestore vector support requires upgrade)
      // if (i < embeddings.length) {
      //   chunkData['embedding_vector'] = FieldValue.vector(embeddings[i]); 
      // }

      batch.set(chunkRef, chunkData);
    }

    // 5. Save Document Metadata
    final doc = KnowledgeDocument(
      id: docId,
      position: 1,
      dataSourceType: 'text',
      name: name,
      createdFrom: 'api',
      createdBy: _userId ?? 'system',
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

    // 6. [NEW] Production Scale Storage: BigQuery Ingestion
    if (_bq != null) {
      try {
        debugPrint('KnowledgeApi: [DUAL-WRITE] Ingesting to BigQuery for production-grade retrieval...');
        await _bq.ingestDocument(
          documentId: docId,
          clientId: datasetId, // Assuming datasetId is the client isolation key or similar for now
          platform: 'file_upload', // Default for text/file, will be specific in connectors
          type: 'text_document',
          title: name,
          content: text,
          embeddings: embeddings,
          metadata: {
            'word_count': wordCount,
            'token_count': totalTokens,
            'original_id': docId,
          }
        );
      } catch (e) {
        debugPrint('KnowledgeApi: ⚠️ BigQuery Dual-Write failed: $e. System continuing with Firestore fallback.');
        // Non-blocking for now
      }
    }

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
    // 1. Delete all chunks in this document
    final chunksSnapshot = await docRef.collection(_collectionChunks).get();
    final batch = _firestore.batch();
    for (final chunk in chunksSnapshot.docs) {
      batch.delete(chunk.reference);
    }
    
    // 2. Delete the document itself
    batch.delete(docRef);
    await batch.commit();
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

      // Vector Search Implementation (Firestore Native)
      try {
        // 1. Generate Embedding for Query
        List<List<double>> queryEmbeddings = [];
        
        if (kIsWeb) {
          debugPrint('KnowledgeApi: [WEB-RETRIEVE] Delegating query embedding to VertexApiService (Proxy path).');
          queryEmbeddings = await _vertexService.getEmbeddings([query]);
        } else {
          String? apiKey = await _vault.getVertexKey();
          bool isVertex = true;
          
          // Check local token provider first (often has fresh OAuth)
          if (apiKey == null) {
              apiKey = await tokenProvider();
               if (apiKey != null && (apiKey.startsWith('ya29.') || apiKey.startsWith('AQ.'))) {
                 // Good info
               } else {
                 apiKey = null;
               }
          }

          if (apiKey == null) {
              apiKey = await _vault.getGeminiKey();
              isVertex = false;
          }
          
          if (apiKey != null) {
             queryEmbeddings = await _vertexService.getEmbeddings(
                [query], 
                accessToken: isVertex && !apiKey.startsWith('AQ.') ? apiKey : null,
                apiKey: (!isVertex || apiKey.startsWith('AQ.')) ? apiKey : null
             );
          }
        }
        
        if (queryEmbeddings.isNotEmpty) {
           final queryVector = queryEmbeddings.first;
              
               // 2. Query Firestore Vector Search
               debugPrint('KnowledgeApi: Performing Firestore Vector Search for "$query"...');
               
               // TODO: Upgrade cloud_firestore to support native Vector Search
               /*
               final collection = _firestore.collectionGroup(_collectionChunks);
               
               // Note: This requires a Vector Index on 'embedding_vector' in chunks collection group
               final querySnapshot = await collection.findNearest(
                  vectorField: 'embedding_vector',
                  queryVector: queryVector,
                  limit: 5,
                  distanceMeasure: DistanceMeasure.cosine,
               ).get();

              final records = querySnapshot.docs.map((doc) {
                  final data = doc.data();
                  // We need to fetch the document metadata or at least return what we have
                  // The chunk contains 'content' directly.
                  return {
                     'score': 0.0, // Firestore doesn't return score in client SDK yet easily, or needs different handling
                     'segment': {
                        'content': data['content'] ?? '',
                        'document_id': data['document_id'],
                     }
                  };
               }).toList();
               
               final result = {'records': records};
               
               if (_cache != null && records.isNotEmpty) { 
                  await _cache.store('knowledge_retrieval', cacheKey, jsonEncode(result));
               }
               
               return result;
               */
           }

     } catch (e) {
        debugPrint('Vector Search Failed: $e');
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
