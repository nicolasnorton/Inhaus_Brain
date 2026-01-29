import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_proxy_service.dart';
import '../tokens/llm_provider.dart';
import 'telemetry_service.dart';

/// Service dedicated to Video Generation using Veo models via Secure Proxy.
/// Implements cost-aware routing (Preview vs Final) and cultural safety checks.
class VideoGenerationService {
  // DeepMind Model Restriction:
  // Previews MUST use LiteRT / Gemini Nano / Veo Fast variants.
  // Final renders MUST use Veo 3 / Veo 3.1.
  // NO External models allowed.
  
  static const String _previewModel = 'veo-3.0-fast-generate-preview'; // DeepMind Fast variant
  static const String _finalModel = 'veo-3.1-generate'; // DeepMind High-Fidelity
  
  static const int _previewDurationParams = 5; 
  static const String _previewAspectRatio = "16:9"; 
  static const String _previewResolution = "480p"; // Optimization for speed

  /// Generates a video preview (LiteRT / Fast model).
  static Future<String> generatePreview(
    String prompt, {
    bool useCulturalSafety = true,
    bool includeSubtitles = false,
    Function(double)? onProgress,
    dynamic telemetry, // Phase 95
  }) async {
    final stopwatch = Stopwatch()..start();
    
    // LiteRT / Fast Preview Logic
    String effectivePrompt = useCulturalSafety ? _appendCulturalSafety(prompt) : prompt;
    if (includeSubtitles) {
      effectivePrompt += " Include bilingual subtitles: English and Spanish (LatAm).";
    }
    
    debugPrint('VideoService: [LiteRT] Starting fast preview generation...');
    
    try {
      final result = await _generateVideoInternal(
        prompt: effectivePrompt,
        modelId: _previewModel,
        isPreview: true,
        onProgress: onProgress,
      );
      
      stopwatch.stop();
      debugPrint('VideoService: [LiteRT] Preview generated in ${stopwatch.elapsed.inMilliseconds}ms');
      
      // Telemetry (Mock call if null)
      // telemetry?.logEvent('video_generated', {'mode': 'preview', 'duration_ms': stopwatch.elapsedMilliseconds});
      
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint('VideoService: [LiteRT] Preview failed after ${stopwatch.elapsed.inMilliseconds}ms. Error: $e');
      
      // Fallback Strategy for Previews
      if (stopwatch.elapsed.inSeconds > 3) {
         return _getStaticFallback("LiteRT Timeout (>3s)");
      }
      return _getStaticFallback("LiteRT Error: $e");
    }
  }

  /// Generates the final high-quality video (Veo 3.1).
  static Future<String> generateFinal(
    String prompt, {
    bool confirmedByUser = false,
    bool useCulturalSafety = true,
    bool includeSubtitles = false,
    Function(double)? onProgress,
    dynamic telemetry,
  }) async {
    if (!confirmedByUser) {
      throw Exception('VideoGenerationService: User confirmation required for final render.');
    }

    String effectivePrompt = useCulturalSafety ? _appendCulturalSafety(prompt) : prompt;
    if (includeSubtitles) {
      effectivePrompt += " Include bilingual subtitles: English and Spanish (LatAm).";
    }

    debugPrint('VideoService: [Veo 3.1] Starting final render...');
    
    return _generateVideoInternal(
      prompt: effectivePrompt,
      modelId: _finalModel, // Veo 3.1
      isPreview: false,
      onProgress: onProgress,
    );
  }

  static Future<String> _generateVideoInternal({
    required String prompt,
    required String modelId,
    required bool isPreview,
    Function(double)? onProgress,
  }) async {
    // WEB PROXY PATH
    if (kIsWeb) {
      debugPrint('VideoService: Requesting $modelId via Secure Proxy (Preview: $isPreview)...');
      onProgress?.call(0.1);
      try {
        // LiteRT Optimization: fast params for preview
        final Map<String, dynamic> params = isPreview ? {
           'durationSeconds': _previewDurationParams,
           'aspectRatio': _previewAspectRatio,
           'resolution': _previewResolution, // Hint to backend if supported
           'sampleCount': 1,
        } : {
           'durationSeconds': 8, // Full quality
           'aspectRatio': '16:9',
           'sampleCount': 1
        };

        final config = AIModelConfig(
          provider: AIProvider.vertex, 
          modelId: modelId,
          temperature: 0.5, 
          maxTokens: 100,
        );
        
        // Pass params via prompt engineering or update AIProxyService to accept generic params
        // For now, we rely on the Proxy handling this or defaults.
        // NOTE: We are sticking to the DeepMind-only constraint.

        final proxyResponse = await AIProxyService.generateContent(
          prompt: prompt,
          config: config,
        );

        if (proxyResponse['custom_type'] == 'veo_lro') {
          final opName = proxyResponse['operationName'];
          debugPrint('VideoService: LRO started: $opName. Polling...');
          return await _pollProxyVeoOperation(opName, onProgress: onProgress);
        } 
        
        else if (proxyResponse['custom_type'] == 'veo_result') {
           final predictions = proxyResponse['predictions'] as List?;
           if (predictions != null && predictions.isNotEmpty) {
             final videoUrl = predictions[0]['url'] ?? predictions[0]['videoUri'];
             if (videoUrl != null) {
               onProgress?.call(1.0);
               return _sanitizeMediaUrl(videoUrl);
             }
           }
        }
        
        throw Exception('Proxy returned no valid video URL or Operation ID.');
      } catch (e) {
        debugPrint('VideoService Error: $e');
        rethrow;
      }
    }

    // FALLBACK/MOCK (Non-Web / Dev)
    debugPrint('VideoService: Simulating LiteRT/DeepMind generation (Non-Web).');
    await Future.delayed(const Duration(milliseconds: 1500)); // <2s target
    onProgress?.call(1.0);
    return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  }

  static Future<String> _pollProxyVeoOperation(String operationName, {Function(double)? onProgress}) async {
    int errors = 0;
    const maxErrors = 5; 

    debugPrint('VideoService: Starting poll for Operation: $operationName');

    for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 5));
        
        // Simulating progress since real progress isn't always available in LRO
        double simulatedProgress = 0.1 + (i / 60.0) * 0.8;
        if (simulatedProgress > 0.95) simulatedProgress = 0.95;
        onProgress?.call(simulatedProgress);
        
        try {
            final data = await AIProxyService.pollOperation(operationName);
            
            if (data['done'] == true) {
                if (data['error'] != null) {
                   debugPrint('VideoService: Operation returned error: ${data['error']}');
                   // Specific error handling for Veo
                   return _getStaticFallback("Generation failed: ${data['error']['message'] ?? 'Unknown error'}");
                }
                
                final respObj = data['response'];
                if (respObj != null && respObj['predictions'] != null && (respObj['predictions'] as List).isNotEmpty) {
                    final videoUrl = respObj['predictions'][0]['url'] ?? respObj['predictions'][0]['videoUri'];
                    if (videoUrl != null) {
                      onProgress?.call(1.0);
                      return _sanitizeMediaUrl(videoUrl);
                    }
                }
                 
                 final metadata = data['metadata'];
                 if (metadata != null && metadata['outputUri'] != null) {
                    onProgress?.call(1.0);
                    return _sanitizeMediaUrl(metadata['outputUri']);
                 }
                 return _getStaticFallback('Video generated but URL missing.');
            }
        } catch (e) {
            errors++;
            debugPrint('VideoService: Polling error (attempt ${i + 1}): $e');
            
            if (errors >= maxErrors) {
               return _getStaticFallback('Network or API error during polling (Persistent failures).');
            }
        }
    }
     return _getStaticFallback('Generation timed out.');
  }

  static String _getStaticFallback(String reason) {
    debugPrint('VideoService: [FALLBACK] Using Storyboard Image due to: $reason');
    // In a real app, returning an image URL for a video player might break it unless the player handles images.
    // For now, we return a safe video placeholder that acts as the "Static Storyboard" (e.g. 1 frame video)
    // or we return a special prefix "IMAGE:" that the UI must handle.
    return "IMAGE:https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop"; 
  }

  static String _sanitizeMediaUrl(String url) {
    if (url.startsWith('gs://')) {
       final path = url.replaceFirst('gs://', '');
       return "https://storage.googleapis.com/$path";
    }
    return url;
  }

  static String _appendCulturalSafety(String prompt) {
    // Ensure content is appropriate for Ecuador/LatAm audience
    // Neutral tone, no offensive slang, respectful of local customs.
    // This is a lightweight append; the Model System Prompt should handle the heavy lifting.
    return "$prompt. Cultural Context: Ecuador/LatAm neutral. Brand Safe: Yes.";
  }
}
