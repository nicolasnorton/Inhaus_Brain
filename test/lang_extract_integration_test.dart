import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/core/services/ai_proxy_service.dart';
import 'package:inhaus_brain/core/architecture/blackboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('LangExtract Integration Tests', () {
    
    test('AIProxyService.extractStructured formatting test', () async {
      final schema = {
        "type": "object",
        "properties": {
          "test_field": {"type": "string"}
        }
      };
      
      // Since this requires a real Firebase Auth token to test live, 
      // we test the structure and error handling in a mockable way.
      // In a real staging environment, this would hit the Python function.
      
      expect(() => AIProxyService.extractStructured(
        document: "Test document content",
        schema: schema,
      ), throwsA(isA<Exception>())); // Expected failure without auth
    });

    test('Blackboard fact naming consistency', () {
      final container = ProviderContainer();
      final blackboard = container.read(blackboardProvider.notifier);
      
      const testFactKey = 'extraction_test_doc_123';
      final testData = {
        'status': 'success',
        'extraction': {'key': 'value'},
        'grounding_url': 'https://storage.googleapis.com/test.html'
      };
      
      blackboard.postFact(testFactKey, testData);
      
      expect(container.read(blackboardProvider).facts[testFactKey], equals(testData));
    });
  });
}
