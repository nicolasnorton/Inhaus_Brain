/// Models for user settings and profile

/// Login method
enum LoginMethod {
  github,
  google,
  email;

  String get displayName {
    switch (this) {
      case LoginMethod.github:
        return 'GitHub';
      case LoginMethod.google:
        return 'Google';
      case LoginMethod.email:
        return 'Email';
    }
  }
}

/// Display language
enum Language {
  english,
  spanish;

  String get displayName {
    switch (this) {
      case Language.english:
        return 'English';
      case Language.spanish:
        return 'Español';
    }
  }

  String get code {
    switch (this) {
      case Language.english:
        return 'en';
      case Language.spanish:
        return 'es';
    }
  }
}

/// User role in workspace
enum UserRole {
  owner,
  admin,
  editor,
  member,
  datasetOperator;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.editor:
        return 'Editor';
      case UserRole.member:
        return 'Member';
      case UserRole.datasetOperator:
        return 'Dataset Operator';
    }
  }

  String get icon {
    switch (this) {
      case UserRole.owner:
        return '👑';
      case UserRole.admin:
        return '⚙️';
      case UserRole.editor:
        return '✏️';
      case UserRole.member:
        return '👤';
      case UserRole.datasetOperator:
        return '📊';
    }
  }

  String get description {
    switch (this) {
      case UserRole.owner:
        return 'Full workspace control';
      case UserRole.admin:
        return 'Team and resource management';
      case UserRole.editor:
        return 'Application development';
      case UserRole.member:
        return 'Application usage only';
      case UserRole.datasetOperator:
        return 'Knowledge base specialist';
    }
  }
}

/// User profile
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
  final List<LoginMethod> linkedAccounts;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
    this.linkedAccounts = const [],
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    List<LoginMethod>? linkedAccounts,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      linkedAccounts: linkedAccounts ?? this.linkedAccounts,
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
        'linked_accounts': linkedAccounts.map((a) => a.name).toList(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      linkedAccounts: (json['linked_accounts'] as List?)
              ?.map((a) => LoginMethod.values.byName(a as String))
              .toList() ??
          [],
    );
  }
}

/// User preferences
class UserPreferences {
  final Language language;
  final String? voiceLanguage; // 'en-US', 'es-EC', etc.
  final bool darkMode;
  final bool emailNotifications;

  const UserPreferences({
    this.language = Language.english,
    this.voiceLanguage,
    this.darkMode = true,
    this.emailNotifications = true,
  });

  /// Get effective voice language, defaulting to display language if not set
  String get effectiveVoiceLanguage {
    if (voiceLanguage != null) return voiceLanguage!;
    return language == Language.spanish ? 'es-EC' : 'en-US';
  }

  UserPreferences copyWith({
    Language? language,
    String? voiceLanguage,
    bool? darkMode,
    bool? emailNotifications,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      darkMode: darkMode ?? this.darkMode,
      emailNotifications: emailNotifications ?? this.emailNotifications,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language.name,
        if (voiceLanguage != null) 'voice_language': voiceLanguage,
        'dark_mode': darkMode,
        'email_notifications': emailNotifications,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      language: Language.values.byName(json['language'] as String),
      voiceLanguage: json['voice_language'] as String?,
      darkMode: json['dark_mode'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? true,
    );
  }
}

/// Workspace membership
class WorkspaceMembership {
  final String workspaceId;
  final String workspaceName;
  final UserRole role;
  final DateTime joinedAt;
  final DateTime? lastAccessedAt;

  const WorkspaceMembership({
    required this.workspaceId,
    required this.workspaceName,
    required this.role,
    required this.joinedAt,
    this.lastAccessedAt,
  });

  Map<String, dynamic> toJson() => {
        'workspace_id': workspaceId,
        'workspace_name': workspaceName,
        'role': role.name,
        'joined_at': joinedAt.toIso8601String(),
        if (lastAccessedAt != null)
          'last_accessed_at': lastAccessedAt!.toIso8601String(),
      };

  factory WorkspaceMembership.fromJson(Map<String, dynamic> json) {
    return WorkspaceMembership(
      workspaceId: json['workspace_id'] as String,
      workspaceName: json['workspace_name'] as String,
      role: UserRole.values.byName(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'] as String)
          : null,
    );
  }
}
