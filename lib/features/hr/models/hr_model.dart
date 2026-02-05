import 'package:uuid/uuid.dart';

enum EmployeeStatus {
  active,
  probation, // Important for Ecuador 90-day rule
  terminated,
  contractor
}

enum Department {
  creative,
  tech,
  accounts,
  finance,
  hr,
  admin
}

class Employee {
  final String id;
  final String fullName;
  final String role;
  final Department department;
  final EmployeeStatus status;
  final DateTime hireDate;
  final double salary;
  final String email;
  final Map<String, dynamic> metadata;

  Employee({
    required this.id,
    required this.fullName,
    required this.role,
    required this.department,
    required this.status,
    required this.hireDate,
    required this.salary,
    required this.email,
    this.metadata = const {},
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      fullName: json['fullName'],
      role: json['role'],
      department: Department.values[json['department'] ?? 0],
      status: EmployeeStatus.values[json['status'] ?? 0],
      hireDate: DateTime.parse(json['hireDate']),
      salary: json['salary'].toDouble(),
      email: json['email'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'role': role,
    'department': department.index,
    'status': status.index,
    'hireDate': hireDate.toIso8601String(),
    'salary': salary,
    'email': email,
    'metadata': metadata,
  };
}

class HRDocument {
  final String id;
  final String title;
  final String type; // Contract, Memo, Policy
  final String content;
  final DateTime createdAt;
  final String? relatedEmployeeId;

  HRDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.createdAt,
    this.relatedEmployeeId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'relatedEmployeeId': relatedEmployeeId,
  };
    
  factory HRDocument.create({required String title, required String type, required String content, String? employeeId}) {
     return HRDocument(
        id: const Uuid().v4(),
        title: title,
        type: type,
        content: content,
        createdAt: DateTime.now(),
        relatedEmployeeId: employeeId
     );
  }
}
