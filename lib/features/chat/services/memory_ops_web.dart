import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'memory_ops_base.dart';

class MemoryOpsImpl implements MemoryOpsBase {
  @override
  Future<void> init() async {
    // SharedPreferences handles its own init
  }

  @override
  Future<String> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('external_memory') ?? "# Inhaus Brain External Memory\n\n## Initialized (Web)\n";
  }

  @override
  Future<void> append(String section, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await read();
    final newEntry = "\n\n## $section (${DateTime.now().toIso8601String()})\n$content";
    await prefs.setString('external_memory', current + newEntry);
  }
}
