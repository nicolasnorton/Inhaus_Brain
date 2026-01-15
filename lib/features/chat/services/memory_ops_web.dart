import 'package:shared_preferences/shared_preferences.dart';

class MemoryOps {
  static const String _webMemoryKey = 'inhaus_brain_memory';

  Future<void> init() async {}

  Future<String> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_webMemoryKey) ?? "# Inhaus Brain External Memory (Web)\n\n## Initialized\n";
  }

  Future<void> append(String section, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_webMemoryKey) ?? "# Inhaus Brain External Memory (Web)\n\n## Initialized\n";
    final newEntry = "\n\n## $section (${DateTime.now().toIso8601String()})\n$content";
    await prefs.setString(_webMemoryKey, current + newEntry);
  }
}
