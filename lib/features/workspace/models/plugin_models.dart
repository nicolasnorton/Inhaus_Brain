/// Models for plugin management
library;

/// Plugin installation source
enum PluginSource {
  marketplace,
  github,
  localUpload;

  String get displayName {
    switch (this) {
      case PluginSource.marketplace:
        return 'Marketplace';
      case PluginSource.github:
        return 'GitHub';
      case PluginSource.localUpload:
        return 'Local Upload';
    }
  }

  String get description {
    switch (this) {
      case PluginSource.marketplace:
        return 'Official and partner plugins, tested and maintained';
      case PluginSource.github:
        return 'Install from any public repository with URL + version';
      case PluginSource.localUpload:
        return 'Custom .zip packages for private or internal plugins';
    }
  }
}

/// Plugin type
enum PluginType {
  modelProvider,
  tool,
  customEndpoint,
  reverseInvocation;

  String get displayName {
    switch (this) {
      case PluginType.modelProvider:
        return 'Model Provider';
      case PluginType.tool:
        return 'Tool & Function';
      case PluginType.customEndpoint:
        return 'Custom Endpoint';
      case PluginType.reverseInvocation:
        return 'Reverse Invocation';
    }
  }

  String get description {
    switch (this) {
      case PluginType.modelProvider:
        return 'Every LLM in INHAUS BRAIN (OpenAI, Anthropic, etc.) is actually a plugin';
      case PluginType.tool:
        return 'API calls, data processing, calculations—all plugin-based';
      case PluginType.customEndpoint:
        return 'Expose your INHAUS BRAIN apps as APIs that external systems can call';
      case PluginType.reverseInvocation:
        return 'Plugins can call back into INHAUS BRAIN to use models, tools, or workflows';
    }
  }
}

/// Plugin status
enum PluginStatus {
  installed,
  notInstalled,
  updating,
  error;

  String get displayName {
    switch (this) {
      case PluginStatus.installed:
        return 'Installed';
      case PluginStatus.notInstalled:
        return 'Not Installed';
      case PluginStatus.updating:
        return 'Updating';
      case PluginStatus.error:
        return 'Error';
    }
  }
}

/// Plugin permission level
enum PluginPermission {
  everyone,
  adminOnly;

  String get displayName {
    switch (this) {
      case PluginPermission.everyone:
        return 'Everyone';
      case PluginPermission.adminOnly:
        return 'Admin Only';
    }
  }
}

/// Plugin model
class Plugin {
  final String id;
  final String name;
  final PluginType type;
  final PluginSource source;
  final String version;
  final String description;
  final String? icon;
  final PluginStatus status;
  final String? author;
  final DateTime? installedAt;
  final DateTime? updatedAt;
  final bool hasUpdate;
  final String? latestVersion;
  final List<String> tags;
  final String? documentationUrl;
  final String? repositoryUrl;

  const Plugin({
    required this.id,
    required this.name,
    required this.type,
    required this.source,
    required this.version,
    required this.description,
    this.icon,
    this.status = PluginStatus.notInstalled,
    this.author,
    this.installedAt,
    this.updatedAt,
    this.hasUpdate = false,
    this.latestVersion,
    this.tags = const [],
    this.documentationUrl,
    this.repositoryUrl,
  });

  Plugin copyWith({
    String? id,
    String? name,
    PluginType? type,
    PluginSource? source,
    String? version,
    String? description,
    String? icon,
    PluginStatus? status,
    String? author,
    DateTime? installedAt,
    DateTime? updatedAt,
    bool? hasUpdate,
    String? latestVersion,
    List<String>? tags,
    String? documentationUrl,
    String? repositoryUrl,
  }) {
    return Plugin(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      source: source ?? this.source,
      version: version ?? this.version,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      author: author ?? this.author,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      latestVersion: latestVersion ?? this.latestVersion,
      tags: tags ?? this.tags,
      documentationUrl: documentationUrl ?? this.documentationUrl,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toString().split('.').last,
        'source': source.toString().split('.').last,
        'version': version,
        'description': description,
        if (icon != null) 'icon': icon,
        'status': status.toString().split('.').last,
        if (author != null) 'author': author,
        if (installedAt != null) 'installed_at': installedAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        'has_update': hasUpdate,
        if (latestVersion != null) 'latest_version': latestVersion,
        'tags': tags,
        if (documentationUrl != null) 'documentation_url': documentationUrl,
        if (repositoryUrl != null) 'repository_url': repositoryUrl,
      };

  factory Plugin.fromJson(Map<String, dynamic> json) {
    return Plugin(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PluginType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PluginType.tool,
      ),
      source: PluginSource.values.firstWhere(
        (e) => e.toString().split('.').last == json['source'],
        orElse: () => PluginSource.marketplace,
      ),
      version: json['version'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String?,
      status: PluginStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PluginStatus.notInstalled,
      ),
      author: json['author'] as String?,
      installedAt: json['installed_at'] != null
          ? DateTime.parse(json['installed_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      hasUpdate: json['has_update'] as bool? ?? false,
      latestVersion: json['latest_version'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      documentationUrl: json['documentation_url'] as String?,
      repositoryUrl: json['repository_url'] as String?,
    );
  }
}

/// Plugin configuration
class PluginConfig {
  final String pluginId;
  final Map<String, dynamic> settings;
  final DateTime updatedAt;

  const PluginConfig({
    required this.pluginId,
    required this.settings,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'plugin_id': pluginId,
        'settings': settings,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      pluginId: json['plugin_id'] as String,
      settings: json['settings'] as Map<String, dynamic>,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Workspace plugin settings
class PluginSettings {
  final PluginPermission installPermission;
  final PluginPermission debugPermission;
  final bool autoUpdate;
  final List<String> blockedPlugins;

  const PluginSettings({
    this.installPermission = PluginPermission.adminOnly,
    this.debugPermission = PluginPermission.adminOnly,
    this.autoUpdate = false,
    this.blockedPlugins = const [],
  });

  PluginSettings copyWith({
    PluginPermission? installPermission,
    PluginPermission? debugPermission,
    bool? autoUpdate,
    List<String>? blockedPlugins,
  }) {
    return PluginSettings(
      installPermission: installPermission ?? this.installPermission,
      debugPermission: debugPermission ?? this.debugPermission,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      blockedPlugins: blockedPlugins ?? this.blockedPlugins,
    );
  }

  Map<String, dynamic> toJson() => {
        'install_permission': installPermission.toString().split('.').last,
        'debug_permission': debugPermission.toString().split('.').last,
        'auto_update': autoUpdate,
        'blocked_plugins': blockedPlugins,
      };

  factory PluginSettings.fromJson(Map<String, dynamic> json) {
    return PluginSettings(
      installPermission:
          PluginPermission.values.firstWhere(
            (e) => e.toString().split('.').last == json['install_permission'],
            orElse: () => PluginPermission.adminOnly,
          ),
      debugPermission:
          PluginPermission.values.firstWhere(
            (e) => e.toString().split('.').last == json['debug_permission'],
            orElse: () => PluginPermission.adminOnly,
          ),
      autoUpdate: json['auto_update'] as bool? ?? false,
      blockedPlugins:
          (json['blocked_plugins'] as List?)?.cast<String>() ?? [],
    );
  }
}
