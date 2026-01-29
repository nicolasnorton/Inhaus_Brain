import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/core/services/video_generation_service.dart';
import 'package:inhaus_brain/core/services/ai_proxy_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mock with: flutter pub run build_runner build
// For now, we manually mock since we can't easily run build_runner here.

class MockAIProxyService {
  static Map<String, dynamic> nextContentResponse = {};
  static Map<String, dynamic> nextPollResponse = {};
}

void main() {
  group('VideoGenerationService Tests', () {
    test('generatePreview (Mock/LiteRT) completes rapidly (<2s)', () async {
       final stopwatch = Stopwatch()..start();
       await VideoGenerationService.generatePreview("cat");
       stopwatch.stop();

       // Should be around 1.0s (10 * 100ms) + overhead. 
       // Assert it is definitely faster than the old 3s.
       expect(stopwatch.elapsedMilliseconds, lessThan(2000), reason: "Preview generation too slow for LiteRT experience");
    });
  });
}
