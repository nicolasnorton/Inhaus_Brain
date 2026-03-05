// Data models for Figma REST API integration.
//
// These models represent the JSON structures returned by
// the Figma REST API v1 (https://www.figma.com/developers/api).

class FigmaFile {
  final String key;
  final String name;
  final String lastModified;
  final String thumbnailUrl;
  final String version;
  final Map<String, dynamic> document;
  final Map<String, dynamic> styles;

  const FigmaFile({
    required this.key,
    required this.name,
    required this.lastModified,
    required this.thumbnailUrl,
    required this.version,
    required this.document,
    required this.styles,
  });

  factory FigmaFile.fromJson(Map<String, dynamic> json) {
    return FigmaFile(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lastModified: json['lastModified'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      version: json['version'] as String? ?? '',
      document: json['document'] as Map<String, dynamic>? ?? {},
      styles: json['styles'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'lastModified': lastModified,
        'thumbnailUrl': thumbnailUrl,
        'version': version,
        'document': document,
        'styles': styles,
      };
}

class FigmaNode {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> properties;
  final List<FigmaNode> children;

  const FigmaNode({
    required this.id,
    required this.name,
    required this.type,
    required this.properties,
    this.children = const [],
  });

  factory FigmaNode.fromJson(Map<String, dynamic> json) {
    return FigmaNode(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      properties: Map<String, dynamic>.from(json)
        ..removeWhere((k, _) => ['id', 'name', 'type', 'children'].contains(k)),
      children: (json['children'] as List?)
              ?.map((c) => FigmaNode.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FigmaProject {
  final String id;
  final String name;

  const FigmaProject({required this.id, required this.name});

  factory FigmaProject.fromJson(Map<String, dynamic> json) {
    return FigmaProject(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class FigmaFileRef {
  final String key;
  final String name;
  final String thumbnailUrl;
  final String lastModified;

  const FigmaFileRef({
    required this.key,
    required this.name,
    required this.thumbnailUrl,
    required this.lastModified,
  });

  factory FigmaFileRef.fromJson(Map<String, dynamic> json) {
    return FigmaFileRef(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      lastModified: json['last_modified'] as String? ?? '',
    );
  }
}

class FigmaExportResult {
  final String nodeId;
  final List<String> imageUrls;

  const FigmaExportResult({required this.nodeId, required this.imageUrls});

  factory FigmaExportResult.fromImageMap(Map<String, dynamic> images) {
    final entries = images.entries.toList();
    if (entries.isEmpty) {
      return const FigmaExportResult(nodeId: '', imageUrls: []);
    }
    return FigmaExportResult(
      nodeId: entries.first.key,
      imageUrls: entries.map((e) => e.value as String).toList(),
    );
  }
}
