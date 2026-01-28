/// Models for Index Method and Retrieval Settings
library;

/// Index method enum
enum IndexMethod {
  highQuality,
  economical;

  String get apiValue {
    switch (this) {
      case IndexMethod.highQuality:
        return 'high_quality';
      case IndexMethod.economical:
        return 'economical';
    }
  }

  String get displayName {
    switch (this) {
      case IndexMethod.highQuality:
        return 'High Quality';
      case IndexMethod.economical:
        return 'Economical';
    }
  }

  String get description {
    switch (this) {
      case IndexMethod.highQuality:
        return 'Calling the embedding model to process documents for more precise retrieval helps LLM generate high-quality answers.';
      case IndexMethod.economical:
        return 'Using 10 keywords per chunk for retrieval, no tokens are consumed at the expense of reduced retrieval accuracy.';
    }
  }
}

/// Retrieval method enum (for High Quality index)
enum RetrievalMethod {
  vectorSearch,
  fullTextSearch,
  hybridSearch;

  String get apiValue {
    switch (this) {
      case RetrievalMethod.vectorSearch:
        return 'vector_search';
      case RetrievalMethod.fullTextSearch:
        return 'full_text_search';
      case RetrievalMethod.hybridSearch:
        return 'hybrid_search';
    }
  }

  String get displayName {
    switch (this) {
      case RetrievalMethod.vectorSearch:
        return 'Vector Search';
      case RetrievalMethod.fullTextSearch:
        return 'Full-Text Search';
      case RetrievalMethod.hybridSearch:
        return 'Hybrid Search';
    }
  }

  String get description {
    switch (this) {
      case RetrievalMethod.vectorSearch:
        return 'Generate query embeddings and search for the text chunk most similar to its vector representation.';
      case RetrievalMethod.fullTextSearch:
        return 'Index all terms in the document, allowing users to search any term and retrieve relevant text chunk containing those terms.';
      case RetrievalMethod.hybridSearch:
        return 'Execute full-text search and vector searches simultaneously, re-rank to select the best match for the user\'s query. Users can choose to set weights or configure to a Rerank model.';
    }
  }
}

/// Retrieval settings configuration
class RetrievalSettings {
  final RetrievalMethod searchMethod;
  final bool rerankingEnable;
  final String? rerankingMode;
  final RerankingModel? rerankingModel;
  final Map<String, double>? weights; // For hybrid search
  final int topK;
  final bool scoreThresholdEnabled;
  final double? scoreThreshold;

  const RetrievalSettings({
    required this.searchMethod,
    this.rerankingEnable = false,
    this.rerankingMode,
    this.rerankingModel,
    this.weights,
    this.topK = 3,
    this.scoreThresholdEnabled = false,
    this.scoreThreshold,
  });

  Map<String, dynamic> toJson() => {
        'search_method': searchMethod.apiValue,
        'reranking_enable': rerankingEnable,
        if (rerankingMode != null) 'reranking_mode': rerankingMode,
        if (rerankingModel != null) 'reranking_model': rerankingModel!.toJson(),
        if (weights != null) 'weights': weights,
        'top_k': topK,
        'score_threshold_enabled': scoreThresholdEnabled,
        if (scoreThreshold != null) 'score_threshold': scoreThreshold,
      };

  factory RetrievalSettings.fromJson(Map<String, dynamic> json) {
    return RetrievalSettings(
      searchMethod: RetrievalMethod.values.firstWhere(
        (e) => e.apiValue == json['search_method'],
      ),
      rerankingEnable: json['reranking_enable'] as bool? ?? false,
      rerankingMode: json['reranking_mode'] as String?,
      rerankingModel: json['reranking_model'] != null
          ? RerankingModel.fromJson(json['reranking_model'] as Map<String, dynamic>)
          : null,
      weights: json['weights'] != null
          ? Map<String, double>.from(json['weights'] as Map)
          : null,
      topK: json['top_k'] as int? ?? 3,
      scoreThresholdEnabled: json['score_threshold_enabled'] as bool? ?? false,
      scoreThreshold: json['score_threshold'] as double?,
    );
  }

  /// Create default vector search settings
  factory RetrievalSettings.vectorSearch({
    int topK = 3,
    double scoreThreshold = 0.5,
  }) {
    return RetrievalSettings(
      searchMethod: RetrievalMethod.vectorSearch,
      topK: topK,
      scoreThresholdEnabled: true,
      scoreThreshold: scoreThreshold,
    );
  }

  /// Create default full-text search settings
  factory RetrievalSettings.fullTextSearch({
    int topK = 3,
  }) {
    return RetrievalSettings(
      searchMethod: RetrievalMethod.fullTextSearch,
      topK: topK,
    );
  }

  /// Create default hybrid search settings
  factory RetrievalSettings.hybridSearch({
    int topK = 3,
    double semanticWeight = 0.5,
    double keywordWeight = 0.5,
  }) {
    return RetrievalSettings(
      searchMethod: RetrievalMethod.hybridSearch,
      topK: topK,
      weights: {
        'semantic': semanticWeight,
        'keyword': keywordWeight,
      },
    );
  }
}

/// Reranking model configuration
class RerankingModel {
  final String rerankingProviderName;
  final String rerankingModelName;

  const RerankingModel({
    required this.rerankingProviderName,
    required this.rerankingModelName,
  });

  Map<String, dynamic> toJson() => {
        'reranking_provider_name': rerankingProviderName,
        'reranking_model_name': rerankingModelName,
      };

  factory RerankingModel.fromJson(Map<String, dynamic> json) {
    return RerankingModel(
      rerankingProviderName: json['reranking_provider_name'] as String,
      rerankingModelName: json['reranking_model_name'] as String,
    );
  }
}

/// Q&A mode configuration (for self-hosted deployments)
class QAModeConfig {
  final bool enabled;

  const QAModeConfig({this.enabled = false});

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
      };
}

/// Chunk mode enum
enum ChunkMode {
  general,
  parentChild,
  qa;

  String get displayName {
    switch (this) {
      case ChunkMode.general:
        return 'General';
      case ChunkMode.parentChild:
        return 'Parent-Child';
      case ChunkMode.qa:
        return 'Q&A';
    }
  }
}

/// Process rule for document chunking
class ProcessRule {
  final String mode; // 'automatic' or 'custom'
  final Map<String, dynamic>? rules;

  const ProcessRule({
    required this.mode,
    this.rules,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode,
        if (rules != null) 'rules': rules,
      };

  factory ProcessRule.fromJson(Map<String, dynamic> json) {
    return ProcessRule(
      mode: json['mode'] as String,
      rules: json['rules'] as Map<String, dynamic>?,
    );
  }

  /// Create automatic processing rule
  factory ProcessRule.automatic() {
    return const ProcessRule(mode: 'automatic');
  }

  /// Create custom processing rule
  factory ProcessRule.custom({
    required List<Map<String, dynamic>> preProcessingRules,
    required Map<String, dynamic> segmentation,
  }) {
    return ProcessRule(
      mode: 'custom',
      rules: {
        'pre_processing_rules': preProcessingRules,
        'segmentation': segmentation,
      },
    );
  }
}

/// Embedding model configuration
class EmbeddingModelConfig {
  final String provider;
  final String model;
  final bool isMultimodal;

  const EmbeddingModelConfig({
    required this.provider,
    required this.model,
    this.isMultimodal = false,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'model': model,
        'is_multimodal': isMultimodal,
      };
}
