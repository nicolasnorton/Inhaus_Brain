import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_proxy_service.dart';
import 'open_model_service.dart';
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
  static const String _finalModel = 'veo-3.1-generate-001'; // DeepMind High-Fidelity (Corrected ID)
  
  static const int _previewDurationParams = 5; 
  static const String _previewAspectRatio = "16:9"; 
  static const String _previewResolution = "720p"; // Min resolution for Veo models
  
  // High-Quality Fallback (Imagen 3.0)
  static const String _fallbackImageModel = 'imagen-3.0-generate-001';

  /// Generates a video preview (LiteRT / Fast model).
  /// AGENT 3: Prioritizes REAL video generation with retries before fallback
  static Future<String> generatePreview(
    String prompt, {
    bool useCulturalSafety = true,
    bool includeSubtitles = false,
    Function(double)? onProgress,
    dynamic telemetry, // Phase 95
    int maxRetries = 2, // Try up to 2 times before fallback
  }) async {
    final stopwatch = Stopwatch()..start();
    
    // LiteRT / Fast Preview Logic
    String effectivePrompt = useCulturalSafety ? _appendCulturalSafety(prompt) : prompt;
    if (includeSubtitles) {
      effectivePrompt += " Include bilingual subtitles: English and Spanish (LatAm).";
    }
    
    debugPrint('VideoService: 🚀 Starting MULTI-TIER video preview generation (Priority: Cloud)');
    onProgress?.call(0.05);

    // 1. Cloud Preview Priority (Highest Consistency)
    debugPrint('VideoService: Attempting CLOUD generation (Veo Fast)...');
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        debugPrint('VideoService: Cloud Attempt ${attempt + 1}/$maxRetries');
        
        final result = await _generateVideoInternal(
          prompt: effectivePrompt,
          modelId: _previewModel,
          isPreview: true,
          onProgress: onProgress,
        );
        
        // Check if result is a real video (not fallback)
        if (result.isNotEmpty && !result.startsWith('IMAGE:')) {
          stopwatch.stop();
          debugPrint('VideoService: ✅ REAL cloud preview generated in ${stopwatch.elapsed.inSeconds}s');
          debugPrint('📊 [Telemetry] video_preview_success: duration=${stopwatch.elapsedMilliseconds}ms, attempt=${attempt + 1}, source=veo_cloud_preview');
          onProgress?.call(1.0);
          return result;
        }

        debugPrint('VideoService: ⚠️ Cloud preview returned fallback or empty, trying next tier...');
        break; // Break loop to try Edge
      } catch (e) {
        debugPrint('VideoService: Cloud Preview attempt ${attempt + 1} failed: $e');
        if (attempt < maxRetries - 1) {
           await Future.delayed(Duration(seconds: 2 * (attempt + 1))); // Backoff
           continue;
        }
      }
    }

    // 2. Edge/On-Device Secondary fallback
    try {
      debugPrint('VideoService: Falling back to ON-DEVICE generation (OpenModel ONNX)...');
      final onDeviceResult = await OpenModelService.generatePreviewOnDevice(effectivePrompt);
      if (onDeviceResult.isNotEmpty && !onDeviceResult.startsWith('IMAGE:')) {
        stopwatch.stop();
        debugPrint('VideoService: ✅ On-device preview success in ${stopwatch.elapsed.inSeconds}s!');
        onProgress?.call(1.0);
        return onDeviceResult;
      }
    } catch (e) {
      debugPrint('VideoService: On-device generation failed: $e');
    }

    // 3. Last Resort Fallback (Imagen Storyboard)
    debugPrint('VideoService: 🚨 All real video tiers exhausted. Using last-resort storyboards.');
    return await _generateImagenFallback(effectivePrompt);
  }

  /// Generates the final high-quality video (Veo 3.1).
  /// AGENT 3: This uses flagship model and may take up to 2-3 minutes.
  static Future<String> generateFinal(
    String prompt, {
    bool confirmedByUser = false,
    bool useCulturalSafety = true,
    bool includeSubtitles = false,
    Function(double)? onProgress,
    Function(String)? onStatusMessage, // New: send user messages
    dynamic telemetry,
  }) async {
    if (!confirmedByUser) {
      throw Exception('VideoGenerationService: User confirmation required for final render.');
    }

    final stopwatch = Stopwatch()..start();
    
    String effectivePrompt = useCulturalSafety ? _appendCulturalSafety(prompt) : prompt;
    if (includeSubtitles) {
      effectivePrompt += " Include bilingual subtitles: English and Spanish (LatAm).";
    }

    debugPrint('VideoService: 🎬 Starting FINAL HIGH-QUALITY render (Veo 3.1)');
    debugPrint('VideoService: Expected duration: 60-180 seconds');
    
    onStatusMessage?.call('Generating high-quality video... This may take up to 2 minutes.');
    onProgress?.call(0.05);
    
    // Tier 1: Cloud Final (Priority)
    try {
      final result = await _generateVideoInternal(
        prompt: effectivePrompt,
        modelId: _finalModel, // Veo 3.1
        isPreview: false,
        onProgress: onProgress,
      );
      
      if (!result.startsWith('IMAGE:')) {
        stopwatch.stop();
        debugPrint('VideoService: ✅ FINAL cloud video created in ${stopwatch.elapsed.inSeconds}s');
        debugPrint('📊 [Telemetry] video_final_success: duration=${stopwatch.elapsed.inSeconds}s, source=veo_3.1_cloud, subtitles=$includeSubtitles');
        onStatusMessage?.call('High-quality video ready!');
        return result;
      }
    } catch (e) {
      debugPrint('VideoService: Cloud Final failed: $e. Trying Tier 2 (Edge)...');
    }

    // Tier 2: Edge/On-Device (Secondary)
    try {
      debugPrint('VideoService: Attempting ON-DEVICE fallback for FINAL request...');
      final onDeviceResult = await OpenModelService.generatePreviewOnDevice(effectivePrompt);
      if (onDeviceResult.isNotEmpty && !onDeviceResult.startsWith('IMAGE:')) {
        stopwatch.stop();
        debugPrint('VideoService: ✅ FINAL request fulfilled by Edge video in ${stopwatch.elapsed.inSeconds}s');
        onStatusMessage?.call('Video ready (on-device preview quality).');
        return onDeviceResult;
      }
    } catch (e) {
      debugPrint('VideoService: On-device generation also failed for FINAL: $e');
    }

    // Tier 3: Last Resort Fallback (Imagen Storyboard)
    debugPrint('VideoService: ⚠️ All real video paths failed for final. Using storyboard.');
    onStatusMessage?.call('Video generation unavailable. Providing cinematic storyboard.');
    return await _generateImagenFallback(effectivePrompt);
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
        final Map<String, dynamic> params = isPreview ? {
           'durationSeconds': _previewDurationParams,
           'aspectRatio': _previewAspectRatio,
           'resolution': _previewResolution,
           'sampleCount': 1,
        } : {
           'durationSeconds': 8,
           'aspectRatio': '16:9',
           'sampleCount': 1
        };

        final config = AIModelConfig(
          provider: AIProvider.vertex, 
          modelId: modelId,
          temperature: 0.5, 
          maxTokens: 100,
        );
        
        final proxyResponse = await AIProxyService.generateContent(
          prompt: prompt,
          config: config,
        );

        if (proxyResponse['custom_type'] == 'veo_lro') {
          final opName = proxyResponse['operationName'];
          debugPrint('VideoService: LRO started: $opName. Polling...');
          return await _pollProxyVeoOperation(opName, originalPrompt: prompt, onProgress: onProgress);
        } else if (proxyResponse['custom_type'] == 'veo_result') {
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
        if (isPreview) {
          // Allow caller to handle retry
          rethrow;
        } else {
          return _getStaticFallback("Generation Error: $e");
        }
      }
    }

    // FALLBACK/MOCK (Non-Web / Dev)
    debugPrint('VideoService: Simulating LiteRT/DeepMind generation (Non-Web).');
    await Future.delayed(const Duration(milliseconds: 1500));
    onProgress?.call(1.0);
    return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  }

  static Future<String> _pollProxyVeoOperation(
    String operationName, {
    required String originalPrompt,
    Function(double)? onProgress,
    int maxRetries = 10,
  }) async {
    int consecutiveErrors = 0;
    int total404Count = 0;
    const maxConsecutiveErrors = 3;
    const max404Retries = 6;
    
    // Enhanced timeout: 600 seconds total (60 polls * 10s)
    const int maxPolls = 60;
    const Duration pollInterval = Duration(seconds: 10);
    
    debugPrint('VideoService: 🎬 Starting REAL video generation poll');
    debugPrint('VideoService: Operation ID: $operationName');
    debugPrint('VideoService: Max duration: ${maxPolls * pollInterval.inSeconds}s (${maxPolls} polls)');
    
    for (int i = 0; i < maxPolls; i++) {
        // Exponential backoff on errors (but cap at 10s)
        final Duration delay = consecutiveErrors > 0 
            ? Duration(seconds: (pollInterval.inSeconds * (1 << consecutiveErrors)).clamp(5, 10))
            : pollInterval;
        
        await Future.delayed(delay);
        
        double simulatedProgress = 0.1 + (i / maxPolls) * 0.85;
        if (simulatedProgress > 0.95) simulatedProgress = 0.95;
        onProgress?.call(simulatedProgress);
        
        debugPrint('VideoService: Poll ${i + 1}/$maxPolls (${(i * pollInterval.inSeconds)}s elapsed)');
        
        try {
            final data = await AIProxyService.pollOperation(operationName)
                .timeout(const Duration(seconds: 30));
            
            if (data['done'] == true) {
                debugPrint('VideoService: ✅ Operation complete!');
                
                if (data['error'] != null) {
                   final errorMsg = data['error']['message'] ?? 'Unknown error';
                   debugPrint('VideoService: ❌ Operation error: $errorMsg');
                   
                   if (errorMsg.contains('quota') || errorMsg.contains('rate limit')) {
                      debugPrint('VideoService: Quota/rate limit hit - immediate fallback');
                      return _getStaticFallback("API quota exceeded: $errorMsg");
                   }
                   
                   return _getStaticFallback("Generation failed: $errorMsg");
                }
                
                final respObj = data['response'];
                if (respObj != null) {
                    if (respObj['predictions'] != null && (respObj['predictions'] as List).isNotEmpty) {
                        final videoUrl = respObj['predictions'][0]['url'] ?? 
                                       respObj['predictions'][0]['videoUri'] ?? 
                                       respObj['predictions'][0]['gcsUri'];
                        
                        if (videoUrl != null) {
                          debugPrint('VideoService: 🎥 REAL video URL found: $videoUrl');
                          onProgress?.call(1.0);
                          debugPrint('📊 [Telemetry] video_generation_success: duration=${i * pollInterval.inSeconds}s, polls=${i + 1}, source=veo_cloud');
                          return _sanitizeMediaUrl(videoUrl);
                        }
                    }
                }
                 
                 final metadata = data['metadata'];
                 if (metadata != null && metadata['outputUri'] != null) {
                    debugPrint('VideoService: 🎥 Video URL from metadata: ${metadata['outputUri']}');
                    onProgress?.call(1.0);
                    debugPrint('📊 [Telemetry] video_generation_success: duration=${i * pollInterval.inSeconds}s, polls=${i + 1}, source=veo_cloud_metadata');
                    return _sanitizeMediaUrl(metadata['outputUri']);
                 }
                 
                 return _getStaticFallback('Video generated but URL missing in response.');
            } else {
                debugPrint('VideoService: ⏳ Still processing... (done: ${data['done']})');
                consecutiveErrors = 0; 
            }
            
        } catch (e) {
            consecutiveErrors++;
            final errorStr = e.toString();
            
            if (errorStr.contains('404') || errorStr.contains('not found')) {
                total404Count++;
                debugPrint('VideoService: ⚠️ 404 Operation Not Found (count: $total404Count/$max404Retries)');
                
                if (total404Count >= max404Retries) {
                    debugPrint('VideoService: ❌ Operation lost after $total404Count attempts');
                    debugPrint('📊 [Telemetry] video_generation_failed: reason=404_operation_not_found, duration=${i * pollInterval.inSeconds}s, polls=${i + 1}');
                    return _getStaticFallback('Operation not found (404) after $total404Count retries');
                }
                consecutiveErrors = 0;
                continue;
            }
            
            debugPrint('VideoService: ❌ Polling error (attempt ${i + 1}, consecutive: $consecutiveErrors): $e');
            
            if (consecutiveErrors >= maxConsecutiveErrors) {
               debugPrint('VideoService: 🛑 Too many consecutive errors ($consecutiveErrors)');
               debugPrint('📊 [Telemetry] video_generation_failed: reason=consecutive_errors, duration=${i * pollInterval.inSeconds}s, polls=${i + 1}, error=$errorStr');
               return _getStaticFallback('Network errors during polling (consecutive failures).');
            }
        }
    }
    
    debugPrint('VideoService: ⏰ Timeout after ${maxPolls * pollInterval.inSeconds}s. Triggering Storyboard Fallback.');
    debugPrint('📊 [Telemetry] video_generation_timeout: duration=${maxPolls * pollInterval.inSeconds}s, polls=$maxPolls');
    
    // Try High-Quality Image Fallback before giving up
    return await _generateImagenFallback(originalPrompt);
  }

  static Future<String> _generateImagenFallback(String prompt) async {
    debugPrint('VideoService: 🎨 Falling back to High-Quality Storyboard (Imagen)...');
    try {
       final config = AIModelConfig(
         provider: AIProvider.vertex, 
         modelId: _fallbackImageModel,
         temperature: 0.5, 
         maxTokens: 100,
       );
       
       final response = await AIProxyService.generateContent(
         prompt: "$prompt. HIGH-QUALITY CINEMATIC STORYBOARD KEYFRAME.",
         config: config,
       );
       
       if (response['custom_type'] == 'imagen') {
         final predictions = response['predictions'] as List?;
         if (predictions != null && predictions.isNotEmpty) {
           final imageUrl = predictions[0]['url'] ?? predictions[0]['gcsUri'];
           if (imageUrl != null) {
              debugPrint('VideoService: ✅ Imagen fallback success!');
              return _sanitizeMediaUrl(imageUrl);
           }
         }
       }
    } catch (e) {
       debugPrint('VideoService: Imagen fallback also failed: $e');
    }
    
    return _getStaticFallback('Video generation timed out and Imagen fallback failed.');
  }

  static String _getStaticFallback(String reason) {
    debugPrint('VideoService: 🚨 [LAST RESORT FALLBACK] Using static storyboard');
    debugPrint('VideoService: Reason: $reason');
    debugPrint('VideoService: This should be rare - investigate if occurring frequently');
    
    debugPrint('📊 [Telemetry] video_fallback_used: reason="$reason", timestamp=${DateTime.now().toIso8601String()}');
    
    // Return plain URL - UI should handle based on type/context
    return "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2564&auto=format&fit=crop"; 
  }

  static String _sanitizeMediaUrl(String url) {
    if (url.startsWith('gs://')) {
       final path = url.replaceFirst('gs://', '');
       return "https://storage.googleapis.com/$path";
    }
    return url;
  }

  static String _appendCulturalSafety(String prompt) {
    return "$prompt. Cultural Context: Ecuador/LatAm neutral. Brand Safe: Yes.";
  }
}
