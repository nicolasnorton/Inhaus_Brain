import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class MemoryOps {
  File? _memoryFile;

  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _memoryFile = File('${directory.path}/memory.md');
      
      if (!await _memoryFile!.exists()) {
        await _memoryFile!.writeAsString("# Inhaus Brain External Memory\n\n## Initialized\n");
      }
    } catch (e) {
      debugPrint("MemoryOps IO Init Error: $e");
    }
  }

  Future<String> read() async {
    if (_memoryFile == null) await init();
    try {
      return await _memoryFile!.readAsString();
    } catch (e) {
      return "Error reading memory: $e";
    }
  }

  Future<void> append(String section, String content) async {
    if (_memoryFile == null) await init();
    try {
      final current = await read();
      final newEntry = "\n\n## $section (${DateTime.now().toIso8601String()})\n$content";
      await _memoryFile!.writeAsString(current + newEntry);
    } catch (e) {
      debugPrint("Error writing to memory: $e");
    }
  }
}
