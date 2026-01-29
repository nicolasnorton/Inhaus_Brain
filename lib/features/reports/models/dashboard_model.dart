
import 'package:uuid/uuid.dart';

class Dashboard {
  final String id;
  final String title;
  final String clientId;
  final Map<String, dynamic> layout; // Stores the configuration for widgets
  final DateTime createdAt;
  final DateTime updatedAt;

  Dashboard({
    required this.id,
    required this.title,
    required this.clientId,
    required this.layout,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dashboard.create({required String title, required String clientId}) {
    final now = DateTime.now();
    return Dashboard(
      id: const Uuid().v4(),
      title: title,
      clientId: clientId,
      layout: {'widgets': []}, // Empty layout initially
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'clientId': clientId,
      'layout': layout,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      id: json['id'],
      title: json['title'],
      clientId: json['clientId'],
      layout: Map<String, dynamic>.from(json['layout'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
