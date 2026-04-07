import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yaml/yaml.dart';
import '../../../core/mcp/agent_tool.dart';
import '../../../core/security/skill_vulnerability_scanner.dart';
import '../models/skill_models.dart';
// Note: We use a deferred or conditional check for IO logic to avoid web crashes
import 'skill_discovery_io.dart' if (dart.library.js_interop) 'skill_discovery_web_stub.dart';

class SkillDiscoveryService {
  final List<AgentSkill> _skills = [];
  
  List<AgentSkill> get skills => List.unmodifiable(_skills);

  Future<void> discoverSkills(String baseDir) async {
    if (kIsWeb) {
      debugPrint('SkillDiscoveryService: File system discovery not supported on web.');
      return;
    }
    
    _skills.clear();
    final discovered = await SkillDiscoveryIO.discover(baseDir, _parseSkillFile);
    _skills.addAll(discovered);
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
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
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

    // ── Phase 6: Security Scan ──
    final scanResult = await SkillVulnerabilityScanner.scan(
      skillName: name,
      skillContent: foundSkill.instructions,
      ref: ref,
    );

    if (!scanResult.isSafe) {
      debugPrint('ActivateSkillTool: BLOCKED "$name" — ${scanResult.reason}');
      return ToolResult.failure(
        'Security scan BLOCKED skill "$name": ${scanResult.reason}\n'
        'Detected patterns: ${scanResult.detectedPatterns.join(', ')}',
      );
    }

    return ToolResult.success({
      'instructions': foundSkill.instructions,
      'message': 'Skill "$name" activated (security scan passed). Follow the instructions provided below.',
    });
  }
}

class LoadSkillResourceTool extends AgentTool {
  final SkillDiscoveryService _skillService;

  LoadSkillResourceTool(this._skillService)
      : super(
          name: 'load_skill_resource',
          description: 'Load a specific resource (document, script, or asset) from an activated skill.',
          inputSchema: {
            'skillName': {
              'type': 'string',
              'description': 'The name of the skill.',
            },
            'resourcePath': {
              'type': 'string',
              'description': 'The relative path to the resource (e.g., "references/FORMS.md").',
            },
          },
        );

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters, {dynamic ref}) async {
    final name = parameters['skillName'] as String?;
    final resourcePath = parameters['resourcePath'] as String?;
    
    if (name == null || resourcePath == null) {
      return ToolResult.failure('Missing skillName or resourcePath parameter.');
    }

    AgentSkill? foundSkill;
    try {
      foundSkill = _skillService.skills.firstWhere((s) => s.name == name);
    } catch (_) {
      foundSkill = null;
    }

    if (foundSkill == null) {
      return ToolResult.failure('Skill "$name" not found.');
    }

    if (kIsWeb) {
      return ToolResult.failure('Loading resources from file system is not supported on web.');
    }

    try {
      final content = await SkillDiscoveryIO.readResource(foundSkill.path, resourcePath);
      if (content == null) {
        return ToolResult.failure('Resource "$resourcePath" not found in skill "$name".');
      }
      return ToolResult.success({
        'content': content,
        'message': 'Resource "$resourcePath" loaded successfully.',
      });
    } catch (e) {
      return ToolResult.failure('Failed to read resource: $e');
    }
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
    LoadSkillResourceTool(skillService),
  ];
});
