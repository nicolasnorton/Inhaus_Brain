import '../models/knowledge_source.dart';

/// Base interface for all Knowledge Module connectors.
abstract class KnowledgeConnector {
  /// Unique identifier for the connector (e.g., 'meta', 'google_ads').
  String get connectorId;

  /// Human-readable name for the connector.
  String get name;

  /// Authenticates the connector using stored credentials or OAuth2 flow.
  Future<void> authenticate();

  /// Fetches recent updates from the platform since the specified date.
  Future<List<KnowledgeConnectorDocument>> fetchRecentUpdates({DateTime? since});

  /// Fetches specific metrics for a document (e.g., likes, clicks).
  Future<Map<String, dynamic>> fetchMetrics(String externalId);
}

/// A standardized document format returned by connectors before ingestion.
class KnowledgeConnectorDocument {
  final String externalId;
  final String title;
  final String content;
  final KnowledgeSourceType type;
  final DateTime publishedAt;
  final Map<String, dynamic> metadata;

  KnowledgeConnectorDocument({
    required this.externalId,
    required this.title,
    required this.content,
    required this.type,
    required this.publishedAt,
    required this.metadata,
  });
}
