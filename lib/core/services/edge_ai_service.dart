import 'dart:async';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
// // import 'package:google_generative_ai/google_generative_ai.dart' as g_ai; // Not needed if using firebase_ai Tool
// import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import '../../features/knowledge/models/knowledge_source.dart';
import '../tokens/llm_provider.dart';

import 'ai_proxy_service.dart';
import 'video_generation_service.dart';
import 'telemetry_service.dart';
import 'semantic_cache_service.dart';
import 'analytics_service.dart';
import '../mcp/agent_tool.dart';
import '../utils/function_schema_mapper.dart';


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
    Uint8List? videoBytes,
    String? videoMimeType,
    Uint8List? pdfBytes,
    String? pdfMimeType,
    AIModelConfig? modelConfig,
    String? apiKey,
    String? gemmaKey,
    String? vertexKey,
    List<AgentTool>? tools, // Native Tools Support
    dynamic ref, // Phase 89: Support both WidgetRef and Ref for proximity sync
  }) async {
    final effectiveMemory = memoryContext ?? systemInstruction;
    var config = modelConfig ?? AIModelConfig.geminiFlash;
    
    
    // config is already initialized above

    if (outputMode == 'json') {
      config = config.copyWith(responseMimeType: 'application/json');
    }

    final effectivePrompt = _buildPromptWithContext(prompt, context, memoryContext: effectiveMemory);
    
    // --- SEMANTIC CACHE CHECK ---
    if (ref != null && !forceMock) {
       try {
         final cache = ref.read(semanticCacheServiceProvider);
         final cachedResult = await cache.get(effectivePrompt, config);
         if (cachedResult != null) {
           _logger.i('EdgeAI: Cache HIT for "${prompt.substring(0, 15)}..."');
           if (ref != null) {
             ref.read(aiProximityProvider.notifier).setProximity(AIProximity.local);
             
             // Log Cache Hit
             ref.read(analyticsServiceProvider).logAiUsage(
                modelId: config.modelId,
                provider: 'cache',
                inputTokens: effectivePrompt.length ~/ 4,
                outputTokens: cachedResult.text.length ~/ 4,
                latencyMs: 50.0,
                isCacheHit: true,
             );
           }
           return cachedResult;
         }
       } catch (e) {
         _logger.w('EdgeAI: Cache check failed: $e');
       }
    }
    // ---------------------------
    
    final stopwatch = Stopwatch()..start();
    _logger.d('EdgeAI: Generating text via ${config.provider} (${config.modelId})');

    if (forceMock) {
      _logger.i('EdgeAI: forceMock is TRUE. Returning mock.');
      return await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
    }

    try {
      final result = await _generateWithTimeout(
        effectivePrompt,
        config,
        effectiveMemory,
        outputMode,
        imageBytes,
        imageMimeType,
        audioBytes,
        audioMimeType,
        videoBytes,
        videoMimeType,
        pdfBytes,
        pdfMimeType,
        apiKey,
        vertexKey,
        tools,
        ref,
      ).timeout(const Duration(seconds: 45));

      // --- SAVE TO CACHE ---
      if (ref != null && !forceMock && result.confidence > 0.5) {
         try {
           final cache = ref.read(semanticCacheServiceProvider);
           // Fire and forget save
           cache.set(effectivePrompt, config, result);
         } catch (e) {
            _logger.w('EdgeAI: Cache save failed: $e');
         }
         
         // --- ANALYTICS LOGGING ---
         if (ref != null) {
            try {
               final analytics = ref.read(analyticsServiceProvider);
               stopwatch.stop();
               // Estimate tokens: 4 chars ~ 1 token
               final inputTokens = effectivePrompt.length ~/ 4;
               final outputTokens = result.text.length ~/ 4;
               
               analytics.logAiUsage(
                  modelId: config.modelId,
                  provider: config.provider.name,
                  inputTokens: inputTokens,
                  outputTokens: outputTokens,
                  latencyMs: stopwatch.elapsedMilliseconds.toDouble(),
                  isCacheHit: false,
               );
            } catch (e) {
               _logger.w('EdgeAI: Analytics logging failed: $e');
            }
         }
         // -------------------------
      }
      // --------------------

      return result;
    } catch (e, stack) {
      if (e is TimeoutException) {
         _logger.e('EdgeAI: TIMEOUT reached. Returning Mock fallback.');
      } else {
         _logger.e('EdgeAI: ERROR during ${config.provider} generation', error: e, stackTrace: stack);
      }
      final mockRes = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
      if (ref != null) {
        ref.read(aiProximityProvider.notifier).setProximity(mockRes.proximity);
      }
      return mockRes;
    }
  }

  static Future<EdgeAIResult> _generateWithTimeout(
    String effectivePrompt,
    AIModelConfig config,
    String? effectiveMemory,
    String? outputMode,
    Uint8List? imageBytes,
    String? imageMimeType,
    Uint8List? audioBytes,
    String? audioMimeType,
    Uint8List? videoBytes,
    String? videoMimeType,
    Uint8List? pdfBytes,
    String? pdfMimeType,
    String? apiKey,
    String? vertexKey,
    List<AgentTool>? tools,
    dynamic ref,
  ) async {
    EdgeAIResult result;
    // On Web, prefer the Proxy to bypass App Check issues and CORS
    if (kIsWeb && config.provider == AIProvider.gemini) {
      try {
         _logger.i('EdgeAI: [WEB] Using Proxy as primary to ensure reliability.');
         
         // Build multimodal prompt for Proxy if needed
         dynamic proxyPrompt = effectivePrompt;
         if (imageBytes != null || audioBytes != null || videoBytes != null || pdfBytes != null) {
            final parts = <Map<String, dynamic>>[{"text": effectivePrompt}];
            if (imageBytes != null) parts.add({"inlineData": {"data": base64Encode(imageBytes), "mimeType": imageMimeType ?? "image/jpeg"}});
            if (audioBytes != null) parts.add({"inlineData": {"data": base64Encode(audioBytes), "mimeType": audioMimeType ?? "audio/mp3"}});
            if (videoBytes != null) parts.add({"inlineData": {"data": base64Encode(videoBytes), "mimeType": videoMimeType ?? "video/mp4"}});
            if (pdfBytes != null) parts.add({"inlineData": {"data": base64Encode(pdfBytes), "mimeType": pdfMimeType ?? "application/pdf"}});
            proxyPrompt = parts;
         }

         final proxyRes = await retry(
           () {
             final proxy = ref is Ref ? ref.read(aiProxyServiceProvider) : (ref as WidgetRef).read(aiProxyServiceProvider);
             return AIProxyService.generateContent(
              prompt: proxyPrompt, 
              config: config,
              systemInstruction: effectiveMemory,
              tools: tools?.map((t) => t.toFunctionSchema()).toList() ?? [], 
              thinking: config.modelId.contains('thinking') || effectivePrompt.toLowerCase().contains('deep research'),
              audio: config.modelId.contains('lyra'),
             );
           },
           maxAttempts: 2,
           delayFactor: const Duration(milliseconds: 500),
         );
         
         String text = "No proxy content.";
         final candidates = proxyRes['candidates'] as List?;
         if (candidates != null && candidates.isNotEmpty) {
           final candidate = candidates.first;
           final content = candidate['content'];
           final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
               final buffer = StringBuffer();
               for (var part in parts) {
                 if (part is Map) {
                   if (part.containsKey('thought')) {
                      buffer.writeln("> *Thinking: ${part['thought']}* \n");
                   }
                   if (part.containsKey('text')) {
                      buffer.write(part['text']);
                   }
                   // If it's a direct tool call from the parts list, preserve it for AssistantService
                   if (part.containsKey('executable_adunit')) {
                      buffer.write(jsonEncode(part));
                   }
                 }
               }
               text = buffer.toString();
               if (text.isEmpty && parts.isNotEmpty) {
                  text = jsonEncode(parts.first);
               }
            } else {
              _logger.w('EdgeAI: Proxy response has candidates but NO parts.');
            }
         } else {
           _logger.w('EdgeAI: Proxy response has NO candidates. Fallback text used.');
           if (proxyRes['error'] != null) {
             text = "Proxy Error: ${proxyRes['error']}";
           }
         }
         
         // Cleanup JSON if requested
         if (outputMode == 'json') {
           text = _stripMarkdown(text);
         }
         
         return EdgeAIResult(text, AIProximity.cloud, modelUsed: 'Proxy: ${config.modelId}');
      } catch (proxyErr) {
         _logger.w('EdgeAI: [WEB] Proxy failed: $proxyErr. Attempting direct SDK...');
         // If proxy fails, we can still TRY the direct SDK as a last resort
      }
    }

    switch (config.provider) {
      case AIProvider.gemini:
        try {
           result = await _generateFirebaseAI(
             effectivePrompt, 
             config, 
             vertexKeyOverride: vertexKey,
             apiKeyOverride: apiKey,
             imageBytes: imageBytes, 
             imageMimeType: imageMimeType,
             audioBytes: audioBytes,
             audioMimeType: audioMimeType,
             videoBytes: videoBytes,
             videoMimeType: videoMimeType,
             pdfBytes: pdfBytes,

             pdfMimeType: pdfMimeType,
             tools: tools,
           );
        } catch (e) {
           _logger.w('EdgeAI: FirebaseAI failed: $e. Using LiteRT/Mock fallback.');
           // Fallback to LiteRT (On-Device) if cloud fails
           try {
             result = await _generateLiteRT(effectivePrompt, config, errorMessage: e.toString());
           } catch (liteErr) {
             result = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
           }
         }
        break;
      case AIProvider.litert:
        result = await _generateLiteRT(effectivePrompt, config, errorMessage: null);
        break;
      default:
        // Fallback to FirebaseAI for everything else
           result = await _generateFirebaseAI(
             effectivePrompt, 
             config, 
             vertexKeyOverride: vertexKey,
             apiKeyOverride: apiKey,
             imageBytes: imageBytes, 
             imageMimeType: imageMimeType,
             audioBytes: audioBytes,
             audioMimeType: audioMimeType,
             videoBytes: videoBytes,
             videoMimeType: videoMimeType,
             pdfBytes: pdfBytes,

             pdfMimeType: pdfMimeType,
             tools: tools,
           );

    }
    
    // Phase 89: Global Proximity Sync (Only if ref is provided)
    if (ref != null) {
      ref.read(aiProximityProvider.notifier).setProximity(result.proximity);
    }
    
    return result;
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
    Uint8List? videoBytes,
    String? videoMimeType,
    Uint8List? pdfBytes,
    Uint8List? pdfBytes,
    String? pdfMimeType,
    List<AgentTool>? tools,
  }) async {
    final ai = FirebaseAI.vertexAI();
    // Note: apiKey and backend are now automatically handled by FirebaseAI based on project config
    
    // Map AgentTools to Firebase AI Schema
    final List<Tool> nativeTools = [];
    if (tools != null && tools.isNotEmpty) {
      final declarations = tools.map((t) {
         final schema = t.toFunctionSchema();
         return FunctionDeclaration(
           t.name,
           t.description,
           FunctionSchemaMapper.map(t.inputSchema), // Removed 'properties' wrapper as inputSchema is already correct map for mapper
         );
      }).toList();
      nativeTools.add(Tool(functionDeclarations: declarations));
    }
    
    // Config: If formatting as JSON, do NOT use tools (they conflict in Gemini 1.5)
    // BUT for Gemini 2.0+, tools + JSON might be supported. For now, stick to standard behavior.
    if (config.responseMimeType == 'application/json') {
       nativeTools.clear(); 
    } else {
       if (config.useGoogleSearch) {
         nativeTools.add(Tool.googleSearch());
       }
       // Code Execution enables dangerous Python sandbox, use carefully
       // nativeTools.add(Tool.codeExecution()); 
    }

    final model = ai.generativeModel(
      model: config.modelId,
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
      tools: nativeTools,
    );

    final parts = <Part>[TextPart(prompt)];
    
    if (imageBytes != null) {
      parts.add(InlineDataPart(imageMimeType ?? 'image/jpeg', imageBytes));
    }
    
    if (audioBytes != null) {
      parts.add(InlineDataPart(audioMimeType ?? 'audio/mp3', audioBytes));
    }

    if (videoBytes != null) {
      parts.add(InlineDataPart(videoMimeType ?? 'video/mp4', videoBytes));
    }

    if (pdfBytes != null) {
      parts.add(InlineDataPart(pdfMimeType ?? 'application/pdf', pdfBytes));
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

    // Cleanup JSON if requested
    if (config.responseMimeType == 'application/json') {
      fullText = _stripMarkdown(fullText);
    }

    return EdgeAIResult(fullText, AIProximity.cloud, modelUsed: config.modelId, confidence: confidence, sourceCitations: validSources);
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
    var effectiveConfig = config ?? AIModelConfig.geminiFlash;
     


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
           tools: [], // Stream doesn't support tools yet in this wrapper
           ref: ref
        );
        return;
     }

     try {
       final effectivePrompt = _buildPromptWithContext(prompt, context, memoryContext: effectiveMemory);
       final ai = FirebaseAI.vertexAI();
       
       final model = ai.generativeModel(
          model: effectiveConfig.modelId,
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


  static Future<String> generateImage(String prompt, {String? imagenKey, String? vertexKey, dynamic ref, Map<String, dynamic>? generationParams, String? modelId}) async {
    // 1. WEB PROXY PATH (Vertex Imagen - Primary)
    if (kIsWeb) {
       try {
         final effectiveModel = modelId ?? 'imagen-3.0-generate-001';
         debugPrint('EdgeAI: [WEB] Routing Image Generation via Secure Proxy ($effectiveModel)...');
         
         if (ref == null) throw Exception('Ref is required for Image Proxy in Web mode');
         final proxy = (ref is Ref) ? ref.read(aiProxyServiceProvider) : (ref as WidgetRef).read(aiProxyServiceProvider);

         final proxyResponse = await AIProxyService.generateImage(
           prompt: prompt,
           model: effectiveModel,
           config: generationParams,
         );
         
         final images = proxyResponse['images'] as List?;
         if (images != null && images.isNotEmpty) {
            final firstImg = images[0];
            final base64Image = firstImg['data'];
            if (base64Image != null) {
               return "data:${firstImg['mimeType'] ?? 'image/png'};base64,$base64Image";
            }
         }
       } catch (e) {
         debugPrint('EdgeAI: [WEB] Proxy Image Gen Failed: $e. Using fallback chain.');
       }
    } else {
      // 2. NATIVE CLOUD PATH (Firebase Functions)
      try {
        final result = await _generateCloudImage(prompt, modelId: modelId, config: generationParams);
        if (result != null) return result;
      } catch (e) {
        debugPrint('EdgeAI: [NATIVE] Cloud Image Gen Failed: $e');
      }
    }
    
    // 3. SAFE MOCKS (Fallback)
    debugPrint('EdgeAI: 🚨 ALL Image/AI services failed. Providing SAFE MOCK asset.');
    return "https://images.unsplash.com/photo-1535591273668-578e31182c4f?q=80&w=2070&auto=format&fit=crop"; 
  }

  static Future<String?> _generateCloudImage(String prompt, {String? modelId, Map<String, dynamic>? config}) async {
    try {
      debugPrint('EdgeAI: [NATIVE] Calling generate_image Cloud Function...');
      final response = await AIProxyService.generateImage(
        prompt: prompt,
        model: modelId ?? 'imagen-3.0-fast-generate-001',
        config: config,
      );

      final images = response['images'] as List?;
      if (images != null && images.isNotEmpty) {
        final firstImg = images[0];
        final base64Image = firstImg['data'];
        if (base64Image != null) {
          return "data:${firstImg['mimeType'] ?? 'image/png'};base64,$base64Image";
        }
      }
      return null;
    } catch (e) {
      debugPrint('EdgeAI: _generateCloudImage failed: $e');
      return null;
    }
  }

  static Future<String> generateVideo(String prompt, {String? modelId, bool isFinal = false, bool includeSubtitles = false, String? veoKey, String? vertexKey, dynamic ref, Function(double)? onProgress, Function(String)? onStatusMessage}) async {
    // Phase 95: Telemetry Injection via Ref if available
    final telemetry = ref?.read(telemetryServiceProvider);
    
    if (isFinal) {
      return await VideoGenerationService.generateFinal(prompt, modelId: modelId, confirmedByUser: true, onProgress: onProgress, onStatusMessage: onStatusMessage, telemetry: telemetry);
    } else {
      return await VideoGenerationService.generatePreview(prompt, modelId: modelId, onProgress: onProgress, telemetry: telemetry);
    }
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
    AIModelConfig config, {
    String? errorMessage,
  }) async {
    if (!_isLiteRTInitialized) await initLiteRT();

    _logger.d('EdgeAI: [LiteRT] Generating with ${config.modelId} (Accelerated: $_hasHwAccelerator)...');
    
    // Simulate On-Device Latency (fast!)
    await Future.delayed(const Duration(milliseconds: 150)); 
    
    // CRITICAL: Return meaningful error info if this was a fallback
    String sampleResponse;
    if (errorMessage != null) {
      sampleResponse = "LiteRT (${config.modelId}): Fallback due to error: $errorMessage. [Fast On-Device Preview]";
    } else {
      sampleResponse = "LiteRT (${config.modelId}): Analyzed request locally. [Fast On-Device Preview] Content generated successfully.";
    }
    
    return EdgeAIResult(
      sampleResponse, 
      AIProximity.local, 
      modelUsed: config.modelId,
      confidence: 0.85, 
    );
  }

  static String _stripMarkdown(String text) {
    if (text.startsWith('```')) {
      final firstLineEnd = text.indexOf('\n');
      final lastBackticks = text.lastIndexOf('```');
      if (firstLineEnd != -1 && lastBackticks > firstLineEnd) {
        return text.substring(firstLineEnd + 1, lastBackticks).trim();
      }
    }
    return text.trim();
  }
}
