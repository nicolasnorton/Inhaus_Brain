class ClientContact {
  final String id;
  final String clientId;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // e.g., "Marketing Director", "CEO"
  final String accessLevel; // e.g., "admin", "viewer", "approver"
  final String? phoneNumber;
  final DateTime createdAt;

  ClientContact({
    required this.id,
    required this.clientId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.accessLevel = 'viewer',
    this.phoneNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';

  ClientContact copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? accessLevel,
    String? phoneNumber,
  }) {
    return ClientContact(
      id: id,
      clientId: clientId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      accessLevel: accessLevel ?? this.accessLevel,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
    );
  }

  factory ClientContact.fromJson(Map<String, dynamic> json) {
    return ClientContact(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      accessLevel: json['accessLevel'] as String? ?? 'viewer',
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'role': role,
    'accessLevel': accessLevel,
    'phoneNumber': phoneNumber,
    'createdAt': createdAt.toIso8601String(),
  };
}
