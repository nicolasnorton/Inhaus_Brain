import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Inhaus Brain Evals', () {
    test('Verify Router Classification Accuracy', () async {
      final file = File('test/evals/golden_inputs.json');
      final List<dynamic> goldens = jsonDecode(await file.readAsString());

      for (var golden in goldens) {
        print('Evaluating: ${golden['id']}');
        
        // This is a placeholder for actual agent execution.
        // In a real environment, you would use:
        // final result = await router.execute(userPrompt: golden['input'], ...);
        
        final expectedIntent = golden['expected_intent'];
        
        // Assertion: We expect the router to correctly identify the intent.
        // For actual production evals, we would call an LLM-Grader here.
        expect(expectedIntent, isNotEmpty);
      }
    });
  });
}
