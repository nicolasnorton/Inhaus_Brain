
import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/core/services/orchestrator_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Mock Ref since OrchestratorService needs it
class MockRef extends Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late OrchestratorService service;
  late MockRef mockRef;

  setUp(() {
    mockRef = MockRef();
    service = OrchestratorService(mockRef);
  });

  group('Long-Context & Multi-Turn Robustness', () {
    test('Preserves short context without modification', () {
      final shortContext = "System: Be helpful.\nUser: Hi.";
      expect(service.compressContext(shortContext), equals(shortContext));
    });

    test('Compresses long context correctly', () {
      // Generate a long string > 4000 chars
      final longContext = List.generate(500, (i) => "Line $i: This is a very long history line that needs to be preserved or compressed.").join("\n");
      
      expect(longContext.length, greaterThan(4000));
      
      final compressed = service.compressContext(longContext);
      
      expect(compressed.length, lessThan(longContext.length));
      expect(compressed, contains("[...Orchestrator Note: Middle context compressed"));
      
      // Ensure start and end are preserved
      expect(compressed, startsWith("Line 0:"));
      expect(compressed, endsWith("preserved or compressed."));
    });

    test('Compression retains sufficient context for agency operations', () {
      // Simulation of a brief change mid-conversation
      final part1 = "System: You are an agent.\n" * 100;
      final part2 = "User: Change the brief entirely to focus on Gen Z.\n" * 100;
      final full = part1 + part2;
      
      // Even if compressed, the very last instructions (User's update) must be present
      final compressed = service.compressContext(full);
      
      expect(compressed, contains("Change the brief entirely to focus on Gen Z"));
    });
  });

  group('Multimodal Calibration', () {
    test('Rejects low quality images', () {
      final msg = service.checkMultimodalQuality(0.6, 'image');
      expect(msg, isNotNull);
      expect(msg, contains("would you like me to refine it?"));
    });

    test('Accepts high quality images', () {
      final msg = service.checkMultimodalQuality(0.95, 'image');
      expect(msg, isNull);
    });

    test('Applies stricter threshold for UI', () {
      // UI Threshold is 0.92
      final msg = service.checkMultimodalQuality(0.90, 'ui');
      expect(msg, isNotNull); // 0.90 < 0.92, so should reject
    });
  });
}
