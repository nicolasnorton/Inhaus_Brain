
enum SourceType {
  file,      // PDF, CSV, Text
  web,       // URL
  dataConnector, // BigQuery, SQL
  social,     // Meta Organic, TikTok Organic
  adAccount,   // Google Ads, Meta Ads
  analytics,   // GA4, Search Console
  pastedText // Copied Text
}

class ReportSource {
  final String id;
  final String reportId;
  final SourceType type;
  final String name;
  final String? content; // For text-extracted content
  final String? uri;     // URL or Path
  final Map<String, dynamic> metadata;
  final DateTime addedAt;

  ReportSource({
    required this.id,
    required this.reportId,
    required this.type,
    required this.name,
    this.content,
    this.uri,
    this.metadata = const {},
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'type': type.index,
      'name': name,
      'content': content,
      'uri': uri,
      'metadata': metadata,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory ReportSource.fromJson(Map<String, dynamic> json) {
    return ReportSource(
      id: json['id'],
      reportId: json['reportId'],
      type: SourceType.values[json['type'] ?? 0],
      name: json['name'],
      content: json['content'],
      uri: json['uri'],
      metadata: json['metadata'] ?? {},
      addedAt: DateTime.parse(json['addedAt']),
    );
  }
}
