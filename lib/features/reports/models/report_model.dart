import 'package:uuid/uuid.dart';

class Report {
  final String id;
  final String title;
  final String clientId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> sources; // File names or connection names
  // In a real app, we'd have list of ChatMessages, Notes, etc.
  
  Report({
    required this.id,
    required this.title,
    required this.clientId,
    required this.createdAt,
    required this.updatedAt,
    this.sources = const [],
  });

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
}

// Mock Data
final List<Report> mockReports = [
  Report(
    id: '1',
    title: 'Q1 Performance Analysis',
    clientId: 'client_1',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    sources: ['BigQuery: Monthly Stats', 'Drive: Strategy Doc'],
  ),
  Report(
    id: '2',
    title: 'Competitor Landscape - Banking',
    clientId: 'client_2',
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    sources: ['Web: Top 25 Ads', 'Drive: Competitor List'],
  ),
];
