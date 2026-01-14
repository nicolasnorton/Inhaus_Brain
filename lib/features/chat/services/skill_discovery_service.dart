import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml/yaml.dart';
import '../../../core/mcp/agent_tool.dart';
import '../models/skill_models.dart';

class SkillDiscoveryService {
  final List<AgentSkill> _skills = [];
  
  List<AgentSkill> get skills => List.unmodifiable(_skills);

  Future<void> discoverSkills(String baseDir) async {
    final dir = Directory(baseDir);
    if (!await dir.exists()) {
      debugPrint('SkillDiscoveryService: Base directory $baseDir does not exist.');
      return;
    }

    _skills.clear();
    final entities = await dir.list().toList();
    for (final entity in entities) {
      if (entity is Directory) {
        final skillFile = File('${entity.path}/SKILL.md');
        if (await skillFile.exists()) {
          try {
            final content = await skillFile.readAsString();
            final skill = _parseSkillFile(content, entity.path);
            _skills.add(skill);
          } catch (e) {
            debugPrint('SkillDiscoveryService: Error parsing ${skillFile.path}: $e');
          }
        }
      }
    }
  }

  AgentSkill _parseSkillFile(String content, String path) {
    if (!content.trim().startsWith('---')) {
      throw const FormatException('SKILL.md must start with YAML frontmatter');
    }

    final parts = content.split('---');
    if (parts.length < 3) {
      throw const FormatException('Invalid SKILL.md format. Missing frontmatter closing ---');
    }

    final yamlStr = parts[1];
    final markdown = parts.sublist(2).join('---').trim();

    final yamlMap = loadYaml(yamlStr) as YamlMap;
    return AgentSkill.fromYamlAndMarkdown(
      Map<String, dynamic>.from(yamlMap),
      markdown,
      path,
    );
  }

  String generateAvailableSkillsXml() {
    if (_skills.isEmpty) return '';

    final skillXmls = _skills.map((s) => s.toXmlMetadata()).join('\n');
    return '''
<available_skills>
$skillXmls
</available_skills>''';
  }
}

class ActivateSkillTool extends AgentTool {
  final SkillDiscoveryService _skillService;

  ActivateSkillTool(this._skillService)
      : super(
          name: 'activate_skill',
          description: 'Load full instructions for an available skill. Use this when a task matches one of your available skills.',
          inputSchema: {
            'skillName': {
              'type': 'string',
              'description': 'The name of the skill to activate.',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    final name = parameters['skillName'] as String?;
    if (name == null) return ToolResult.failure('Missing skillName parameter.');

    AgentSkill? foundSkill;
    try {
      foundSkill = _skillService.skills.firstWhere((s) => s.name == name);
    } catch (_) {
      foundSkill = null;
    }

    if (foundSkill == null) {
      return ToolResult.failure('Skill "$name" not found among available skills.');
    }

    return ToolResult.success({
      'instructions': foundSkill.instructions,
      'message': 'Skill "$name" activated. Please follow the instructions provided below.',
    });
  }
}

final skillDiscoveryServiceProvider = Provider<SkillDiscoveryService>((ref) => SkillDiscoveryService());

final skillDiscoveryInitProvider = FutureProvider<void>((ref) async {
  final skillService = ref.read(skillDiscoveryServiceProvider);
  // In dynamic environments, this path could be from a settings vault
  await skillService.discoverSkills('lib/features/chat/skills');
});

final skillToolsProvider = Provider<List<AgentTool>>((ref) {
  final skillService = ref.watch(skillDiscoveryServiceProvider);
  return [
    ActivateSkillTool(skillService),
  ];
});
