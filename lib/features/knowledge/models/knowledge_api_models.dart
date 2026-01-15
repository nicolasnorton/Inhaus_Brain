/// Models for Knowledge Base API
library;

/// Knowledge document model
class KnowledgeDocument {
  final String id;
  final int position;
  final String dataSourceType;
  final Map<String, dynamic>? dataSourceInfo;
  final String? datasetProcessRuleId;
  final String name;
  final String createdFrom;
  final String createdBy;
  final int createdAt;
  final int tokens;
  final String indexingStatus;
  final String? error;
  final bool enabled;
  final int? disabledAt;
  final String? disabledBy;
  final bool archived;
  final String displayStatus;
  final int wordCount;
  final int hitCount;
  final String docForm;

  const KnowledgeDocument({
    required this.id,
    required this.position,
    required this.dataSourceType,
    this.dataSourceInfo,
    this.datasetProcessRuleId,
    required this.name,
    required this.createdFrom,
    required this.createdBy,
    required this.createdAt,
    required this.tokens,
    required this.indexingStatus,
    this.error,
    required this.enabled,
    this.disabledAt,
    this.disabledBy,
    required this.archived,
    required this.displayStatus,
    required this.wordCount,
    required this.hitCount,
    required this.docForm,
  });

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocument(
      id: json['id'] as String,
      position: json['position'] as int,
      dataSourceType: json['data_source_type'] as String,
      dataSourceInfo: json['data_source_info'] as Map<String, dynamic>?,
      datasetProcessRuleId: json['dataset_process_rule_id'] as String?,
      name: json['name'] as String,
      createdFrom: json['created_from'] as String,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] as int,
      tokens: json['tokens'] as int,
      indexingStatus: json['indexing_status'] as String,
      error: json['error'] as String?,
      enabled: json['enabled'] as bool,
      disabledAt: json['disabled_at'] as int?,
      disabledBy: json['disabled_by'] as String?,
      archived: json['archived'] as bool,
      displayStatus: json['display_status'] as String,
      wordCount: json['word_count'] as int,
      hitCount: json['hit_count'] as int,
      docForm: json['doc_form'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': position,
        'data_source_type': dataSourceType,
        if (dataSourceInfo != null) 'data_source_info': dataSourceInfo,
        if (datasetProcessRuleId != null) 'dataset_process_rule_id': datasetProcessRuleId,
        'name': name,
        'created_from': createdFrom,
        'created_by': createdBy,
        'created_at': createdAt,
        'tokens': tokens,
        'indexing_status': indexingStatus,
        if (error != null) 'error': error,
        'enabled': enabled,
        if (disabledAt != null) 'disabled_at': disabledAt,
        if (disabledBy != null) 'disabled_by': disabledBy,
        'archived': archived,
        'display_status': displayStatus,
        'word_count': wordCount,
        'hit_count': hitCount,
        'doc_form': docForm,
      };
}

/// Document chunk (segment) model
class DocumentChunk {
  final String id;
  final int position;
  final String documentId;
  final String content;
  final String? answer;
  final int wordCount;
  final int tokens;
  final List<String> keywords;
  final String indexNodeId;
  final String indexNodeHash;
  final int hitCount;
  final bool enabled;
  final int? disabledAt;
  final String? disabledBy;
  final String status;
  final String createdBy;
  final int createdAt;
  final int indexingAt;
  final int completedAt;
  final String? error;
  final int? stoppedAt;

  const DocumentChunk({
    required this.id,
    required this.position,
    required this.documentId,
    required this.content,
    this.answer,
    required this.wordCount,
    required this.tokens,
    required this.keywords,
    required this.indexNodeId,
    required this.indexNodeHash,
    required this.hitCount,
    required this.enabled,
    this.disabledAt,
    this.disabledBy,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.indexingAt,
    required this.completedAt,
    this.error,
    this.stoppedAt,
  });

  factory DocumentChunk.fromJson(Map<String, dynamic> json) {
    return DocumentChunk(
      id: json['id'] as String,
      position: json['position'] as int,
      documentId: json['document_id'] as String,
      content: json['content'] as String,
      answer: json['answer'] as String?,
      wordCount: json['word_count'] as int,
      tokens: json['tokens'] as int,
      keywords: (json['keywords'] as List).cast<String>(),
      indexNodeId: json['index_node_id'] as String,
      indexNodeHash: json['index_node_hash'] as String,
      hitCount: json['hit_count'] as int,
      enabled: json['enabled'] as bool,
      disabledAt: json['disabled_at'] as int?,
      disabledBy: json['disabled_by'] as String?,
      status: json['status'] as String,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] as int,
      indexingAt: json['indexing_at'] as int,
      completedAt: json['completed_at'] as int,
      error: json['error'] as String?,
      stoppedAt: json['stopped_at'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': position,
        'document_id': documentId,
        'content': content,
        if (answer != null) 'answer': answer,
        'word_count': wordCount,
        'tokens': tokens,
        'keywords': keywords,
        'index_node_id': indexNodeId,
        'index_node_hash': indexNodeHash,
        'hit_count': hitCount,
        'enabled': enabled,
        if (disabledAt != null) 'disabled_at': disabledAt,
        if (disabledBy != null) 'disabled_by': disabledBy,
        'status': status,
        'created_by': createdBy,
        'created_at': createdAt,
        'indexing_at': indexingAt,
        'completed_at': completedAt,
        if (error != null) 'error': error,
        if (stoppedAt != null) 'stopped_at': stoppedAt,
      };
}

/// Metadata field model
class MetadataField {
  final String id;
  final String type;
  final String name;
  final int? useCount;

  const MetadataField({
    required this.id,
    required this.type,
    required this.name,
    this.useCount,
  });

  factory MetadataField.fromJson(Map<String, dynamic> json) {
    return MetadataField(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      useCount: json['use_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        if (useCount != null) 'use_count': useCount,
      };
}

/// Indexing status model
class IndexingStatus {
  final String id;
  final String indexingStatus;
  final double? processingStartedAt;
  final double? parsingCompletedAt;
  final double? cleaningCompletedAt;
  final double? splittingCompletedAt;
  final double? completedAt;
  final double? pausedAt;
  final String? error;
  final double? stoppedAt;
  final int completedSegments;
  final int totalSegments;

  const IndexingStatus({
    required this.id,
    required this.indexingStatus,
    this.processingStartedAt,
    this.parsingCompletedAt,
    this.cleaningCompletedAt,
    this.splittingCompletedAt,
    this.completedAt,
    this.pausedAt,
    this.error,
    this.stoppedAt,
    required this.completedSegments,
    required this.totalSegments,
  });

  factory IndexingStatus.fromJson(Map<String, dynamic> json) {
    return IndexingStatus(
      id: json['id'] as String,
      indexingStatus: json['indexing_status'] as String,
      processingStartedAt: json['processing_started_at'] as double?,
      parsingCompletedAt: json['parsing_completed_at'] as double?,
      cleaningCompletedAt: json['cleaning_completed_at'] as double?,
      splittingCompletedAt: json['splitting_completed_at'] as double?,
      completedAt: json['completed_at'] as double?,
      pausedAt: json['paused_at'] as double?,
      error: json['error'] as String?,
      stoppedAt: json['stopped_at'] as double?,
      completedSegments: json['completed_segments'] as int,
      totalSegments: json['total_segments'] as int,
    );
  }
}

/// Knowledge base model
class KnowledgeBase {
  final String id;
  final String name;
  final String? description;
  final String provider;
  final String permission;
  final String? dataSourceType;
  final String? indexingTechnique;
  final int appCount;
  final int documentCount;
  final int wordCount;
  final String createdBy;
  final int createdAt;
  final String updatedBy;
  final int updatedAt;
  final String? embeddingModel;
  final String? embeddingModelProvider;
  final bool? embeddingAvailable;

  const KnowledgeBase({
    required this.id,
    required this.name,
    this.description,
    required this.provider,
    required this.permission,
    this.dataSourceType,
    this.indexingTechnique,
    required this.appCount,
    required this.documentCount,
    required this.wordCount,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
    this.embeddingModel,
    this.embeddingModelProvider,
    this.embeddingAvailable,
  });

  factory KnowledgeBase.fromJson(Map<String, dynamic> json) {
    return KnowledgeBase(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      provider: json['provider'] as String,
      permission: json['permission'] as String,
      dataSourceType: json['data_source_type'] as String?,
      indexingTechnique: json['indexing_technique'] as String?,
      appCount: json['app_count'] as int,
      documentCount: json['document_count'] as int,
      wordCount: json['word_count'] as int,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] as int,
      updatedBy: json['updated_by'] as String,
      updatedAt: json['updated_at'] as int,
      embeddingModel: json['embedding_model'] as String?,
      embeddingModelProvider: json['embedding_model_provider'] as String?,
      embeddingAvailable: json['embedding_available'] as bool?,
    );
  }
}

/// API error model
class KnowledgeApiError {
  final String code;
  final String message;
  final int status;

  const KnowledgeApiError({
    required this.code,
    required this.message,
    required this.status,
  });

  factory KnowledgeApiError.fromJson(Map<String, dynamic> json) {
    return KnowledgeApiError(
      code: json['code'] as String,
      message: json['message'] as String,
      status: json['status'] as int,
    );
  }
}
