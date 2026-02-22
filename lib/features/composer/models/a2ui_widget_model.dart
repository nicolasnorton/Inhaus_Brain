import 'package:cloud_firestore/cloud_firestore.dart';

class A2uiWidgetModel {
  final String id;
  final String name;
  final String jsonSchema;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  A2uiWidgetModel({
    required this.id,
    required this.name,
    required this.jsonSchema,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory A2uiWidgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Missing data for document \${doc.id}');
    }
    
    return A2uiWidgetModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled Widget',
      jsonSchema: data['jsonSchema'] as String? ?? '{}',
      ownerId: data['ownerId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'jsonSchema': jsonSchema,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  A2uiWidgetModel copyWith({
    String? name,
    String? jsonSchema,
  }) {
    return A2uiWidgetModel(
      id: id,
      name: name ?? this.name,
      jsonSchema: jsonSchema ?? this.jsonSchema,
      ownerId: ownerId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
