import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../features/knowledge/models/knowledge_source.dart';
import '../tokens/llm_provider.dart';
import '../auth/secret_vault_service.dart';
import '../auth/auth_service.dart';
import 'ai_proxy_service.dart';

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
    String? vertexKey,
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
          final vaultGeminiKey = await _vault.getGeminiKey();
          final vaultVertexKey = await _vault.getVertexKey();
          
          final effectiveApiKey = apiKey ?? vaultGeminiKey;
          final effectiveVertexKey = vertexKey ?? vaultVertexKey;
          
          // Mode detection: If vertex key is present and looks like a token, use Vertex path
          // Standard Access Tokens start with ya29. 
          // Keys starting with AQ. are also treated as OAuth-style tokens for Vertex AI
          final isVertexToken = effectiveVertexKey != null && effectiveVertexKey.isNotEmpty && 
              (effectiveVertexKey.startsWith('ya29.') || effectiveVertexKey.startsWith('AQ.'));
          
          if (isVertexToken) {
             try {
               result = await _generateVertexGemini(effectivePrompt, config, effectiveVertexKey!, imageBytes, imageMimeType);
             } catch (e) {
               debugPrint('EdgeAI: [DEBUG] Vertex Gemini (Token) failed: $e. Falling back to Dev API.');
               if (effectiveApiKey != null && effectiveApiKey.isNotEmpty && !effectiveApiKey.startsWith('AQ.')) {
                  // Fallback: Use the config as-is (with version suffix if present)
                  result = await _generateGemini(effectivePrompt, config, effectiveApiKey, imageBytes, imageMimeType, audioBytes, audioMimeType);
               } else {
                 rethrow;
               }
             }
          } 
          // Path 2: Explicit API Key (starts with AIza)
          else if ((effectiveVertexKey != null && effectiveVertexKey.isNotEmpty) || (effectiveApiKey != null && effectiveApiKey.isNotEmpty)) {
             final keyToUse = (effectiveVertexKey != null && effectiveVertexKey.isNotEmpty) ? effectiveVertexKey : effectiveApiKey!;
             
             try {
                // Route based on key type: 
                // ya29. or AQ. -> Vertex AI (Requires Authorization Header)
                // AIza... -> Gemini Dev API (Requires ?key= query parameter)
               if (keyToUse.startsWith('ya29.') || keyToUse.startsWith('AQ.')) {
                  result = await _generateVertexGemini(effectivePrompt, config, keyToUse, imageBytes, imageMimeType);
               } else {
                  result = await _generateGemini(effectivePrompt, config, keyToUse, imageBytes, imageMimeType, audioBytes, audioMimeType);
               }
             } catch (e) {
                final errorObj = e;
                final errorStr = (errorObj != null) ? errorObj.toString() : 'Unknown Vertex Error';
                debugPrint('EdgeAI: [DEBUG] Vertex Gemini (API Key) failed: $errorStr. Falling back to Google Generative Language API.');
                // Special guidance for 401/403
                if (errorStr.contains('401') || errorStr.contains('403')) {
                   debugPrint('EdgeAI: [HINT] This likely means the API Key is not enabled for the Vertex AI (AI Platform) API specifically, or is restricted.');
                }
                
                // Fallback to standard Gemini API if we have a valid Dev API key
                if (effectiveApiKey != null && effectiveApiKey.isNotEmpty && !effectiveApiKey.startsWith('AQ.')) {
                   // Dev API often uses 'gemini-1.5-flash' alias instead of specific version 'gemini-1.5-flash-001'
                   // We strip the suffix to be safe during fallback.
                   var fallbackId = config.modelId;
                   if (fallbackId.contains('-001')) {
                      fallbackId = fallbackId.replaceAll('-001', '');
                   } else if (fallbackId.contains('-002')) {
                      fallbackId = fallbackId.replaceAll('-002', '');
                   }
                   final devApiConfig = AIModelConfig(provider: AIProvider.gemini, modelId: fallbackId, temperature: config.temperature, maxTokens: config.maxTokens);
                   
                   result = await _generateGemini(effectivePrompt, devApiConfig, effectiveApiKey, imageBytes, imageMimeType, audioBytes, audioMimeType);
                } else {
                   rethrow;
                }
              }
           }
           // Priority 3: Standard Gemini Dev API
           else if (effectiveApiKey != null && effectiveApiKey.isNotEmpty && !effectiveApiKey.startsWith('AQ.')) {
             try {
               result = await _generateGemini(effectivePrompt, config, effectiveApiKey, imageBytes, imageMimeType, audioBytes, audioMimeType);
             } catch (e) {
                final gemErrObj = e;
                final gemErr = (gemErrObj != null) ? gemErrObj.toString() : 'Unknown Gemini Error';
                debugPrint('EdgeAI: [DEBUG] Primary Gemini model (${config.modelId}) failed: $gemErr');
                // Fallback: Try gemini-pro (v1.0) if Flash fails
                final fallbackConfig = AIModelConfig(provider: AIProvider.gemini, modelId: 'gemini-pro');
                result = await _generateGemini(effectivePrompt, fallbackConfig, effectiveApiKey, imageBytes, imageMimeType, audioBytes, audioMimeType);
             }
           } 
           else {
             debugPrint('EdgeAI: [DEBUG] No Gemini keys found. Returning mock.');
             result = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
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

    // Use REST API directly to access latest tools (Google Search, Code Execution) 
    // which might not be exposed in the current google_generative_ai package version (0.4.7)
    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/${config.modelId}:generateContent?key=$apiKey');
    
    final List<Map<String, dynamic>> parts = [
      {'text': prompt}
    ];

    if (imageBytes != null) {
      parts.add({
        'inline_data': {
          'mime_type': mimeType ?? 'image/jpeg',
          'data': base64Encode(imageBytes)
        }
      });
    }

    if (audioBytes != null) {
      parts.add({
        'inline_data': {
          'mime_type': audioMimeType ?? 'audio/mp3',
          'data': base64Encode(audioBytes)
        }
      });
    }

    final body = {
      "contents": [
        {
          "parts": parts,
          "role": "user"
        }
      ],
      "tools": [
        {"codeExecution": {}}
      ],
      "safetySettings": [
        {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
        {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
        {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"},
        {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"}
      ]
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Extract text from candidates
      if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
        final candidate = data['candidates'][0];
        final content = candidate['content'];
        String fullText = "";
        
        if (content != null && content['parts'] != null) {
          for (var part in content['parts']) {
             if (part.containsKey('text')) {
               fullText += part['text'];
             } else if (part.containsKey('executableCode')) {
               fullText += "\n```python\n${part['executableCode']['code']}\n```\n";
             } else if (part.containsKey('codeExecutionResult')) {
               fullText += "\nOutput: ${part['codeExecutionResult']['output']}\n";
             } else if (part.containsKey('functionCall')) {
               final fc = part['functionCall'];
               fullText += "\n[System: Calling Native Tool ${fc['name']} with args: ${fc['args']}]\n";
             }
          }
        }
        
        // Handle stop reasons like SAFETY or RECITATION if text is likely empty
        if (fullText.trim().isEmpty && candidate['finishReason'] != null) {
           fullText = "Generation stopped: ${candidate['finishReason']}";
        }
        
        // Append grounding metadata if available
        if (candidate['groundingMetadata'] != null) {
           final metadata = candidate['groundingMetadata'];
           if (metadata['searchEntryPoint'] != null) {
               // Strip style tags to prevent JSON parser confusion in the frontend
               // and clean up the HTML for display
               String cleanContent = (metadata['searchEntryPoint']['renderedContent'] ?? '')
                   .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
                   .replaceAll(RegExp(r'<[^>]+>'), ' ') // Also strip other HTML tags for clean text, or leave them if Markdown supports it. Let's strip style but keep structure if possible? 
                   // Actually, let's keep it simple: Strip STYLE only, as that breaks JSON. 
                   // The user log showed CSS text leaking. 
                   // Let's go with just stripping style for now.
                   .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
                   .replaceAll(RegExp(r'\s+'), ' ')
                   .trim();
               
               // Use a simpler approach: Just a link if we can't parse safely?
               // The log showed <div class="container">... 
               // Let's just strip the style block entirely.
               String rawHtml = (metadata['searchEntryPoint']['renderedContent'] ?? '');
               String noStyle = rawHtml.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');
               
               // Sanitize heavily for JSON safety
               noStyle = noStyle.replaceAll(RegExp(r'\s+'), ' ').trim();
               
               fullText += "\n\n[Google Search Results]:\n$noStyle";
           }
        }
        
        return EdgeAIResult(fullText.isEmpty ? "No text generated." : fullText, AIProximity.cloud, modelUsed: config.modelId);
      }
      return EdgeAIResult("No candidates returned.", AIProximity.cloud);
    } else {
      throw Exception('Gemini REST Error: ${response.statusCode} ${response.body}');
    }
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

  static Future<String> generateImage(String prompt, {String? imagenKey, String? vertexKey, String? bananaKey, String? midjourneyKey, String? runwayKey, Ref? ref}) async {
    String? freshToken;
    if (ref != null) {
      try {
        freshToken = await ref.read(authServiceProvider).getFreshVertexToken();
      } catch (e) {/* ignore */}
    }

    final isNanoBanana = prompt.toLowerCase().contains('banana') || (bananaKey != null && bananaKey.isNotEmpty);
    
    final vaultVertexKey = await _vault.getVertexKey();
    final vaultImagenKey = await _vault.getImagenKey();
    
    // Priority: Fresh Token > Passed Token > Vault Token > Legacy Keys
    final effectiveKey = freshToken ?? vertexKey ?? vaultVertexKey ?? imagenKey ?? vaultImagenKey;
    
    // WEB PROXY PATH (Always use proxy if on web and trying to use Vertex/Imagen)
    if (kIsWeb && (effectiveKey != null || isNanoBanana)) {
       try {
         debugPrint('EdgeAI: [WEB] Routing Image Generation via Secure Proxy...');
         final proxyResponse = await AIProxyService.generateContent(
           prompt: prompt,
           config: AIModelConfig(provider: AIProvider.vertex, modelId: 'imagen-3.0-generate-001'),
         );
         
         // Parse Proxy Response (Custom 'imagen' or standard Gemini)
         // Our backend returns { custom_type: 'imagen', predictions: [...] }
         if (proxyResponse['custom_type'] == 'imagen') {
            final predictions = proxyResponse['predictions'] as List?;
            if (predictions != null && predictions.isNotEmpty) {
               final firstPred = predictions[0];
               final base64Image = firstPred['bytesBase64Encoded'];
               if (base64Image != null) {
                  return "data:image/png;base64,$base64Image";
               }
            }
         }
       } catch (e) {
         debugPrint('EdgeAI: [WEB] Proxy Image Gen Failed: $e. Falling back to Pollinations.');
       }
    } else if (effectiveKey != null && effectiveKey.isNotEmpty || isNanoBanana) {
      // Use Vertex AI Imagen 3 (Direct / Native Mobile)
      if (effectiveKey != null && effectiveKey.isNotEmpty) {
          try {
            return await _generateVertexImagen(prompt, effectiveKey);
          } catch (e) {
            debugPrint('Vertex Imagen failed: $e. Falling back to Pollinations.');
          }
      }
    }

    // POLLINATIONS.AI FALLBACK
    // Use Pollinations.ai for high-quality, free image generation.
    final seed = DateTime.now().millisecondsSinceEpoch;
    
    // Clean and optimize prompt for Pollinations
    String safePrompt = prompt.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
                             .replaceAll(RegExp(r'\s+'), ' ')
                             .trim();
    
    if (safePrompt.isEmpty) safePrompt = "abstract art";

    // Limit length to avoid URL issues and 403s
    if (safePrompt.length > 80) {
      safePrompt = safePrompt.substring(0, 80); 
    }
    
    // Use strict encoding for the prompt
    final encodedPrompt = Uri.encodeComponent(safePrompt);
    // Removed model=flux to check if that resolves the 403. Using default model.
    return "https://image.pollinations.ai/prompt/$encodedPrompt?width=1024&height=1024&nologo=true&seed=$seed";
  }

  static Future<String> _generateVertexImagen(String prompt, String key) async {
    String projectId = 'inhausbrain'; 
    
    // Check if it's likely an API Key (starts with AIza) or an Access Token (ya29, AQ)
    final isToken = key.startsWith('ya29.') || key.startsWith('AQ.');
    final isApiKey = !isToken;
    
    // Vertex AI Imagen 3 endpoint: Using the explicit modern path
    final baseUrl = 'https://us-central1-aiplatform.googleapis.com/v1/projects/$projectId/locations/us-central1/publishers/google/models/imagen-3.0-generate-001:predict';
    final url = Uri.parse(isApiKey ? '$baseUrl?key=$key' : baseUrl);
    debugPrint('EdgeAI: [VERTEX] Calling Imagen 3 at ${isApiKey ? "REST" : "OAuth"} endpoint');
    
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
      final predictions = data['predictions'] as List?;
      if (predictions == null || predictions.isEmpty) {
        throw Exception('Vertex Imagen: No predictions in response: ${response.body}');
      }
      final firstPred = predictions[0] as Map?;
      final base64Image = firstPred?['bytesBase64Encoded'];
      if (base64Image == null) {
        throw Exception('Vertex Imagen: No image bytes in response: ${response.body}');
      }
      return "data:image/png;base64,$base64Image";
    } else {
      final errorBody = response.body;
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('EdgeAI: [VERTEX] Imagen Auth Error ${response.statusCode}: $errorBody');
        debugPrint('EdgeAI: [HINT] Ensure the Vertex AI API is enabled in project "$projectId" and your OAuth token (Scopes: cloud-platform) has permissions.');
      }
      throw Exception('Vertex AI Error: ${response.statusCode} $errorBody');
    }
  }

  static Future<String> generateVideo(String prompt, {String? veoKey, String? vertexKey, String? runwayKey, Ref? ref}) async {
    String? freshToken;
    if (ref != null) {
      try {
        freshToken = await ref.read(authServiceProvider).getFreshVertexToken();
      } catch (e) {/* ignore */}
    }

    final vaultVertexKey = await _vault.getVertexKey();
    final vaultVeoKey = await _vault.getVeoKey();
    
    final effectiveKey = freshToken ?? vertexKey ?? vaultVertexKey ?? veoKey ?? vaultVeoKey;
    final isVeoInput = prompt.toLowerCase().contains('veo') || (effectiveKey != null && effectiveKey.isNotEmpty);
    
    if (runwayKey != null && runwayKey.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 5));
      return "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4";
    }
    if (isVeoInput) {
       if (effectiveKey != null && effectiveKey.isNotEmpty) {
          try {
            return await _generateVertexVeo(prompt, effectiveKey);
          } catch (e) {
            debugPrint('Vertex Veo failed: $e. Falling back to placeholder.');
          }
       }
       await Future.delayed(const Duration(seconds: 2)); // Simulate generation time
       return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"; 
    }
    return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  }

  static Future<String> _generateVertexVeo(String prompt, String key) async {
    String projectId = 'inhausbrain';
    // Vertex AI Tokens usually start with ya29. or AQ.
    final isToken = key.startsWith('ya29.') || key.startsWith('AQ.');
    final isApiKey = !isToken;
    
    // Using the veo-001 model ID (SOTA)
    // Veo often requires the :predict endpoint
    final baseUrl = 'https://us-central1-aiplatform.googleapis.com/v1/projects/$projectId/locations/us-central1/publishers/google/models/veo-001:predict';
    final url = Uri.parse(isApiKey ? '$baseUrl?key=$key' : baseUrl);
    debugPrint('EdgeAI: [VERTEX] Calling Veo (veo-001) at ${isApiKey ? "REST Endpoint" : "OAuth Endpoint"}');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (!isApiKey) {
      headers['Authorization'] = 'Bearer $key';
    }

    // Official Veo predictive request structure
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "instances": [
          {
            "prompt": prompt,
          }
        ],
        "parameters": {
          "sampleCount": 1,
          "aspectRatio": "16:9",
          "durationSeconds": 5, // Default for many Veo pipelines
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Case 1: Synchronous response (Preview or small generation)
      if (data['predictions'] != null && data['predictions'].isNotEmpty) {
        final prediction = data['predictions'][0];
        final videoUrl = prediction['url'] ?? prediction['videoUri'];
        if (videoUrl != null) return _sanitizeMediaUrl(videoUrl);
      }

      // Case 2: Long-Running Operation (LRO)
      if (data['name'] != null && data['name'].contains('/operations/')) {
        debugPrint('EdgeAI: [VEO] Generation started asynchronously. Polling Operation: ${data['name']}');
        return await _pollVertexOperation(data['name'], key, isApiKey);
      }

      throw Exception('Veo response format unrecognized: ${response.body}');
    } else {
      final errorBody = response.body;
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('EdgeAI: [VERTEX] Veo Auth Error ${response.statusCode}: $errorBody');
        debugPrint('EdgeAI: [HINT] Ensure the Vertex AI API (AI Platform) is enabled in project "$projectId" and the account has "Vertex AI User" role.');
      }
      throw Exception('Vertex Veo Error: ${response.statusCode} $errorBody');
    }
  }

  static Future<String> _pollVertexOperation(String name, String key, bool isApiKey) async {
    // Operation URL: projects/{project}/locations/{location}/operations/{id}
    final baseUrl = 'https://us-central1-aiplatform.googleapis.com/v1/$name';
    final url = Uri.parse(isApiKey ? '$baseUrl?key=$key' : baseUrl);
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (!isApiKey) {
       headers['Authorization'] = 'Bearer $key';
    }

    // Poll for up to 2 minutes
    for (int i = 0; i < 24; i++) {
       await Future.delayed(const Duration(seconds: 5));
       debugPrint('EdgeAI: [VEO] Checking generation status (attempt ${i + 1})...');
       
       final response = await http.get(url, headers: headers);
       if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['done'] == true) {
             if (data['error'] != null) {
                throw Exception('Veo Operation Failed: ${data['error']}');
             }
             
             // Extract output URI from response metadata or response field
             // For Veo/Imagen, it's often in response.predictions[0].url
             final respObj = data['response'];
             if (respObj != null && respObj['predictions'] != null && respObj['predictions'].isNotEmpty) {
                final videoUrl = respObj['predictions'][0]['url'] ?? respObj['predictions'][0]['videoUri'];
                if (videoUrl != null) return _sanitizeMediaUrl(videoUrl);
             }
             
             // Check metadata if response field is empty
             final metadata = data['metadata'];
             if (metadata != null && metadata['outputUri'] != null) {
                return _sanitizeMediaUrl(metadata['outputUri']);
             }

             throw Exception('Veo operation finished but no video URL found.');
          }
       } else {
          debugPrint('EdgeAI: [VEO] Polling error: ${response.statusCode}');
       }
    }
    
    throw Exception('Veo generation timed out (operation: $name)');
  }

  static String _sanitizeMediaUrl(String url) {
    if (url.startsWith('gs://')) {
       // Convert Google Cloud Storage URI to public HTTPS link
       // gs://bucket_name/object_path -> https://storage.googleapis.com/bucket_name/object_path
       final path = url.replaceFirst('gs://', '');
       return "https://storage.googleapis.com/$path";
    }
    return url;
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
       final vaultGeminiKey = await _vault.getGeminiKey();
       final vaultVertexKey = await _vault.getVertexKey();
       final effectiveApiKey = apiKey ?? vaultGeminiKey;
       final effectiveVertexKey = vaultVertexKey; // In stream we usually rely on vault if not passed

       if (effectiveVertexKey != null && effectiveVertexKey.startsWith('ya29.')) {
          try {
             final result = await _generateVertexGemini(_buildPromptWithContext(prompt, context, memoryContext: memoryContext), config!, effectiveVertexKey, imageBytes, imageMimeType);
             if (ref != null) ref.read(aiProximityProvider.notifier).setProximity(result.proximity);
             yield result;
             return;
          } catch (e) {
             debugPrint('EdgeAI: [VERTEX] Gemini failed ($e). Falling back to Dev API.');
             // Fallthrough to standard API Key implementation
          }
       }

       if (effectiveApiKey != null) {
          final result = await _generateGemini(_buildPromptWithContext(prompt, context, memoryContext: memoryContext), config!, effectiveApiKey, imageBytes, imageMimeType, audioBytes, audioMimeType);
          if (ref != null) ref.read(aiProximityProvider.notifier).setProximity(result.proximity);
          yield result;
          return;
       }
    }
    
    yield EdgeAIResult("Thinking via ${config?.displayName ?? 'Edge Mock'}...", AIProximity.simulated);
    final result = await generateText(prompt, context: context, memoryContext: memoryContext, imageBytes: imageBytes, imageMimeType: imageMimeType, modelConfig: config, apiKey: apiKey, ref: ref);
    yield result;
  }

  static Future<EdgeAIResult> _generateVertexGemini(
    String prompt, 
    AIModelConfig config, 
    String key, 
    Uint8List? imageBytes,
    String? mimeType
  ) async {
    // WEB PROXY PATH
    if (kIsWeb) {
      try {
        debugPrint('EdgeAI: [WEB] Routing Vertex AI request via Secure Proxy...');
        final proxyResponse = await AIProxyService.generateContent(
          prompt: prompt,
          config: config,
        );
        
        // Parse Proxy Response (Standard Gemini JSON structure)
        final candidates = proxyResponse['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
           final firstCandidate = candidates[0];
           final content = firstCandidate['content'];
           String fullText = "";
           if (content != null && content['parts'] != null) {
              for (var part in content['parts']) {
                 if (part['text'] != null) fullText += part['text'];
              }
           }
           if (fullText.isEmpty && firstCandidate['finishReason'] != null) {
              fullText = "Stopped: ${firstCandidate['finishReason']}";
           }
           return EdgeAIResult(fullText, AIProximity.cloud, modelUsed: config.modelId);
        }
        return EdgeAIResult("No text generated (Proxy).", AIProximity.cloud);
      } catch (e) {
        debugPrint('EdgeAI: [WEB] Proxy Request Failed: $e');
        // Optional: Fallback to direct API if Proxy fails? 
        // For now, rethrow because direct Vertex on Web is known to fail (CORS).
        rethrow;
      }
    }

    // NATIVE / MOBILE PATH (Existing direct logic)
    String projectId = 'inhausbrain';
    final isToken = key.startsWith('ya29.') || key.startsWith('AQ.');
    final isApiKey = !isToken;
    
    // Map Dev API model IDs to Vertex AI model IDs
    // Using explicit versioned IDs to improve reliability in us-central1
    String modelId = config.modelId;
    if (modelId.contains('flash')) modelId = 'gemini-1.5-flash-002';
    else if (modelId.contains('pro')) modelId = 'gemini-1.5-pro-002';

    // Vertex AI Gemini endpoint: Use generateContent which is the modern path for Gemini on Vertex
    final baseUrl = 'https://us-central1-aiplatform.googleapis.com/v1/projects/$projectId/locations/us-central1/publishers/google/models/$modelId:generateContent';
    
    final url = Uri.parse(isApiKey ? '$baseUrl?key=$key' : baseUrl);
    debugPrint('EdgeAI: [VERTEX] Calling Gemini via ${isApiKey ? "API Key" : "OAuth Token"} ($modelId)');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (!isApiKey) {
      headers['Authorization'] = 'Bearer $key';
    }

    final List<Map<String, dynamic>> parts = [{'text': prompt}];
    if (imageBytes != null) {
      parts.add({
        'inline_data': {
          'mime_type': mimeType ?? 'image/jpeg',
          'data': base64Encode(imageBytes)
        }
      });
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": parts,
          }
        ],
        "generationConfig": {
          "temperature": config.temperature,
          "maxOutputTokens": 2048,
        },
        "safetySettings": [
           {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
           {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
           {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"},
           {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String text = "";
      
      // Handle array of candidates (Gemini style)
      if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
         final candidate = data['candidates'][0];
         if (candidate['content'] != null && candidate['content']['parts'] != null) {
            text = (candidate['content']['parts'] as List).map((p) => p['text'] ?? '').join("");
         }
      } 
      // Handle 'predictions' fallback for older Vertex models or predict endpoint
      else if (data['predictions'] != null && (data['predictions'] as List).isNotEmpty) {
         text = data['predictions'][0]['content'] ?? data['predictions'][0]['text'] ?? "";
      }
      
      if (text.isEmpty) text = "No content generated.";
      return EdgeAIResult(text, AIProximity.cloud, modelUsed: 'Vertex: $modelId');
    } else {
      final errorBody = response.body;
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('EdgeAI: [VERTEX] Auth Error ${response.statusCode}: $errorBody');
        debugPrint('EdgeAI: [HINT] Ensure the Vertex AI API is enabled in project "$projectId" and your OAuth token (Scopes: cloud-platform) has permissions.');
      }
      throw Exception('Vertex Gemini Error: ${response.statusCode} $errorBody');
    }
  }

  static Future<EdgeAIResult> _generateLocalMock(String prompt, {bool hasImage = false}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return EdgeAIResult("Edge Mock: Analyzed request locally. (Simulated Response)", AIProximity.simulated);
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
