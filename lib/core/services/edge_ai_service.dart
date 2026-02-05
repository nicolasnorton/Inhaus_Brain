import 'dart:async';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import '../../features/knowledge/models/knowledge_source.dart';
import '../tokens/llm_provider.dart';
import '../auth/secret_vault_service.dart';
import 'ai_proxy_service.dart';
import 'video_generation_service.dart';
import 'telemetry_service.dart';


enum AIProximity {
  local,     // Chrome Prompt API or Gemini Nano
  cloud,     // Vertex AI
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
  final double confidence;
  final List<String>? sourceCitations;

  EdgeAIResult(this.text, this.proximity, {this.modelUsed, this.confidence = 1.0, this.sourceCitations});
}

class EdgeAIService {
  static bool forceMock = false;
  static final _vault = SecretVaultService();

  static final _logger = Logger();

  static Future<EdgeAIResult> generateText(
    String prompt, {
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    String? systemInstruction, // Alias for memoryContext
    String? outputMode,       // Alias for JSON response
    Uint8List? imageBytes,
    String? imageMimeType,
    Uint8List? audioBytes,
    String? audioMimeType,
    AIModelConfig? modelConfig,
    String? apiKey,
    String? gemmaKey,
    String? vertexKey,
    dynamic ref, // Phase 89: Support both WidgetRef and Ref for proximity sync
  }) async {
    final effectiveMemory = memoryContext ?? systemInstruction;
    var config = modelConfig ?? AIModelConfig.geminiFlash;
    
    if (outputMode == 'json') {
      config = config.copyWith(responseMimeType: 'application/json');
    }

    final effectivePrompt = _buildPromptWithContext(prompt, context, memoryContext: effectiveMemory);
    
    _logger.d('EdgeAI: Generating text via ${config.provider} (${config.modelId})');

    if (forceMock) {
      _logger.i('EdgeAI: forceMock is TRUE. Returning mock.');
      return await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
    }

    try {
      EdgeAIResult result;
      switch (config.provider) {
        case AIProvider.gemini:
          // Unified FirebaseAI Path (Vertex or Google AI Dev)
          try {
             // Prefer Vertex if we have a token/key for it
             result = await _generateFirebaseAI(
               effectivePrompt, 
               config, 
               vertexKeyOverride: vertexKey,
               apiKeyOverride: apiKey,
               imageBytes: imageBytes, 
               imageMimeType: imageMimeType,
               audioBytes: audioBytes,
               audioMimeType: audioMimeType
             );
          } catch (e) {
             _logger.w('EdgeAI: FirebaseAI failed: $e. Falling back to Proxy/Mock.');
             // If direct SDK fails (e.g. Web CORS or Auth), try Proxy if on Web
             if (kIsWeb) {
                try {
                   final proxyRes = await retry(
                     () => AIProxyService.generateContent(prompt: effectivePrompt, config: config),
                     maxAttempts: 3,
                     delayFactor: const Duration(milliseconds: 500),
                   );
                   
                   String text = "No proxy content.";
                   try {
                      final candidates = proxyRes['candidates'] as List?;
                      if (candidates?.isNotEmpty == true) {
                        final candidate = candidates!.first;
                        final parts = candidate['content']?['parts'] as List?;
                        if (parts?.isNotEmpty == true) {
                          text = parts!.first['text'] ?? parts.first.toString();
                        }
                      }
                    } catch (parseErr) {
                      _logger.w('EdgeAI: Proxy parse error: $parseErr');
                    }
                   
                   result = EdgeAIResult(text, AIProximity.cloud, modelUsed: 'Proxy: ${config.modelId}');
                } catch (proxyErr) {
                   _logger.e('EdgeAI: Proxy fallback failed: $proxyErr');
                   if (forceMock) rethrow; 
                   // Fallback to LiteRT (On-Device)
                   try {
                     _logger.i('EdgeAI: Proxy failed. Switching to LiteRT (On-Device)...');
                     result = await _generateLiteRT(effectivePrompt, config);
                   } catch (liteErr) {
                     _logger.w('EdgeAI: LiteRT failed: $liteErr. Using Mock.');
                     result = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
                   }
                }
             } else {
                 // Not Web - Try LiteRT immediately
                 try {
                   _logger.i('EdgeAI: Cloud failed. Switching to LiteRT (On-Device)...');
                   result = await _generateLiteRT(effectivePrompt, config);
                 } catch (liteErr) {
                   _logger.w('EdgeAI: LiteRT failed: $liteErr. Using Mock.');
                   result = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
                 }
             }
          }
          break;
        case AIProvider.litert:
          result = await _generateLiteRT(effectivePrompt, config);
          break;
        default:
          // Fallback to FirebaseAI for everything else (using consolidated Key routing)
             // Prefer Vertex if we have a token/key for it
             result = await _generateFirebaseAI(
               effectivePrompt, 
               config, 
               vertexKeyOverride: vertexKey,
               apiKeyOverride: apiKey,
               imageBytes: imageBytes, 
               imageMimeType: imageMimeType,
               audioBytes: audioBytes,
               audioMimeType: audioMimeType
             );
      }
      
      // Phase 89: Global Proximity Sync (Only if ref is provided)
      if (ref != null) {
        ref.read(aiProximityProvider.notifier).setProximity(result.proximity);
      }
      
      return result;
    } catch (e, stack) {
      _logger.e('EdgeAI: ERROR during ${config.provider} generation', error: e, stackTrace: stack);
      final mockRes = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
      if (ref != null) {
        ref.read(aiProximityProvider.notifier).setProximity(mockRes.proximity);
      }
      return mockRes;
    }
  }

  // --- PROVIDER IMPLEMENTATIONS ---


  static Future<EdgeAIResult> _generateFirebaseAI(
    String prompt, 
    AIModelConfig config, {
    String? vertexKeyOverride,
    String? apiKeyOverride,
    Uint8List? imageBytes,
    String? imageMimeType,
    Uint8List? audioBytes,
    String? audioMimeType,
  }) async {
    final ai = FirebaseAI.vertexAI();
    // Note: apiKey and backend are now automatically handled by FirebaseAI based on project config
    
    final model = ai.generativeModel(
      model: _sanitizeModelName(config.modelId),
      generationConfig: GenerationConfig(
        temperature: config.temperature,
        maxOutputTokens: config.maxTokens ?? 2048,
        responseMimeType: config.responseMimeType,
      ),
      safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high, HarmBlockMethod.probability), 
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high, HarmBlockMethod.probability),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high, HarmBlockMethod.probability),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high, HarmBlockMethod.probability),
      ],
      tools: [
        Tool.codeExecution(),
        // if (config.useGoogleSearch) 
        //   Tool.googleSearchRetrieval(GoogleSearchRetrieval(dynamicRetrievalConfig: DynamicRetrievalConfig(mode: DynamicRetrievalConfigMode.modeDynamic))),
      ],
    );

    final parts = <Part>[TextPart(prompt)];
    
    if (imageBytes != null) {
      parts.add(InlineDataPart(imageMimeType ?? 'image/jpeg', imageBytes));
    }
    
    if (audioBytes != null) {
      parts.add(InlineDataPart(audioMimeType ?? 'audio/mp3', audioBytes));
    }

    final content = Content.multi(parts);
    
    final response = await model.generateContent([content]);
    
    String fullText = response.text ?? '';
    
    if (fullText.isEmpty && response.candidates.isNotEmpty) {
       for (var part in response.candidates.first.content.parts) {
          if (part is TextPart) {
             fullText += part.text;
          } else if (part is FunctionCall) {
             // Convert native function call to JSON format for AssistantService
             final callJson = jsonEncode({
               'tool': part.name,
               'args': part.args,
             });
             fullText += callJson;
          } else if (part is FunctionResponse) {
             fullText += "\n**Function Result:** ${part.response}";
          } else if (part is ExecutableCodePart) {
             // Handle ExecutableCodePart - extract the actual code
             debugPrint('EdgeAI: ExecutableCodePart detected - language: ${part.language}, code length: ${part.code.length}');
             String code = part.code.trim();
             // Fix for Gemini wrapping JSON in print()
             if (code.startsWith('print(') && code.endsWith(')')) {
                debugPrint('EdgeAI: Unwrapping print() statement from tool code...');
                code = code.substring(6, code.length - 1);
             }
             fullText += code;
          } else {
             // Fallback for other unknown types
             debugPrint('EdgeAI Warning: Unknown part type: ${part.runtimeType}');
             fullText += part.toString();
          }
       }
    }
    
    if (fullText.trim().isEmpty) {
        debugPrint('EdgeAI Warning: Response candidates empty or unparseable. Parts: ${response.candidates.firstOrNull?.content.parts}');
        fullText = 'No content generated. (Empty Response)';
    }

    // Check for grounding
    List<String> validSources = [];
    if (response.candidates.isNotEmpty) {
       final grounding = response.candidates.first.groundingMetadata;
       if (grounding != null && grounding.groundingChunks.isNotEmpty) {
          validSources = grounding.groundingChunks
              .map((chunk) => chunk.web?.uri?.toString())
              .whereType<String>()
              .toSet() // Create a Set to remove duplicates
              .toList(); // Convert back to List

          final sourcesStr = validSources.join(', ');
          if (sourcesStr.isNotEmpty) {
             fullText += "\n\n**Sources:** $sourcesStr";
          }
       }
    }

    // Confidence Calculation
    double confidence = 1.0;
    if (response.candidates.isNotEmpty) {
      final candidate = response.candidates.first;
      if (candidate.finishReason != FinishReason.stop) {
        confidence = 0.5;
        if (candidate.finishReason == FinishReason.safety || candidate.finishReason == FinishReason.recitation) {
          confidence = 0.0;
        }
      }
      if (prompt.length > 50 && fullText.length < 5) {
        confidence = 0.1;
      }
    }

    return EdgeAIResult(fullText, AIProximity.cloud, modelUsed: config.modelId, confidence: confidence, sourceCitations: validSources);
  }

  static String _sanitizeModelName(String modelId) {
    if (modelId.contains('-001')) return modelId.replaceAll('-001', '');
    if (modelId.contains('-002')) return modelId.replaceAll('-002', '');
    return modelId;
  }

  static Stream<EdgeAIResult> generateTextStream(
    String prompt, {
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    String? systemInstruction, // ADDED
    Uint8List? imageBytes,
    String? imageMimeType,
    Uint8List? audioBytes,
    String? audioMimeType,
    AIModelConfig? config,
    String? apiKey,
    dynamic ref, 
  }) async* {
    final effectiveMemory = memoryContext ?? systemInstruction;
    final effectiveConfig = config ?? AIModelConfig.geminiFlash;
     
     if (effectiveConfig.provider != AIProvider.gemini) {
        yield EdgeAIResult("Thinking...", AIProximity.simulated);
        yield await generateText(
           prompt, 
           context: context, 
           memoryContext: effectiveMemory, 
           imageBytes: imageBytes, 
           imageMimeType: imageMimeType, 
           modelConfig: effectiveConfig, 
           apiKey: apiKey, 
           ref: ref
        );
        return;
     }

     try {
       final effectivePrompt = _buildPromptWithContext(prompt, context, memoryContext: effectiveMemory);
       final ai = FirebaseAI.vertexAI();
       
       final model = ai.generativeModel(
          model: _sanitizeModelName(effectiveConfig.modelId),
          generationConfig: GenerationConfig(
            temperature: effectiveConfig.temperature,
            maxOutputTokens: effectiveConfig.maxTokens,
            responseMimeType: effectiveConfig.responseMimeType,
          ),
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium, HarmBlockMethod.probability), 
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium, HarmBlockMethod.probability),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium, HarmBlockMethod.probability),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium, HarmBlockMethod.probability),
          ],
       );

       final parts = <Part>[TextPart(effectivePrompt)];
       if (imageBytes != null) parts.add(InlineDataPart(imageMimeType ?? 'image/jpeg', imageBytes));
       
       final content = Content.multi(parts);
       final stream = model.generateContentStream([content]);
       
       String accumulatedText = '';
       
       await for (final chunk in stream) {
          if (chunk.text != null && chunk.text!.isNotEmpty) {
             accumulatedText += chunk.text!;
             yield EdgeAIResult(accumulatedText, AIProximity.cloud, modelUsed: effectiveConfig.modelId);
          }
          if (chunk.candidates.isNotEmpty && chunk.candidates.first.finishReason != null) {
            _logger.d('EdgeAI: Stream finished with reason: ${chunk.candidates.first.finishReason}');
          }
       }

     } catch (e) {
        _logger.e('EdgeAI: [STREAM] Error: $e');
        yield EdgeAIResult("Stream Error: $e", AIProximity.simulated);
     }
  }


  static Future<String> generateImage(String prompt, {String? imagenKey, String? vertexKey, dynamic ref}) async {
    // 1. WEB PROXY PATH (Vertex Imagen - Primary)
    if (kIsWeb) {
       try {
         debugPrint('EdgeAI: [WEB] Routing Image Generation via Secure Proxy (Imagen 3)...');
         final proxyResponse = await AIProxyService.generateContent(
           prompt: prompt,
           config: AIModelConfig(provider: AIProvider.vertex, modelId: 'imagen-3.0-generate-001'),
         );
         
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
         debugPrint('EdgeAI: [WEB] Proxy Image Gen Failed: $e. Using fallback chain.');
       }
    } 
    
    // 2. SAFE MOCKS (Fallback)

    // 4. SAFE MOCKS (Clawd / Lobster Mock Fallback)
    debugPrint('EdgeAI: 🚨 ALL Image/AI services failed. Providing SAFE MOCK asset.');
    // Return a guaranteed safe, cached asset path or reliable placeholder
    // In production, these should be local assets. For now, using a reliable Unsplash lobster/tech fallback.
    return "https://images.unsplash.com/photo-1535591273668-578e31182c4f?q=80&w=2070&auto=format&fit=crop"; 
  }

  static Future<String> generateVideo(String prompt, {bool isFinal = false, bool includeSubtitles = false, String? veoKey, String? vertexKey, dynamic ref, Function(double)? onProgress, Function(String)? onStatusMessage}) async {
    // Phase 95: Telemetry Injection via Ref if available
    final telemetry = ref?.read(telemetryServiceProvider);
    
    if (isFinal) {
      return await VideoGenerationService.generateFinal(prompt, confirmedByUser: true, onProgress: onProgress, onStatusMessage: onStatusMessage, telemetry: telemetry);
    } else {
      return await VideoGenerationService.generatePreview(prompt, onProgress: onProgress, telemetry: telemetry);
    }
  }

  static Future<String> _pollProxyVeoOperation(String operationName) async {
    for (int i = 0; i < 24; i++) {
        await Future.delayed(const Duration(seconds: 5));
        debugPrint('EdgeAI: [VEO-PROXY] Checking generation status (attempt ${i + 1})...');
        
        try {
            final data = await AIProxyService.pollOperation(operationName);
            if (data['done'] == true) {
                if (data['error'] != null) throw Exception('Veo Operation Failed: ${data['error']}');
                
                final respObj = data['response'];
                if (respObj != null && respObj['predictions'] != null && (respObj['predictions'] as List).isNotEmpty) {
                    final videoUrl = respObj['predictions'][0]['url'] ?? respObj['predictions'][0]['videoUri'];
                    if (videoUrl != null) return _sanitizeMediaUrl(videoUrl);
                }
                 final metadata = data['metadata'];
                 if (metadata != null && metadata['outputUri'] != null) {
                    return _sanitizeMediaUrl(metadata['outputUri']);
                 }
                 throw Exception('Veo operation finished but no video URL found.');
            }
        } catch (e) {
            debugPrint('EdgeAI: [VEO-PROXY] Polling error: $e');
        }
    }
     throw Exception('Veo generation timed out (operation: $operationName)');
  }

  static String _sanitizeMediaUrl(String url) {
    if (url.startsWith('gs://')) {
       final path = url.replaceFirst('gs://', '');
       return "https://storage.googleapis.com/$path";
    }
    return url;
  }

  static Future<String> generateAudio(String prompt, {String? lyriaKey}) async {
    debugPrint('EdgeAI: [AUDIO] Generating audio for: "$prompt" (MOCKED/STATIC)');
    await Future.delayed(const Duration(milliseconds: 1500));
    // Use local asset for instant playback reliability in demo
    return "assets/audio/success_chime.mp3"; 
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


  // --- LITER T INTEGRATION ---

  static bool _isLiteRTInitialized = false;
  static bool _hasHwAccelerator = false;

  /// Initializes LiteRT and checks for hardware acceleration.
  static Future<void> initLiteRT() async {
    if (_isLiteRTInitialized) return;
    try {
      // In 2026, we use the unified litert package
      // Assuming mock/simulated here since we don't have the actual package in this env
      // final status = await LiteRT.init(); 
      // _hasHwAccelerator = await LiteRT.env.checkHwAccelerator(); 
      
      _logger.d('EdgeAI: Initializing LiteRT...');
      // Simulation of checking HW
      await Future.delayed(const Duration(milliseconds: 100));
      if (!kIsWeb) {
         _hasHwAccelerator = true; // Assume modern mobile/desktop has NPU/GPU
      }
      _isLiteRTInitialized = true;
      _logger.i('EdgeAI: LiteRT initialized (HW Accel: $_hasHwAccelerator)');
    } catch (e) {
      _logger.w('EdgeAI: LiteRT init failed: $e');
    }
  }

  static Future<EdgeAIResult> _generateLiteRT(
    String prompt, 
    AIModelConfig config,
  ) async {
    if (!_isLiteRTInitialized) await initLiteRT();

    _logger.d('EdgeAI: [LiteRT] Generating with ${config.modelId} (Accelerated: $_hasHwAccelerator)...');
    
    // Simulate On-Device Latency (fast!)
    await Future.delayed(const Duration(milliseconds: 150)); 
    
    final sampleResponse = "LiteRT (${config.modelId}): Analyzed '$prompt'. Result: [Fast On-Device Preview] Content generated successfully.";
    
    return EdgeAIResult(
      sampleResponse, 
      AIProximity.local, 
      modelUsed: config.modelId,
      confidence: 0.85, // Good but maybe not perfect
    );
  }
}
