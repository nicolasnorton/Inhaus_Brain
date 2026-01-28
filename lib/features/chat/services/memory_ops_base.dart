import 'package:flutter/foundation.dart';

abstract class MemoryOpsBase {
  Future<void> init();
  Future<String> read();
  Future<void> append(String section, String content);
}

// Factory to get the right implementation
class MemoryOps {
  static MemoryOpsBase create() {
    // We would use conditional imports here, but for now we'll use a simpler approach
    // or provide the concrete class directly in a platform-specific file.
    throw UnimplementedError('Use conditional exports instead');
  }
}
