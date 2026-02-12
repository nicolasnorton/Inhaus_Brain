class StitchProject {
  final String id;
  final String displayName;
  final String description;
  final DateTime createTime;
  final DateTime updateTime;

  StitchProject({
    required this.id,
    required this.displayName,
    required this.description,
    required this.createTime,
    required this.updateTime,
  });

  factory StitchProject.fromJson(Map<String, dynamic> json) {
    return StitchProject(
      id: json['name']?.split('/').last ?? '', // name is full path projects/{project}/locations/{location}/projects/{id}
      displayName: json['display_name'] ?? '',
      description: json['description'] ?? '',
      createTime: DateTime.parse(json['create_time']),
      updateTime: DateTime.parse(json['update_time']),
    );
  }
}

class StitchScreen {
  final String id;
  final String displayName;
  final String? imageUrl;
  final String? code;
  final DateTime createTime;
  final DateTime updateTime;

  StitchScreen({
    required this.id,
    required this.displayName,
    this.imageUrl,
    this.code,
    required this.createTime,
    required this.updateTime,
  });

  factory StitchScreen.fromJson(Map<String, dynamic> json) {
    return StitchScreen(
      id: json['name']?.split('/').last ?? '',
      displayName: json['display_name'] ?? '',
      imageUrl: json['image_uri'], // Or however it's returned
      code: json['code_content'], // Hypothetical field
      createTime: DateTime.parse(json['create_time']),
      updateTime: DateTime.parse(json['update_time']),
    );
  }
}

class DesignContext {
  final String projectId;
  final String screenId;
  final Map<String, dynamic> styles;
  final Map<String, dynamic> components;

  DesignContext({
    required this.projectId,
    required this.screenId,
    required this.styles,
    required this.components,
  });

  factory DesignContext.fromJson(Map<String, dynamic> json) {
    return DesignContext(
      projectId: json['project_id'] ?? '',
      screenId: json['screen_id'] ?? '',
      styles: json['styles'] ?? {},
      components: json['components'] ?? {},
    );
  }
}

class SiteBuild {
  final String operationName;
  final String status;
  final String? siteUrl;

  SiteBuild({
    required this.operationName,
    required this.status,
    this.siteUrl,
  });

  factory SiteBuild.fromJson(Map<String, dynamic> json) {
    return SiteBuild(
      operationName: json['name'] ?? '',
      status: json['status'] ?? 'unknown',
      siteUrl: json['site_url'],
    );
  }
}
