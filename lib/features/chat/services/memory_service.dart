import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'memory_ops_io.dart' if (dart.library.html) 'memory_ops_web.dart';

class MemoryService {
  final _ops = MemoryOps();

  Future<void> init() async {
    await _ops.init();
  }

  Future<String> readMemory() async {
    return await _ops.read();
  }

  Future<void> appendToMemory(String section, String content) async {
    await _ops.append(section, content);
  }
}

final memoryServiceProvider = Provider<MemoryService>((ref) => MemoryService());
