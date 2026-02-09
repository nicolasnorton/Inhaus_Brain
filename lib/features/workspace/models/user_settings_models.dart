/// User theme preference
enum ThemePreference {
  light,
  dark,
  system;

  String get displayName {
    switch (this) {
      case ThemePreference.light:
        return 'Light';
      case ThemePreference.dark:
        return 'Dark';
      case ThemePreference.system:
        return 'System';
    }
  }
}

/// User profile model
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? organization;
  final String? timezone;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.organization,
    this.timezone,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? organization,
    String? timezone,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      organization: organization ?? this.organization,
      timezone: timezone ?? this.timezone,
    );
  }
}

/// User notification settings
class NotificationSettings {
  final bool emailNotifications;
  final bool usageAlerts;
  final bool securityAlerts;
  final bool productUpdates;

  const NotificationSettings({
    this.emailNotifications = true,
    this.usageAlerts = true,
    this.securityAlerts = true,
    this.productUpdates = false,
  });

  NotificationSettings copyWith({
    bool? emailNotifications,
    bool? usageAlerts,
    bool? securityAlerts,
    bool? productUpdates,
  }) {
    return NotificationSettings(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      usageAlerts: usageAlerts ?? this.usageAlerts,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      productUpdates: productUpdates ?? this.productUpdates,
    );
  }
}

/// Workspace API Key model
class WorkspaceApiKey {
  final String id;
  final String name;
  final String key;
  final DateTime createdAt;
  final DateTime? lastUsed;

  const WorkspaceApiKey({
    required this.id,
    required this.name,
    required this.key,
    required this.createdAt,
    this.lastUsed,
  });
}

/// Global user settings container
class UserSettings {
  final UserProfile profile;
  final ThemePreference theme;
  final NotificationSettings notifications;
  final List<WorkspaceApiKey> apiKeys;
  final String preferredModelId;

  const UserSettings({
    required this.profile,
    required this.theme,
    required this.notifications,
    required this.apiKeys,
    this.preferredModelId = 'gemini-1.5-flash-002',
  });

  UserSettings copyWith({
    UserProfile? profile,
    ThemePreference? theme,
    NotificationSettings? notifications,
    List<WorkspaceApiKey>? apiKeys,
    String? preferredModelId,
  }) {
    return UserSettings(
      profile: profile ?? this.profile,
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      apiKeys: apiKeys ?? this.apiKeys,
      preferredModelId: preferredModelId ?? this.preferredModelId,
    );
  }
}
