import 'package:uuid/uuid.dart';
import 'source_model.dart';

class Report {
  final String id;
  final String title;
  final String clientId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReportSource> sources; // Changed to full object

  Report({
    required this.id,
    required this.title,
    required this.clientId,
    required this.createdAt,
    required this.updatedAt,
    List<ReportSource>? sources,
  }) : sources = sources ?? [];

  factory Report.create({required String title, required String clientId}) {
    final now = DateTime.now();
    return Report(
      id: const Uuid().v4(),
      title: title,
      clientId: clientId,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'clientId': clientId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sources': sources.map((s) => s.toJson()).toList(),
    };
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      title: json['title'],
      clientId: json['clientId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      sources: (json['sources'] as List<dynamic>?)
          ?.map((e) => ReportSource.fromJson(e))
          .toList(),
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
