/// Request model for querying external knowledge base
class ExternalKnowledgeRequest {
  final String knowledgeId;
  final String query;
  final RetrievalSetting retrievalSetting;
  final MetadataCondition? metadataCondition;

  const ExternalKnowledgeRequest({
    required this.knowledgeId,
    required this.query,
    required this.retrievalSetting,
    this.metadataCondition,
  });

  Map<String, dynamic> toJson() => {
        'knowledge_id': knowledgeId,
        'query': query,
        'retrieval_setting': retrievalSetting.toJson(),
        if (metadataCondition != null) 'metadata_condition': metadataCondition!.toJson(),
      };
}

/// Retrieval settings for query
class RetrievalSetting {
  final int topK;
  final double scoreThreshold;

  const RetrievalSetting({
    required this.topK,
    required this.scoreThreshold,
  });

  Map<String, dynamic> toJson() => {
        'top_k': topK,
        'score_threshold': scoreThreshold,
      };
}

/// Metadata filtering condition
class MetadataCondition {
  final String logicalOperator; // 'and' or 'or'
  final List<Condition> conditions;

  const MetadataCondition({
    required this.logicalOperator,
    required this.conditions,
  });

  Map<String, dynamic> toJson() => {
        'logical_operator': logicalOperator,
        'conditions': conditions.map((c) => c.toJson()).toList(),
      };
}

/// Individual filter condition
class Condition {
  final List<String> name;
  final String comparisonOperator;
  final String? value;

  const Condition({
    required this.name,
    required this.comparisonOperator,
    this.value,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'comparison_operator': comparisonOperator,
        if (value != null) 'value': value,
      };
}

/// Response from external knowledge base query
class ExternalKnowledgeResponse {
  final List<KnowledgeRecord> records;

  const ExternalKnowledgeResponse({required this.records});

  factory ExternalKnowledgeResponse.fromJson(Map<String, dynamic> json) {
    final recordsList = json['records'] as List;
    return ExternalKnowledgeResponse(
      records: recordsList.map((r) => KnowledgeRecord.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'records': records.map((r) => r.toJson()).toList(),
      };
}

/// Individual knowledge record from query result
class KnowledgeRecord {
  final String content;
  final double score;
  final String title;
  final Map<String, dynamic>? metadata;

  const KnowledgeRecord({
    required this.content,
    required this.score,
    required this.title,
    this.metadata,
  });

  factory KnowledgeRecord.fromJson(Map<String, dynamic> json) {
    return KnowledgeRecord(
      content: json['content'] as String,
      score: (json['score'] as num).toDouble(),
      title: json['title'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'content': content,
        'score': score,
        'title': title,
        if (metadata != null) 'metadata': metadata,
      };
}

/// Error response from external knowledge API
class ExternalKnowledgeError {
  final int errorCode;
  final String errorMsg;

  const ExternalKnowledgeError({
    required this.errorCode,
    required this.errorMsg,
  });

  factory ExternalKnowledgeError.fromJson(Map<String, dynamic> json) {
    return ExternalKnowledgeError(
      errorCode: json['error_code'] as int,
      errorMsg: json['error_msg'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'error_code': errorCode,
        'error_msg': errorMsg,
      };

  // Error code constants
  static const int invalidAuthFormat = 1001;
  static const int authFailed = 1002;
  static const int knowledgeNotExist = 2001;

  String get errorDescription {
    switch (errorCode) {
      case invalidAuthFormat:
        return 'Invalid Authorization header format';
      case authFailed:
        return 'Authorization failed';
      case knowledgeNotExist:
        return 'The knowledge base does not exist';
      default:
        return errorMsg;
    }
  }
}

/// Connection status enum
enum ConnectionStatus {
  active,
  error,
  pending,
  inactive;

  String get displayName {
    switch (this) {
      case ConnectionStatus.active:
        return 'Active';
      case ConnectionStatus.error:
        return 'Error';
      case ConnectionStatus.pending:
        return 'Pending';
      case ConnectionStatus.inactive:
        return 'Inactive';
    }
  }
}

/// External connection configuration
class ExternalConnection {
  final String id;
  final String name;
  final String endpoint;
  final String? apiKey;
  final ConnectionStatus status;
  final DateTime? lastSync;
  final String? knowledgeId; // Pipeline ID for LlamaCloud

  const ExternalConnection({
    required this.id,
    required this.name,
    required this.endpoint,
    this.apiKey,
    required this.status,
    this.lastSync,
    this.knowledgeId,
  });

  factory ExternalConnection.fromJson(Map<String, dynamic> json) {
    return ExternalConnection(
      id: json['id'] as String,
      name: json['name'] as String,
      endpoint: json['endpoint'] as String,
      apiKey: json['api_key'] as String?,
      status: ConnectionStatus.values.byName(json['status'] as String),
      lastSync: json['last_sync'] != null ? DateTime.parse(json['last_sync'] as String) : null,
      knowledgeId: json['knowledge_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'endpoint': endpoint,
        if (apiKey != null) 'api_key': apiKey,
        'status': status.name,
        if (lastSync != null) 'last_sync': lastSync!.toIso8601String(),
        if (knowledgeId != null) 'knowledge_id': knowledgeId,
      };

  ExternalConnection copyWith({
    String? id,
    String? name,
    String? endpoint,
    String? apiKey,
    ConnectionStatus? status,
    DateTime? lastSync,
    String? knowledgeId,
  }) {
    return ExternalConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      apiKey: apiKey ?? this.apiKey,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
      knowledgeId: knowledgeId ?? this.knowledgeId,
    );
  }
}
