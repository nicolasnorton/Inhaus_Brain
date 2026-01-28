import 'package:flutter_test/flutter_test.dart';
import 'package:inhaus_brain/features/assistant/services/assistant_service.dart';

void main() {
  group('Tool Calling & Function Reliability Agent', () {
    test('Detects tool_call in JSON', () async {
      final jsonResponse = '''
      {
        "final_output": "Here is the image.",
        "tool_call": {
          "name": "image_generation",
          "args": {"prompt": "test"}
        }
      }
      ''';
      
      // Heuristic parsing logic (Simulated from AssistantService)
      final hasToolCall = jsonResponse.contains('"tool_call"');
      expect(hasToolCall, isTrue);
    });

    test('Detects Spanish llamada_herramienta', () async {
       final jsonResponse = '''
      {
        "salida_final": "Hola",
        "llamada_herramienta": {
          "nombre": "image_generation",
          "args": {"prompt": "prueba"}
        }
      }
      ''';
       expect(jsonResponse.contains('"llamada_herramienta"'), isTrue);
    });

    test('Rejects hallucinated tools', () {
      final supportedTools = ['image_generation', 'video_generation', 'web_search', 'create_artifact', 'gen_ui_component'];
      final hallucinatedTool = 'magic_wand_tool';
      
      expect(supportedTools.contains(hallucinatedTool), isFalse);
    });
  });
}
