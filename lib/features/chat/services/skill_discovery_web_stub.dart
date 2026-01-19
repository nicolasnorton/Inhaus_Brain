import '../models/skill_models.dart';

class SkillDiscoveryIO {
  static Future<List<AgentSkill>> discover(String baseDir, AgentSkill Function(String content, String path) parser) async {
    return []; // No-op for web
  }

  static Future<String?> readResource(String skillPath, String resourcePath) async {
    return null;
  }
}
