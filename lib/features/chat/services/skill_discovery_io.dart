import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';
import '../models/skill_models.dart';

class SkillDiscoveryIO {
  static Future<List<AgentSkill>> discover(String baseDir, AgentSkill Function(String content, String path) parser) async {
    final dir = Directory(baseDir);
    if (!await dir.exists()) {
      debugPrint('SkillDiscoveryIO: Base directory $baseDir does not exist.');
      return [];
    }

    final List<AgentSkill> skills = [];
    final entities = await dir.list().toList();
    for (final entity in entities) {
      if (entity is Directory) {
        final skillFile = File('${entity.path}/SKILL.md');
        if (await skillFile.exists()) {
          try {
            final content = await skillFile.readAsString();
            final skill = parser(content, entity.path);
            skills.add(skill);
          } catch (e) {
            debugPrint('SkillDiscoveryIO: Error parsing ${skillFile.path}: $e');
          }
        }
      }
    }
    return skills;
  }
  static Future<String?> readResource(String skillPath, String resourcePath) async {
    final file = File('$skillPath/$resourcePath');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }
}
