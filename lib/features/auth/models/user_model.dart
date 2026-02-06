enum UserRole {
  superAdmin,
  admin,
  accountManager,
  designer,
  socialMediaManager,
  adManager,
  humanAgencyStaff,
  clientUser
}

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final UserRole role;
  final List<String> assignedClientIds;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    this.assignedClientIds = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      role: UserRole.values.firstWhere((e) => e.toString().split('.').last == json['role']),
      assignedClientIds: List<String>.from(json['assignedClientIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'role': role.toString().split('.').last,
    'assignedClientIds': assignedClientIds,
  };

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    List<String>? assignedClientIds,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      assignedClientIds: assignedClientIds ?? this.assignedClientIds,
    );
  }
}
