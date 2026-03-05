import 'package:uuid/uuid.dart';
import 'source_model.dart';


enum ReportOutputType {
  audio,
  video,
  text,
  image,
  pdf
}

class Citation {
  final String sourceId;
  final String sourceName;
  final String excerpt;      // The exact passage being cited
  final int? pageNumber;
  final double? relevanceScore;

  Citation({
    required this.sourceId,
    required this.sourceName,
    required this.excerpt,
    this.pageNumber,
    this.relevanceScore,
  });

  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'sourceName': sourceName,
    'excerpt': excerpt,
    'pageNumber': pageNumber,
    'relevanceScore': relevanceScore,
  };

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      sourceId: json['sourceId'],
      sourceName: json['sourceName'],
      excerpt: json['excerpt'],
      pageNumber: json['pageNumber'],
      relevanceScore: json['relevanceScore']?.toDouble(),
    );
  }
}

class ReportOutput {
  final String id;
  final String title;
  final ReportOutputType type;
  final String? content; // For text/markdown
  final String? uri; // For audio/video/image files
  final DateTime createdAt;
  final List<Citation> citations;

  ReportOutput({
    required this.id,
    required this.title,
    required this.type,
    this.content,
    this.uri,
    required this.createdAt,
    List<Citation>? citations,
  }) : citations = citations ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.index,
    'content': content,
    'uri': uri,
    'createdAt': createdAt.toIso8601String(),
    'citations': citations.map((c) => c.toJson()).toList(),
  };

  factory ReportOutput.fromJson(Map<String, dynamic> json) {
    return ReportOutput(
      id: json['id'],
      title: json['title'],
      type: ReportOutputType.values[json['type'] ?? 0],
      content: json['content'],
      uri: json['uri'],
      createdAt: DateTime.parse(json['createdAt']),
      citations: (json['citations'] as List<dynamic>?)
          ?.map((e) => Citation.fromJson(e))
          .toList(),
    );
  }
}

class Report {
  final String id;
  final String title;
  final String clientId;
  final String? createdBy; // User ID of creator
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? datasetId; // Reference to Knowledge Base
  final String? pdfUrl; // Reference to generated PDF report
  final List<ReportSource> sources; 
  final List<ReportOutput> outputs;

  Report({
    required this.id,
    required this.title,
    required this.clientId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.datasetId,
    this.pdfUrl,
    List<ReportSource>? sources,
    List<ReportOutput>? outputs,
  }) : sources = sources ?? [], outputs = outputs ?? [];

  /// Safe timestamp parsing — handles Firestore Timestamp, ISO String, and null
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    try { return (date as dynamic).toDate(); } catch (_) { return DateTime.now(); }
  }

  factory Report.create({required String title, required String clientId, String? datasetId, String? createdBy}) {
    final now = DateTime.now();
    return Report(
      id: const Uuid().v4(),
      title: title,
      clientId: clientId,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      datasetId: datasetId,
      pdfUrl: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'clientId': clientId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'datasetId': datasetId,
      'pdfUrl': pdfUrl,
      'sources': sources.map((s) => s.toJson()).toList(),
      'outputs': outputs.map((o) => o.toJson()).toList(),
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id']?.toString() ?? 'unknown',
      title: json['title']?.toString() ?? 'Untitled Report',
      clientId: json['clientId']?.toString() ?? '',
      createdBy: json['createdBy']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      datasetId: json['datasetId']?.toString(),
      pdfUrl: json['pdfUrl']?.toString(),
      sources: (json['sources'] as List<dynamic>?)
          ?.map((e) => ReportSource.fromJson(e))
          .toList(),
      outputs: (json['outputs'] as List<dynamic>?)
          ?.map((e) => ReportOutput.fromJson(e))
          .toList(),
    );
  }

  Report copyWith({
    String? id,
    String? title,
    String? clientId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? datasetId,
    String? pdfUrl,
    List<ReportSource>? sources,
    List<ReportOutput>? outputs,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      clientId: clientId ?? this.clientId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      datasetId: datasetId ?? this.datasetId,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      sources: sources ?? this.sources,
      outputs: outputs ?? this.outputs,
    );
  }
}

// Mock Data
final List<Report> mockReports = [
  Report(
    id: '1',
    title: 'Q1 Performance Analysis',
    clientId: 'client_1',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    sources: [
       ReportSource(id: 's1', reportId: '1', type: SourceType.dataConnector, name: 'BigQuery: Monthly Stats', addedAt: DateTime.now()),
       ReportSource(id: 's2', reportId: '1', type: SourceType.file, name: 'Strategy Doc.pdf', addedAt: DateTime.now()),
    ],
    outputs: [
       ReportOutput(id: 'o1', title: 'Audio Summary', type: ReportOutputType.audio, uri: 'assets/audio/success_chime.mp3', createdAt: DateTime.now()),
    ],
  ),
  Report(
    id: '2',
    title: 'Competitor Landscape - Banking',
    clientId: 'client_2',
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    sources: [
       ReportSource(id: 's3', reportId: '2', type: SourceType.web, name: 'Web: Top 25 Ads', addedAt: DateTime.now()),
    ],
  ),
];
