/// Models for integrating knowledge bases within applications

/// Metadata filter mode
enum MetadataFilterMode {
  disabled,
  automatic,
  manual;

  String get displayName {
    switch (this) {
      case MetadataFilterMode.disabled:
        return 'Disabled';
      case MetadataFilterMode.automatic:
        return 'Automatic';
      case MetadataFilterMode.manual:
        return 'Manual';
    }
  }
}

/// Metadata filter operator for different field types
enum MetadataOperator {
  // String operators
  is_,
  isNot,
  isEmpty,
  isNotEmpty,
  contains,
  notContains,
  startsWith,
  endsWith,
  
  // Number operators
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  
  // Date operators
  before,
  after;

  String get apiValue {
    switch (this) {
      case MetadataOperator.is_:
        return 'is';
      case MetadataOperator.isNot:
        return 'is not';
      case MetadataOperator.isEmpty:
        return 'is empty';
      case MetadataOperator.isNotEmpty:
        return 'is not empty';
      case MetadataOperator.contains:
        return 'contains';
      case MetadataOperator.notContains:
        return 'not contains';
      case MetadataOperator.startsWith:
        return 'starts with';
      case MetadataOperator.endsWith:
        return 'ends with';
      case MetadataOperator.equals:
        return '=';
      case MetadataOperator.notEquals:
        return '≠';
      case MetadataOperator.greaterThan:
        return '>';
      case MetadataOperator.lessThan:
        return '<';
      case MetadataOperator.greaterThanOrEqual:
        return '≥';
      case MetadataOperator.lessThanOrEqual:
        return '≤';
      case MetadataOperator.before:
        return 'before';
      case MetadataOperator.after:
        return 'after';
    }
  }

  /// Get operators for string fields
  static List<MetadataOperator> get stringOperators => [
        MetadataOperator.is_,
        MetadataOperator.isNot,
        MetadataOperator.isEmpty,
        MetadataOperator.isNotEmpty,
        MetadataOperator.contains,
        MetadataOperator.notContains,
        MetadataOperator.startsWith,
        MetadataOperator.endsWith,
      ];

  /// Get operators for number fields
  static List<MetadataOperator> get numberOperators => [
        MetadataOperator.equals,
        MetadataOperator.notEquals,
        MetadataOperator.greaterThan,
        MetadataOperator.lessThan,
        MetadataOperator.greaterThanOrEqual,
        MetadataOperator.lessThanOrEqual,
        MetadataOperator.isEmpty,
        MetadataOperator.isNotEmpty,
      ];

  /// Get operators for date fields
  static List<MetadataOperator> get dateOperators => [
        MetadataOperator.is_,
        MetadataOperator.before,
        MetadataOperator.after,
        MetadataOperator.isEmpty,
        MetadataOperator.isNotEmpty,
      ];
}

/// Metadata filter condition
class MetadataConditionFilter {
  final String fieldId;
  final String fieldName;
  final String fieldType; // 'string', 'number', 'time'
  final MetadataOperator operator;
  final dynamic value; // Can be variable reference or constant

  const MetadataConditionFilter({
    required this.fieldId,
    required this.fieldName,
    required this.fieldType,
    required this.operator,
    this.value,
  });

  Map<String, dynamic> toJson() => {
        'field_id': fieldId,
        'field_name': fieldName,
        'field_type': fieldType,
        'operator': operator.apiValue,
        if (value != null) 'value': value,
      };

  factory MetadataConditionFilter.fromJson(Map<String, dynamic> json) {
    return MetadataConditionFilter(
      fieldId: json['field_id'] as String,
      fieldName: json['field_name'] as String,
      fieldType: json['field_type'] as String,
      operator: MetadataOperator.values.firstWhere(
        (e) => e.apiValue == json['operator'],
      ),
      value: json['value'],
    );
  }
}

/// Metadata filter configuration
class MetadataFilterConfig {
  final MetadataFilterMode mode;
  final String logicOperator; // 'AND' or 'OR'
  final List<MetadataConditionFilter> conditions;

  const MetadataFilterConfig({
    required this.mode,
    this.logicOperator = 'AND',
    this.conditions = const [],
  });

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'logic_operator': logicOperator,
        'conditions': conditions.map((c) => c.toJson()).toList(),
      };

  factory MetadataFilterConfig.fromJson(Map<String, dynamic> json) {
    return MetadataFilterConfig(
      mode: MetadataFilterMode.values.byName(json['mode'] as String),
      logicOperator: json['logic_operator'] as String? ?? 'AND',
      conditions: (json['conditions'] as List?)
              ?.map((c) => MetadataConditionFilter.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Create disabled filter
  factory MetadataFilterConfig.disabled() {
    return const MetadataFilterConfig(mode: MetadataFilterMode.disabled);
  }

  /// Create automatic filter
  factory MetadataFilterConfig.automatic() {
    return const MetadataFilterConfig(mode: MetadataFilterMode.automatic);
  }

  /// Create manual filter
  factory MetadataFilterConfig.manual({
    required List<MetadataConditionFilter> conditions,
    String logicOperator = 'AND',
  }) {
    return MetadataFilterConfig(
      mode: MetadataFilterMode.manual,
      conditions: conditions,
      logicOperator: logicOperator,
    );
  }
}

/// Multi-path retrieval rerank strategy
enum RerankStrategy {
  weightedScore,
  rerankModel;

  String get displayName {
    switch (this) {
      case RerankStrategy.weightedScore:
        return 'Weighted Score';
      case RerankStrategy.rerankModel:
        return 'Rerank Model';
    }
  }

  String get description {
    switch (this) {
      case RerankStrategy.weightedScore:
        return 'Uses internal scoring mechanisms without external Rerank model, avoiding additional costs.';
      case RerankStrategy.rerankModel:
        return 'External scoring system that calculates relevance score between user question and candidate documents.';
    }
  }
}

/// Multi-path retrieval configuration
class MultiPathRetrievalConfig {
  final RerankStrategy strategy;
  final double? semanticWeight; // For weighted score (0.0 to 1.0)
  final double? keywordWeight; // For weighted score (0.0 to 1.0)
  final RerankingModel? rerankModel; // For rerank model strategy
  final int topK;
  final bool scoreThresholdEnabled;
  final double? scoreThreshold;

  const MultiPathRetrievalConfig({
    required this.strategy,
    this.semanticWeight,
    this.keywordWeight,
    this.rerankModel,
    this.topK = 4,
    this.scoreThresholdEnabled = false,
    this.scoreThreshold,
  });

  Map<String, dynamic> toJson() => {
        'strategy': strategy.name,
        if (semanticWeight != null) 'semantic_weight': semanticWeight,
        if (keywordWeight != null) 'keyword_weight': keywordWeight,
        if (rerankModel != null) 'rerank_model': rerankModel!.toJson(),
        'top_k': topK,
        'score_threshold_enabled': scoreThresholdEnabled,
        if (scoreThreshold != null) 'score_threshold': scoreThreshold,
      };

  factory MultiPathRetrievalConfig.fromJson(Map<String, dynamic> json) {
    return MultiPathRetrievalConfig(
      strategy: RerankStrategy.values.byName(json['strategy'] as String),
      semanticWeight: json['semantic_weight'] as double?,
      keywordWeight: json['keyword_weight'] as double?,
      rerankModel: json['rerank_model'] != null
          ? RerankingModel.fromJson(json['rerank_model'] as Map<String, dynamic>)
          : null,
      topK: json['top_k'] as int? ?? 4,
      scoreThresholdEnabled: json['score_threshold_enabled'] as bool? ?? false,
      scoreThreshold: json['score_threshold'] as double?,
    );
  }

  /// Create weighted score configuration
  factory MultiPathRetrievalConfig.weightedScore({
    double semanticWeight = 0.5,
    double keywordWeight = 0.5,
    int topK = 4,
  }) {
    return MultiPathRetrievalConfig(
      strategy: RerankStrategy.weightedScore,
      semanticWeight: semanticWeight,
      keywordWeight: keywordWeight,
      topK: topK,
    );
  }

  /// Create semantic-only configuration
  factory MultiPathRetrievalConfig.semanticOnly({int topK = 4}) {
    return MultiPathRetrievalConfig(
      strategy: RerankStrategy.weightedScore,
      semanticWeight: 1.0,
      keywordWeight: 0.0,
      topK: topK,
    );
  }

  /// Create keyword-only configuration
  factory MultiPathRetrievalConfig.keywordOnly({int topK = 4}) {
    return MultiPathRetrievalConfig(
      strategy: RerankStrategy.weightedScore,
      semanticWeight: 0.0,
      keywordWeight: 1.0,
      topK: topK,
    );
  }

  /// Create rerank model configuration
  factory MultiPathRetrievalConfig.withRerankModel({
    required RerankingModel model,
    int topK = 4,
    double scoreThreshold = 0.5,
  }) {
    return MultiPathRetrievalConfig(
      strategy: RerankStrategy.rerankModel,
      rerankModel: model,
      topK: topK,
      scoreThresholdEnabled: true,
      scoreThreshold: scoreThreshold,
    );
  }
}

/// Knowledge base context configuration for applications
class KnowledgeContext {
  final List<String> knowledgeBaseIds;
  final MetadataFilterConfig? metadataFilter;
  final MultiPathRetrievalConfig? retrievalConfig;
  final bool citationEnabled;

  const KnowledgeContext({
    required this.knowledgeBaseIds,
    this.metadataFilter,
    this.retrievalConfig,
    this.citationEnabled = false,
  });

  Map<String, dynamic> toJson() => {
        'knowledge_base_ids': knowledgeBaseIds,
        if (metadataFilter != null) 'metadata_filter': metadataFilter!.toJson(),
        if (retrievalConfig != null) 'retrieval_config': retrievalConfig!.toJson(),
        'citation_enabled': citationEnabled,
      };

  factory KnowledgeContext.fromJson(Map<String, dynamic> json) {
    return KnowledgeContext(
      knowledgeBaseIds: (json['knowledge_base_ids'] as List).cast<String>(),
      metadataFilter: json['metadata_filter'] != null
          ? MetadataFilterConfig.fromJson(json['metadata_filter'] as Map<String, dynamic>)
          : null,
      retrievalConfig: json['retrieval_config'] != null
          ? MultiPathRetrievalConfig.fromJson(json['retrieval_config'] as Map<String, dynamic>)
          : null,
      citationEnabled: json['citation_enabled'] as bool? ?? false,
    );
  }
}

/// Citation and attribution result
class CitationResult {
  final String content;
  final String knowledgeBaseId;
  final String knowledgeBaseName;
  final String documentId;
  final String documentName;
  final String chunkId;
  final double score;

  const CitationResult({
    required this.content,
    required this.knowledgeBaseId,
    required this.knowledgeBaseName,
    required this.documentId,
    required this.documentName,
    required this.chunkId,
    required this.score,
  });

  factory CitationResult.fromJson(Map<String, dynamic> json) {
    return CitationResult(
      content: json['content'] as String,
      knowledgeBaseId: json['knowledge_base_id'] as String,
      knowledgeBaseName: json['knowledge_base_name'] as String,
      documentId: json['document_id'] as String,
      documentName: json['document_name'] as String,
      chunkId: json['chunk_id'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }
}
