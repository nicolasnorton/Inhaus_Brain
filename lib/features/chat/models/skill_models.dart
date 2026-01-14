import 'package:flutter/foundation.dart';

@immutable
class AgentSkill {
  final String name;
  final String description;
  final String? license;
  final String? compatibility;
  final Map<String, String> metadata;
  final List<String> allowedTools;
  final String instructions; // The Markdown body
  final String path; // Absolute path to the skill directory

  const AgentSkill({
    required this.name,
    required this.description,
    this.license,
    this.compatibility,
    this.metadata = const {},
    this.allowedTools = const [],
    required this.instructions,
    required this.path,
  });

  factory AgentSkill.fromYamlAndMarkdown(Map<String, dynamic> yaml, String markdown, String path) {
    return AgentSkill(
      name: yaml['name'] as String,
      description: yaml['description'] as String,
      license: yaml['license'] as String?,
      compatibility: yaml['compatibility'] as String?,
      metadata: Map<String, String>.from(yaml['metadata'] ?? {}),
      allowedTools: (yaml['allowed-tools'] as String?)?.split(' ') ?? [],
      instructions: markdown,
      path: path,
    );
  }

  String toXmlMetadata() {
    return '''
  <skill>
    <name>$name</name>
    <description>$description</description>
    <location>$path/SKILL.md</location>
  </skill>''';
  }
}
