import 'dart:js_interop';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../features/knowledge/models/knowledge_source.dart';
import '../tokens/llm_provider.dart';

@JS('getAISystemStatus')
external JSPromise getAISystemStatus();

@JS('promptBuiltInAI')
external JSPromise promptBuiltInAI(String query);

enum AIProximity {
  local,     // Chrome Prompt API or Gemini Nano
  cloud,     // Vertex AI, OpenAI, Claude, Grok
  simulated  // Dynamic Edge Mock
}

class AIProximityNotifier extends Notifier<AIProximity> {
  @override
  AIProximity build() => AIProximity.simulated;

  void setProximity(AIProximity proximity) {
    state = proximity;
  }
}

final aiProximityProvider = NotifierProvider<AIProximityNotifier, AIProximity>(AIProximityNotifier.new);

class EdgeAIResult {
  final String text;
  final AIProximity proximity;
  final String? modelUsed;

  EdgeAIResult(this.text, this.proximity, {this.modelUsed});
}

class EdgeAIService {
  static bool forceMock = false;

  static Future<EdgeAIResult> generateText(
    String prompt, {
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    Uint8List? imageBytes,
    String? imageMimeType,
    AIModelConfig? modelConfig, // Phase 35: Config Override
    String? apiKey,
    String? gemmaKey,   // Legacy: Map to config
    String? openAIKey,  // Phase 35
    String? anthropicKey, // Phase 35
    String? xaiKey,     // Phase 35
  }) async {
    final effectivePrompt = _buildPromptWithContext(prompt, context, memoryContext: memoryContext);
    
    // Default to Gemini Flash if no config provided
    final config = modelConfig ?? AIModelConfig.geminiFlash;
    
    debugPrint('EdgeAI: Generating text via ${config.displayName}...');

    if (forceMock) {
      return await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
    }

    try {
      switch (config.provider) {
        case AIProvider.gemini:
          return await _generateGemini(effectivePrompt, config, apiKey, imageBytes, imageMimeType);
        case AIProvider.openai:
          return await _generateOpenAI(effectivePrompt, config, openAIKey, imageBytes, imageMimeType);
        case AIProvider.claude:
          return await _generateClaude(effectivePrompt, config, anthropicKey, imageBytes, imageMimeType);
        case AIProvider.grok:
          return await _generateGrok(effectivePrompt, config, xaiKey); // Grok 1 is text-only public API for now
        case AIProvider.mistral:
          // Placeholder structure
          return await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null); 
        default:
          return await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
      }
    } catch (e) {
      debugPrint('EdgeAI Error (${config.provider}): $e. Falling back to Local Mock.');
      return await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
    }
  }

  // --- PROVIDER IMPLEMENTATIONS ---

  static Future<EdgeAIResult> _generateGemini(
    String prompt, 
    AIModelConfig config, 
    String? apiKey, 
    Uint8List? imageBytes,
    String? mimeType
  ) async {
    if (apiKey == null || apiKey.isEmpty) throw Exception("Gemini API Key missing");

    final model = GenerativeModel(model: config.modelId, apiKey: apiKey);
    final List<Part> parts = [TextPart(prompt)];
    
    if (imageBytes != null) {
      parts.add(DataPart(mimeType ?? 'image/jpeg', imageBytes));
    }

    final content = [Content.multi(parts)];
    final response = await model.generateContent(content);
    
    return EdgeAIResult(response.text ?? "No response", AIProximity.cloud, modelUsed: config.modelId);
  }

  static Future<EdgeAIResult> _generateOpenAI(
    String prompt, 
    AIModelConfig config, 
    String? apiKey, 
    Uint8List? imageBytes, 
    String? mimeType
  ) async {
    if (apiKey == null || apiKey.isEmpty) throw Exception("OpenAI API Key missing");

    final messages = <Map<String, dynamic>>[];
    
    // Vision Support for GPT-4o
    if (imageBytes != null) {
      final base64Image = base64Encode(imageBytes);
      messages.add({
        "role": "user",
        "content": [
          {"type": "text", "text": prompt},
          {
            "type": "image_url",
            "image_url": {
              "url": "data:${mimeType ?? 'image/jpeg'};base64,$base64Image"
            }
          }
        ]
      });
    } else {
      messages.add({"role": "user", "content": prompt});
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": config.modelId,
        "messages": messages,
        "temperature": config.temperature,
        "max_tokens": config.maxTokens ?? 2048,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return EdgeAIResult(content, AIProximity.cloud, modelUsed: config.modelId);
    } else {
      throw Exception('OpenAI Error: ${response.body}');
    }
  }

  static Future<EdgeAIResult> _generateClaude(
    String prompt, 
    AIModelConfig config, 
    String? apiKey, 
    Uint8List? imageBytes, 
    String? mimeType
  ) async {
    if (apiKey == null || apiKey.isEmpty) throw Exception("Anthropic API Key missing");

    final messages = <Map<String, dynamic>>[];
    
    if (imageBytes != null) {
      final base64Image = base64Encode(imageBytes);
      messages.add({
        "role": "user",
        "content": [
          {
            "type": "image",
            "source": {
              "type": "base64",
              "media_type": mimeType ?? 'image/jpeg',
              "data": base64Image
            }
          },
          {"type": "text", "text": prompt}
        ]
      });
    } else {
       messages.add({"role": "user", "content": prompt});
    }

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        "model": config.modelId,
        "max_tokens": config.maxTokens ?? 2048,
        "messages": messages,
        "temperature": config.temperature,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'];
      return EdgeAIResult(content, AIProximity.cloud, modelUsed: config.modelId);
    } else {
      throw Exception('Anthropic Error: ${response.body}');
    }
  }

  static Future<EdgeAIResult> _generateGrok(
    String prompt, 
    AIModelConfig config, 
    String? apiKey
  ) async {
    if (apiKey == null || apiKey.isEmpty) throw Exception("xAI API Key missing");

    // Grok uses OpenAI-compatible API
    final response = await http.post(
      Uri.parse('https://api.x.ai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": config.modelId, // e.g. "grok-beta"
        "messages": [
          {"role": "system", "content": "You are Grok, a conversational AI developed by xAI."},
          {"role": "user", "content": prompt}
        ],
        "temperature": config.temperature,
         // xAI specific params might go here
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return EdgeAIResult(content, AIProximity.cloud, modelUsed: config.modelId);
    } else {
      throw Exception('Grok Error: ${response.body}');
    }
  }

  // --- LEGACY MOCK & HELPERS ---

  static Future<String> generateImage(String prompt, {String? imagenKey, String? bananaKey, String? midjourneyKey, String? runwayKey}) async {
    // Phase 35: Mock Midjourney/Runway Logic
    if (midjourneyKey != null && midjourneyKey.isNotEmpty) {
       await Future.delayed(const Duration(seconds: 4));
       return "https://via.placeholder.com/1024x1024.png?text=Midjourney+v6"; 
    }
    if (imagenKey != null && imagenKey.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      return "https://via.placeholder.com/1024x1024.png?text=Imagen+3+Generated+Art";
    }
    // ...
    return "assets/images/mock_concept.png"; 
  }

  static Future<String> generateVideo(String prompt, {String? veoKey, String? runwayKey}) async {
    if (runwayKey != null && runwayKey.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 5));
      return "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4"; // Runway Mock
    }
    // ...
    return "assets/videos/mock_render.mp4";
  }

  static Stream<EdgeAIResult> generateTextStream(
    String prompt, {
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    Uint8List? imageBytes,
    String? imageMimeType,
    AIModelConfig? config,
    String? apiKey,
    // Add logic for streaming later (Gemini already supports it, OpenAI/Claude support SSE)
  }) async* {
    // For now, fallback to non-streaming for non-Gemini or mock
    if (config?.provider == AIProvider.gemini && apiKey != null) {
       // ... existing Gemini logic ...
       final effectivePrompt = _buildPromptWithContext(prompt, context, memoryContext: memoryContext);
       final model = GenerativeModel(model: config!.modelId, apiKey: apiKey);
        final List<Part> parts = [TextPart(effectivePrompt)];
        if (imageBytes != null) {
          parts.add(DataPart(imageMimeType ?? 'image/jpeg', imageBytes));
        }
        final content = [Content.multi(parts)];
        final responseStream = model.generateContentStream(content);
        await for (final chunk in responseStream) {
          if (chunk.text != null) yield EdgeAIResult(chunk.text!, AIProximity.cloud);
        }
    } else {
      // Simulate streaming for others/mock
      yield EdgeAIResult("Thinking via ${config?.displayName ?? 'Edge Mock'}...", AIProximity.simulated);
      final result = await generateText(prompt, context: context, memoryContext: memoryContext, imageBytes: imageBytes, imageMimeType: imageMimeType, modelConfig: config, apiKey: apiKey);
      yield result; // Return full block for now
    }
  }

  // Same helper methods as before...
  static Future<EdgeAIResult> _generateLocalMock(String prompt, {bool hasImage = false}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Finalize mock response
    
    // Simulate simple responses
    return EdgeAIResult("Edge Mock: Analyzed '$prompt' locally.", AIProximity.simulated);
  }

  static String _buildPromptWithContext(String prompt, List<KnowledgeSource> context, {String? memoryContext}) {
    final buffer = StringBuffer();
    if (memoryContext != null && memoryContext.isNotEmpty) {
      buffer.writeln(memoryContext);
      buffer.writeln('-----------------------------------');
    }
    if (context.isNotEmpty) {
      buffer.writeln('CONTEXT FROM KNOWLEDGE BASE:');
      for (final source in context) {
        buffer.writeln('${source.title}: ${source.content.length > 200 ? source.content.substring(0,200) : source.content}...');
      }
    }
    buffer.writeln('\nUSER PROMPT: $prompt');
    return buffer.toString();
  }
  
  static Future<String> generateAudio(String prompt, {String? lyriaKey}) async {
    // ...
    return "assets/audio/mock_soundtrack.mp3"; 
  }
}

