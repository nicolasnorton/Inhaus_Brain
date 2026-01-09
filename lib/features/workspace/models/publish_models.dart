import 'package:flutter/material.dart';

/// Publishing method
enum PublishMethod {
  webApp,
  api,
  embed,
  mcpServer;

  String get displayName {
    switch (this) {
      case PublishMethod.webApp:
        return 'Web App';
      case PublishMethod.api:
        return 'API';
      case PublishMethod.embed:
        return 'Website Embed';
      case PublishMethod.mcpServer:
        return 'MCP Server';
    }
  }

  IconData get icon {
    switch (this) {
      case PublishMethod.webApp:
        return Icons.language;
      case PublishMethod.api:
        return Icons.code;
      case PublishMethod.embed:
        return Icons.web;
      case PublishMethod.mcpServer:
        return Icons.power;
    }
  }
}

/// App type for publishing
enum PublishAppType {
  workflow,
  chatflow;

  String get displayName {
    switch (this) {
      case PublishAppType.workflow:
        return 'Workflow';
      case PublishAppType.chatflow:
        return 'Chatflow';
    }
  }
}

/// Branding configuration
class BrandingConfig {
  final String appName;
  final String description;
  final String? iconUrl;
  final String primaryColor;
  final String theme; // light, dark, auto

  const BrandingConfig({
    required this.appName,
    required this.description,
    this.iconUrl,
    this.primaryColor = '#1890ff',
    this.theme = 'light',
  });

  BrandingConfig copyWith({
    String? appName,
    String? description,
    String? iconUrl,
    String? primaryColor,
    String? theme,
  }) {
    return BrandingConfig(
      appName: appName ?? this.appName,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toJson() => {
        'app_name': appName,
        'description': description,
        if (iconUrl != null) 'icon_url': iconUrl,
        'primary_color': primaryColor,
        'theme': theme,
      };

  factory BrandingConfig.fromJson(Map<String, dynamic> json) {
    return BrandingConfig(
      appName: json['app_name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String?,
      primaryColor: json['primary_color'] as String? ?? '#1890ff',
      theme: json['theme'] as String? ?? 'light',
    );
  }
}

/// Rate limit configuration
class RateLimitConfig {
  final int requestsPerMinute;
  final int requestsPerHour;
  final int requestsPerDay;

  const RateLimitConfig({
    this.requestsPerMinute = 60,
    this.requestsPerHour = 1000,
    this.requestsPerDay = 10000,
  });

  Map<String, dynamic> toJson() => {
        'requests_per_minute': requestsPerMinute,
        'requests_per_hour': requestsPerHour,
        'requests_per_day': requestsPerDay,
      };

  factory RateLimitConfig.fromJson(Map<String, dynamic> json) {
    return RateLimitConfig(
      requestsPerMinute: json['requests_per_minute'] as int? ?? 60,
      requestsPerHour: json['requests_per_hour'] as int? ?? 1000,
      requestsPerDay: json['requests_per_day'] as int? ?? 10000,
    );
  }
}

/// Access control configuration
class AccessControlConfig {
  final bool isPublic;
  final bool requireAuth;
  final List<String> allowedDomains;
  final RateLimitConfig rateLimit;

  const AccessControlConfig({
    this.isPublic = true,
    this.requireAuth = false,
    this.allowedDomains = const [],
    this.rateLimit = const RateLimitConfig(),
  });

  Map<String, dynamic> toJson() => {
        'is_public': isPublic,
        'require_auth': requireAuth,
        'allowed_domains': allowedDomains,
        'rate_limit': rateLimit.toJson(),
      };

  factory AccessControlConfig.fromJson(Map<String, dynamic> json) {
    return AccessControlConfig(
      isPublic: json['is_public'] as bool? ?? true,
      requireAuth: json['require_auth'] as bool? ?? false,
      allowedDomains:
          (json['allowed_domains'] as List?)?.cast<String>() ?? [],
      rateLimit: RateLimitConfig.fromJson(
          json['rate_limit'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Legal configuration
class LegalConfig {
  final String copyright;
  final String? privacyPolicyUrl;
  final String? termsOfServiceUrl;

  const LegalConfig({
    this.copyright = '',
    this.privacyPolicyUrl,
    this.termsOfServiceUrl,
  });

  Map<String, dynamic> toJson() => {
        'copyright': copyright,
        if (privacyPolicyUrl != null) 'privacy_policy_url': privacyPolicyUrl,
        if (termsOfServiceUrl != null)
          'terms_of_service_url': termsOfServiceUrl,
      };

  factory LegalConfig.fromJson(Map<String, dynamic> json) {
    return LegalConfig(
      copyright: json['copyright'] as String? ?? '',
      privacyPolicyUrl: json['privacy_policy_url'] as String?,
      termsOfServiceUrl: json['terms_of_service_url'] as String?,
    );
  }
}

/// Web app configuration
class WebAppConfig {
  final String publicUrl;
  final BrandingConfig branding;
  final AccessControlConfig accessControl;
  final LegalConfig legal;
  final bool enabled;

  const WebAppConfig({
    required this.publicUrl,
    required this.branding,
    this.accessControl = const AccessControlConfig(),
    this.legal = const LegalConfig(),
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'public_url': publicUrl,
        'branding': branding.toJson(),
        'access_control': accessControl.toJson(),
        'legal': legal.toJson(),
        'enabled': enabled,
      };

  factory WebAppConfig.fromJson(Map<String, dynamic> json) {
    return WebAppConfig(
      publicUrl: json['public_url'] as String,
      branding: BrandingConfig.fromJson(
          json['branding'] as Map<String, dynamic>),
      accessControl: AccessControlConfig.fromJson(
          json['access_control'] as Map<String, dynamic>? ?? {}),
      legal: LegalConfig.fromJson(
          json['legal'] as Map<String, dynamic>? ?? {}),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

/// API endpoint
class APIEndpoint {
  final String path;
  final String method;
  final String description;
  final Map<String, dynamic> requestSchema;
  final Map<String, dynamic> responseSchema;

  const APIEndpoint({
    required this.path,
    required this.method,
    required this.description,
    required this.requestSchema,
    required this.responseSchema,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'method': method,
        'description': description,
        'request_schema': requestSchema,
        'response_schema': responseSchema,
      };

  factory APIEndpoint.fromJson(Map<String, dynamic> json) {
    return APIEndpoint(
      path: json['path'] as String,
      method: json['method'] as String,
      description: json['description'] as String,
      requestSchema: json['request_schema'] as Map<String, dynamic>,
      responseSchema: json['response_schema'] as Map<String, dynamic>,
    );
  }
}

/// API configuration
class APIConfig {
  final String endpoint;
  final String apiKey;
  final bool enabled;
  final RateLimitConfig rateLimit;
  final List<APIEndpoint> endpoints;

  const APIConfig({
    required this.endpoint,
    required this.apiKey,
    this.enabled = true,
    this.rateLimit = const RateLimitConfig(),
    this.endpoints = const [],
  });

  Map<String, dynamic> toJson() => {
        'endpoint': endpoint,
        'api_key': apiKey,
        'enabled': enabled,
        'rate_limit': rateLimit.toJson(),
        'endpoints': endpoints.map((e) => e.toJson()).toList(),
      };

  factory APIConfig.fromJson(Map<String, dynamic> json) {
    return APIConfig(
      endpoint: json['endpoint'] as String,
      apiKey: json['api_key'] as String,
      enabled: json['enabled'] as bool? ?? true,
      rateLimit: RateLimitConfig.fromJson(
          json['rate_limit'] as Map<String, dynamic>? ?? {}),
      endpoints: (json['endpoints'] as List?)
              ?.map((e) => APIEndpoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Embed type
enum EmbedType {
  chatWidget,
  iframe;

  String get displayName {
    switch (this) {
      case EmbedType.chatWidget:
        return 'Chat Widget';
      case EmbedType.iframe:
        return 'Inline Frame';
    }
  }
}

/// Widget position
enum WidgetPosition {
  bottomRight,
  bottomLeft,
  topRight,
  topLeft;

  String get displayName {
    switch (this) {
      case WidgetPosition.bottomRight:
        return 'Bottom Right';
      case WidgetPosition.bottomLeft:
        return 'Bottom Left';
      case WidgetPosition.topRight:
        return 'Top Right';
      case WidgetPosition.topLeft:
        return 'Top Left';
    }
  }
}

/// Embed configuration
class EmbedConfig {
  final EmbedType type;
  final WidgetPosition? position;
  final String? customCSS;
  final int? width;
  final int? height;
  final String embedCode;

  const EmbedConfig({
    required this.type,
    required this.embedCode,
    this.position,
    this.customCSS,
    this.width,
    this.height,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'embed_code': embedCode,
        if (position != null) 'position': position!.name,
        if (customCSS != null) 'custom_css': customCSS,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

  factory EmbedConfig.fromJson(Map<String, dynamic> json) {
    return EmbedConfig(
      type: EmbedType.values.byName(json['type'] as String),
      embedCode: json['embed_code'] as String,
      position: json['position'] != null
          ? WidgetPosition.values.byName(json['position'] as String)
          : null,
      customCSS: json['custom_css'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }
}

/// MCP tool
class MCPTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Map<String, dynamic> outputSchema;

  const MCPTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.outputSchema,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'input_schema': inputSchema,
        'output_schema': outputSchema,
      };

  factory MCPTool.fromJson(Map<String, dynamic> json) {
    return MCPTool(
      name: json['name'] as String,
      description: json['description'] as String,
      inputSchema: json['input_schema'] as Map<String, dynamic>,
      outputSchema: json['output_schema'] as Map<String, dynamic>,
    );
  }
}

/// MCP server configuration
class MCPServerConfig {
  final String serverUrl;
  final bool enabled;
  final String? description;
  final List<MCPTool> tools;

  const MCPServerConfig({
    required this.serverUrl,
    this.enabled = false,
    this.description,
    this.tools = const [],
  });

  Map<String, dynamic> toJson() => {
        'server_url': serverUrl,
        'enabled': enabled,
        if (description != null) 'description': description,
        'tools': tools.map((t) => t.toJson()).toList(),
      };

  factory MCPServerConfig.fromJson(Map<String, dynamic> json) {
    return MCPServerConfig(
      serverUrl: json['server_url'] as String,
      enabled: json['enabled'] as bool? ?? false,
      description: json['description'] as String?,
      tools: (json['tools'] as List?)
              ?.map((t) => MCPTool.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Publishing configuration
class PublishConfig {
  final String appId;
  final String appName;
  final String description;
  final String? iconUrl;
  final PublishAppType appType;
  final List<PublishMethod> enabledMethods;
  final WebAppConfig webApp;
  final APIConfig api;
  final EmbedConfig? embed;
  final MCPServerConfig? mcpServer;
  final DateTime publishedAt;
  final bool isPublished;

  const PublishConfig({
    required this.appId,
    required this.appName,
    required this.description,
    this.iconUrl,
    required this.appType,
    required this.enabledMethods,
    required this.webApp,
    required this.api,
    this.embed,
    this.mcpServer,
    required this.publishedAt,
    this.isPublished = false,
  });

  Map<String, dynamic> toJson() => {
        'app_id': appId,
        'app_name': appName,
        'description': description,
        if (iconUrl != null) 'icon_url': iconUrl,
        'app_type': appType.name,
        'enabled_methods': enabledMethods.map((m) => m.name).toList(),
        'web_app': webApp.toJson(),
        'api': api.toJson(),
        if (embed != null) 'embed': embed!.toJson(),
        if (mcpServer != null) 'mcp_server': mcpServer!.toJson(),
        'published_at': publishedAt.toIso8601String(),
        'is_published': isPublished,
      };

  factory PublishConfig.fromJson(Map<String, dynamic> json) {
    return PublishConfig(
      appId: json['app_id'] as String,
      appName: json['app_name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String?,
      appType: PublishAppType.values.byName(json['app_type'] as String),
      enabledMethods: (json['enabled_methods'] as List)
          .map((m) => PublishMethod.values.byName(m as String))
          .toList(),
      webApp: WebAppConfig.fromJson(json['web_app'] as Map<String, dynamic>),
      api: APIConfig.fromJson(json['api'] as Map<String, dynamic>),
      embed: json['embed'] != null
          ? EmbedConfig.fromJson(json['embed'] as Map<String, dynamic>)
          : null,
      mcpServer: json['mcp_server'] != null
          ? MCPServerConfig.fromJson(
              json['mcp_server'] as Map<String, dynamic>)
          : null,
      publishedAt: DateTime.parse(json['published_at'] as String),
      isPublished: json['is_published'] as bool? ?? false,
    );
  }
}
