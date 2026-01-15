import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../features/knowledge/models/knowledge_source.dart';
import '../tokens/llm_provider.dart';
import '../auth/secret_vault_service.dart';

// --- JS Interop for Chrome Prompt API ---
// These will only work on Chrome with experimental flags enabled.
/*
import 'dart:js_interop';

@JS('getAISystemStatus')
external JSPromise getAISystemStatus();

@JS('promptBuiltInAI')
external JSPromise promptBuiltInAI(String query);
*/

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
  static final _vault = SecretVaultService();

  static Future<EdgeAIResult> generateText(
    String prompt, {
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    Uint8List? imageBytes,
    String? imageMimeType,
    Uint8List? audioBytes,
    String? audioMimeType,
    AIModelConfig? modelConfig,
    String? apiKey,
    String? gemmaKey,
    String? openAIKey,
    String? anthropicKey,
    String? xaiKey,
    Ref? ref, // Phase 89: Optional Ref for proximity sync
  }) async {
    final effectivePrompt = _buildPromptWithContext(prompt, context, memoryContext: memoryContext);
    
    final config = modelConfig ?? AIModelConfig.geminiFlash;
    
    debugPrint('EdgeAI: [DEBUG] Generating text via ${config.provider} (${config.modelId})');

    if (forceMock) {
      debugPrint('EdgeAI: [DEBUG] forceMock is TRUE. Returning mock.');
      return await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
    }

    try {
      EdgeAIResult result;
      switch (config.provider) {
        case AIProvider.gemini:
          final vaultKey = await _vault.getGeminiKey();
          final key = apiKey ?? vaultKey;
          
          if (key == null || key.trim().isEmpty) {
            debugPrint('EdgeAI: [DEBUG] Gemini Key is NULL or EMPTY. Triggering fallback to mock.');
            result = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
          } else {
            try {
              result = await _generateGemini(effectivePrompt, config, key, imageBytes, imageMimeType, audioBytes, audioMimeType);
            } catch (e) {
              debugPrint('EdgeAI: [DEBUG] Primary Gemini model (${config.modelId}) failed: $e');
              try {
                // FALLBACK: Try gemini-pro (v1.0) if Flash fails
                final fallbackConfig = AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-pro');
                result = await _generateGemini(effectivePrompt, fallbackConfig, key, imageBytes, imageMimeType, audioBytes, audioMimeType);
              } catch (fallbackError) {
                 debugPrint('EdgeAI: [DEBUG] Fallback Gemini model also failed: $fallbackError');
                 rethrow; // Re-throw to trigger outer catch and potential mock fallback
              }
            }
          }
          break;
        case AIProvider.openai:
          final key = openAIKey ?? await _vault.getOpenAIKey();
          debugPrint('EdgeAI: [DEBUG] OpenAI Key found: ${key != null && key.isNotEmpty}');
          if (key == null || key.isEmpty) {
             result = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
          } else {
             result = await _generateOpenAI(effectivePrompt, config, key, imageBytes, imageMimeType);
          }
          break;
        case AIProvider.claude:
          final key = anthropicKey ?? await _vault.getAnthropicKey();
          debugPrint('EdgeAI: [DEBUG] Claude Key found: ${key != null && key.isNotEmpty}');
          if (key == null || key.isEmpty) {
             result = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
          } else {
             result = await _generateClaude(effectivePrompt, config, key, imageBytes, imageMimeType);
          }
          break;
        case AIProvider.grok:
          final key = xaiKey ?? await _vault.getXAIKey();
          debugPrint('EdgeAI: [DEBUG] Grok Key found: ${key != null && key.isNotEmpty}');
          if (key == null || key.isEmpty) {
             result = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
          } else {
             result = await _generateGrok(effectivePrompt, config, key);
          }
          break;
        default:
          debugPrint('EdgeAI: [DEBUG] Unknown provider ${config.provider}. Returning mock.');
          result = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
      }
      
      // Phase 89: Global Proximity Sync (Only if ref is provided)
      if (ref != null) {
        ref.read(aiProximityProvider.notifier).setProximity(result.proximity);
      }
      
      return result;
    } catch (e) {
      debugPrint('EdgeAI: [DEBUG] ERROR during ${config.provider} generation: $e');
      final mockRes = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
      if (ref != null) {
        ref.read(aiProximityProvider.notifier).setProximity(mockRes.proximity);
      }
      return mockRes;
    }
  }

  // --- PROVIDER IMPLEMENTATIONS ---

  static Future<EdgeAIResult> _generateGemini(
    String prompt, 
    AIModelConfig config, 
    String? apiKey, 
    Uint8List? imageBytes,
    String? mimeType,
    Uint8List? audioBytes,
    String? audioMimeType
  ) async {
    if (apiKey == null || apiKey.isEmpty) throw Exception("Gemini API Key missing");

    final model = GenerativeModel(model: config.modelId, apiKey: apiKey);
    final List<Part> parts = [TextPart(prompt)];
    
    if (imageBytes != null) {
      parts.add(DataPart(mimeType ?? 'image/jpeg', imageBytes));
    }

    if (audioBytes != null) {
      parts.add(DataPart(audioMimeType ?? 'audio/mp3', audioBytes));
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

    final response = await http.post(
      Uri.parse('https://api.x.ai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": config.modelId,
        "messages": [
          {"role": "system", "content": "You are Grok, a conversational AI developed by xAI."},
          {"role": "user", "content": prompt}
        ],
        "temperature": config.temperature,
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

  static Future<String> generateImage(String prompt, {String? imagenKey, String? bananaKey, String? midjourneyKey, String? runwayKey}) async {
    final isNanoBanana = prompt.toLowerCase().contains('banana') || (bananaKey != null && bananaKey.isNotEmpty);
    
    if (midjourneyKey != null && midjourneyKey.isNotEmpty) {
       await Future.delayed(const Duration(seconds: 4));
       return "https://via.placeholder.com/1024x1024.png?text=Midjourney+v6"; 
    }
    if (imagenKey != null && imagenKey.isNotEmpty || isNanoBanana) {
      // Use Vertex AI Imagen 3 (requires Access Token as 'imagenKey' for now, or Service Account via proxy)
      // Assuming 'imagenKey' is a valid Google Cloud Access Token or API Key with sufficient scope.
      // If it's an API Key (AIStudio), it might not work for Imagen yet.
      // For this implementation, we assume the user provides a Bearer Token or we use a REST proxy.
      // Given the constraints, we will TRY to call the Vertex AI REST endpoint if the key looks like a token.
      
      if (imagenKey!.startsWith('ya29')) { // Typical Google Access Token prefix
         try {
           return await _generateVertexImagen(prompt, imagenKey);
         } catch (e) {
           debugPrint('Vertex Imagen failed: $e. Falling back to Pollinations.');
         }
      } else {
         // Fallback/Simulated for standard API keys or placeholder
         await Future.delayed(const Duration(seconds: 2));
         // If they have an API key but not a token, we can't easily call Vertex directly from client.
         // We'll log this limitation.
         debugPrint('Imagen Key provided but logic requires Access Token for Vertex AI. Using Pollinations fallback.');
      }
    }

    // POLLINATIONS.AI FALLBACK
    // Use Pollinations.ai for free, high-quality, dynamic image generation without an API key.
    // We use a random seed to ensure uniqueness for repeated prompts.
    final seed = DateTime.now().millisecondsSinceEpoch;
    
    // Truncate prompt deeply to avoid "URI Too Long" or "Forbidden" issues.
    // We only keep alphanumeric and spaces to be ultra-safe.
    String safePrompt = prompt.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
    if (safePrompt.length > 100) {
      safePrompt = safePrompt.substring(0, 100); 
    }
    
    final encodedPrompt = Uri.encodeComponent(safePrompt);
    return "https://image.pollinations.ai/prompt/$encodedPrompt?width=1024&height=1024&seed=$seed&model=flux"; 
  }

  static Future<String> _generateVertexImagen(String prompt, String accessToken) async {
    // Requires PROJECT_ID. Since we don't have it injected, we might need to ask or use a default.
    // For now, we'll try to find it in the vault or use a placeholder which will fail if invalid.
    String projectId = 'inhausbrain'; // Default from user context
    
    final url = Uri.parse('https://us-central1-aiplatform.googleapis.com/v1/projects/$projectId/locations/us-central1/publishers/google/models/imagegeneration:predict');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "instances": [
          {"prompt": prompt}
        ],
        "parameters": {
          "sampleCount": 1,
          "aspectRatio": "1:1"
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Vertex AI Image generation response structure
      // predictions[0].bytesBase64Encoded
      final base64Image = data['predictions'][0]['bytesBase64Encoded'];
      return "data:image/png;base64,$base64Image";
    } else {
      throw Exception('Vertex AI Error: ${response.statusCode} ${response.body}');
    }
  }

  static Future<String> generateVideo(String prompt, {String? veoKey, String? runwayKey}) async {
    final isVeo = prompt.toLowerCase().contains('veo') || (veoKey != null && veoKey.isNotEmpty);
    
    if (runwayKey != null && runwayKey.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 5));
      return "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4";
    }
    if (isVeo) {
       await Future.delayed(const Duration(seconds: 3));
       return "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4"; // Placeholder for Veo
    }
    return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  }

  static Future<String> generateAudio(String prompt, {String? lyriaKey}) async {
    // Phase 89: Mock/Simulate Lyria
    await Future.delayed(const Duration(seconds: 3));
    return "assets/audio/mock_soundtrack.mp3"; 
  }

  static Stream<EdgeAIResult> generateTextStream(
    String prompt, {
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    Uint8List? imageBytes,
    String? imageMimeType,
    Uint8List? audioBytes,
    String? audioMimeType,
    AIModelConfig? config,
    String? apiKey,
    Ref? ref, // Phase 89: For proximity sync
  }) async* {
    if (config?.provider == AIProvider.gemini) {
       final key = apiKey ?? await _vault.getGeminiKey();
       if (key != null) {
          final effectivePrompt = _buildPromptWithContext(prompt, context, memoryContext: memoryContext);
          final model = GenerativeModel(model: config!.modelId, apiKey: key);
          final List<Part> parts = [TextPart(effectivePrompt)];
          if (imageBytes != null) {
            parts.add(DataPart(imageMimeType ?? 'image/jpeg', imageBytes));
          }
          if (audioBytes != null) {
            parts.add(DataPart(audioMimeType ?? 'audio/mp3', audioBytes));
          }
          final content = [Content.multi(parts)];
          final responseStream = model.generateContentStream(content);
          await for (final chunk in responseStream) {
            if (chunk.text != null) {
              if (ref != null) ref.read(aiProximityProvider.notifier).setProximity(AIProximity.cloud);
              yield EdgeAIResult(chunk.text!, AIProximity.cloud);
            }
          }
          return;
       }
    }
    
    yield EdgeAIResult("Thinking via ${config?.displayName ?? 'Edge Mock'}...", AIProximity.simulated);
    final result = await generateText(prompt, context: context, memoryContext: memoryContext, imageBytes: imageBytes, imageMimeType: imageMimeType, modelConfig: config, apiKey: apiKey, ref: ref);
    yield result;
  }

  static Future<EdgeAIResult> _generateLocalMock(String prompt, {bool hasImage = false}) async {
    await Future.delayed(const Duration(milliseconds: 800));
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
}
