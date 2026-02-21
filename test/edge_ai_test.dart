
import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/core/services/edge_ai_service.dart';
import 'package:inhaus_brain/core/tokens/llm_provider.dart';

void main() {
  group('Edge AI Service Tests', () {
    test('LiteRT Initialization', () async {
      await EdgeAIService.initLiteRT();
      // Since it's a static state, we can't easily check internal boolean without reflection or helper
      // But we can check if generation works without error
      final result = await EdgeAIService.generateText(
        "Test Prompt", 
        modelConfig: AIModelConfig.gemma2n
      );
      
      expect(result.proximity, AIProximity.local);
      expect(result.modelUsed, contains('gemma-2b-it-gpu'));
      expect(result.text, contains("LiteRT"));
    });

    // test('Video Preview uses LiteRT config', () {
    //   final config = AIModelConfig.veoFastPreview;
    //   expect(config.provider, AIProvider.litert);
    //   expect(config.modelId, 'veo-3-fast-preview');
    // });

    test('Output Polish uses LiteRT Gemma', () async {
       // This test mocks the integration ensuring the constant is correct
       final config = AIModelConfig.gemma2n;
       expect(config.provider, AIProvider.litert);
    });
  });
}
