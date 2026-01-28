/// Member roles in the workspace
enum MemberRole {
  owner,
  admin,
  editor,
  viewer;

  String get displayName {
    switch (this) {
      case MemberRole.owner:
        return 'Owner';
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.editor:
        return 'Editor';
      case MemberRole.viewer:
        return 'Viewer';
    }
  }

  String get description {
    switch (this) {
      case MemberRole.owner:
        return 'Full access to all workspace settings and billing';
      case MemberRole.admin:
        return 'Can manage members, apps, and workspace settings';
      case MemberRole.editor:
        return 'Can create and edit apps, but cannot manage members';
      case MemberRole.viewer:
        return 'Can view and run apps, but cannot make changes';
    }
  }
}

/// Member status
enum MemberStatus {
  active,
  pending,
  inactive;

  String get displayName {
    switch (this) {
      case MemberStatus.active:
        return 'Active';
      case MemberStatus.pending:
        return 'Pending Invite';
      case MemberStatus.inactive:
        return 'Inactive';
    }
  }
}

/// Workspace member model
class Member {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final MemberRole role;
  final MemberStatus status;
  final DateTime joinedAt;
  final DateTime? lastActive;

  const Member({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.status = MemberStatus.active,
    required this.joinedAt,
    this.lastActive,
  });

  Member copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    MemberRole? role,
    MemberStatus? status,
    DateTime? joinedAt,
    DateTime? lastActive,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'role': role.name,
        'status': status.name,
        'joined_at': joinedAt.toIso8601String(),
        if (lastActive != null) 'last_active': lastActive!.toIso8601String(),
      };

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: MemberRole.values.byName(json['role'] as String),
      status: MemberStatus.values.byName(json['status'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'] as String)
          : null,
    );
  }
}

/// Workspace invitation model
class WorkspaceInvite {
  final String id;
  final String email;
  final MemberRole role;
  final DateTime sentAt;
  final DateTime expiresAt;

  const WorkspaceInvite({
    required this.id,
    required this.email,
    required this.role,
    required this.sentAt,
    required this.expiresAt,
  });
}
