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

    final model = GenerativeModel(
      model: config.modelId, 
      apiKey: apiKey,
      tools: [
        Tool(googleSearchRetrieval: GoogleSearchRetrieval(
          dynamicRetrievalConfig: DynamicRetrievalConfig(
            mode: DynamicRetrievalMode.modeDynamic, 
            dynamicThreshold: 0.7
          )
        ))
      ]
    );
    final List<Part> parts = [TextPart(prompt)];
    
    if (imageBytes != null) {
      parts.add(DataPart(mimeType ?? 'image/jpeg', imageBytes));
    }

    if (audioBytes != null) {
      parts.add(DataPart(audioMimeType ?? 'audio/mp3', audioBytes));
    }

    final content = [Content.multi(parts)];
    final response = await model.generateContent(content);
    
    // Check for grounding metadata
    String responseText = response.text ?? "No response";
    if (response.candidates.isNotEmpty && 
        response.candidates.first.groundingMetadata != null) {
        // We could extract sources here if needed, but the model inherently cites them in text
        // or we can parse them from metadata.networkSearchEntry
    }

    return EdgeAIResult(responseText, AIProximity.cloud, modelUsed: config.modelId);
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

  static Future<String> generateImage(String prompt, {String? imagenKey, String? vertexKey, String? bananaKey, String? midjourneyKey, String? runwayKey}) async {
    final isNanoBanana = prompt.toLowerCase().contains('banana') || (bananaKey != null && bananaKey.isNotEmpty);
    
    if (midjourneyKey != null && midjourneyKey.isNotEmpty) {
       await Future.delayed(const Duration(seconds: 4));
       return "https://via.placeholder.com/1024x1024.png?text=Midjourney+v6"; 
    }
    if (imagenKey != null && imagenKey.isNotEmpty || vertexKey != null && vertexKey.isNotEmpty || isNanoBanana) {
      // Use Vertex AI Imagen 3
      final key = vertexKey ?? imagenKey;
      if (key != null && key.isNotEmpty) {
          try {
            return await _generateVertexImagen(prompt, key);
          } catch (e) {
            debugPrint('Vertex Imagen failed: $e. Falling back to Pollinations.');
          }
      }
    }

    // POLLINATIONS.AI FALLBACK
    // Use Pollinations.ai for high-quality, free image generation.
    // We use a random seed to ensure uniqueness.
    final seed = DateTime.now().millisecondsSinceEpoch;
    
    // Clean and optimize prompt for Pollinations
    // Remove special characters, multiple spaces, and trim
    String safePrompt = prompt.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
                             .replaceAll(RegExp(r'\s+'), ' ')
                             .trim();
    
    if (safePrompt.isEmpty) safePrompt = "stunning abstract art";
    if (safePrompt.length > 200) {
      safePrompt = safePrompt.substring(0, 200); 
    }
    
    final encodedPrompt = Uri.encodeComponent(safePrompt);
    // Use the default stable model for better reliability across environments
    return "https://image.pollinations.ai/prompt/$encodedPrompt?width=1024&height=1024&seed=$seed&nologo=true";
  }

  static Future<String> _generateVertexImagen(String prompt, String key) async {
    String projectId = 'inhausbrain'; 
    
    // Check if it's likely an API Key or an Access Token
    final isApiKey = !key.startsWith('ya29.');
    
    final baseUrl = 'https://us-central1-aiplatform.googleapis.com/v1/projects/$projectId/locations/us-central1/publishers/google/models/imagegeneration:predict';
    final url = Uri.parse(isApiKey ? '$baseUrl?key=$key' : baseUrl);
    debugPrint('EdgeAI: [VERTEX] Calling Imagen 3 at ${isApiKey ? baseUrl : url} (Auth: ${isApiKey ? "API Key" : "Bearer Token"})');
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (!isApiKey) {
      headers['Authorization'] = 'Bearer $key';
    }
    
    final response = await http.post(
      url,
      headers: headers,
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
    debugPrint('EdgeAI: [VERTEX] Response status: ${response.statusCode}');

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

  static Future<String> generateVideo(String prompt, {String? veoKey, String? vertexKey, String? runwayKey}) async {
    final isVeo = prompt.toLowerCase().contains('veo') || (veoKey != null && veoKey.isNotEmpty) || (vertexKey != null && vertexKey.isNotEmpty);
    
    if (runwayKey != null && runwayKey.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 5));
      return "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4";
    }
    if (isVeo) {
       final key = vertexKey ?? veoKey;
       if (key != null && key.isNotEmpty) {
          try {
            return await _generateVertexVeo(prompt, key);
          } catch (e) {
            debugPrint('Vertex Veo failed: $e. Falling back to placeholder.');
          }
       }
       await Future.delayed(const Duration(seconds: 3));
       return "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4"; // Placeholder for Veo
    }
    return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  }

  static Future<String> _generateVertexVeo(String prompt, String key) async {
    String projectId = 'inhausbrain';
    final isApiKey = !key.startsWith('ya29.');

    final baseUrl = 'https://us-central1-aiplatform.googleapis.com/v1/projects/$projectId/locations/us-central1/publishers/google/models/veo:predict';
    final url = Uri.parse(isApiKey ? '$baseUrl?key=$key' : baseUrl);
    debugPrint('EdgeAI: [VERTEX] Calling Veo at ${isApiKey ? baseUrl : url} (Auth: ${isApiKey ? "API Key" : "Bearer Token"})');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (!isApiKey) {
      headers['Authorization'] = 'Bearer $key';
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "instances": [
          {"prompt": prompt}
        ],
        "parameters": {
          "sampleCount": 1
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Assuming Veo logic for returning a public URL or base64
      final videoUrl = data['predictions'][0]['url'];
      return videoUrl ?? "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
    } else {
      throw Exception('Vertex Veo Error: ${response.statusCode} ${response.body}');
    }
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
