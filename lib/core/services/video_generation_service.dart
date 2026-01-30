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
    Function(String)? onStatusMessage, // NEW: User status messages
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
    onStatusMessage?.call('Initializing video generation...');

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
          onStatusMessage: onStatusMessage,
        );
        
        // Check if result is a real video (not fallback)
        if (result.isNotEmpty && !result.startsWith('IMAGE:')) {
          stopwatch.stop();
          debugPrint('VideoService: ✅ REAL cloud preview generated in ${stopwatch.elapsed.inSeconds}s');
          debugPrint('📊 [Telemetry] video_preview_success: duration=${stopwatch.elapsedMilliseconds}ms, attempt=${attempt + 1}, source=veo_cloud_preview');
          onProgress?.call(1.0);
          onStatusMessage?.call('Preview ready!');
          return result;
        }

        debugPrint('VideoService: ⚠️ Cloud preview returned fallback or empty, trying next tier...');
        break; // Break loop to try Edge
      } catch (e) {
        debugPrint('VideoService: Cloud Preview attempt ${attempt + 1} failed: $e');
        if (attempt < maxRetries - 1) {
           onStatusMessage?.call('Retrying... (attempt ${attempt + 2}/$maxRetries)');
           await Future.delayed(Duration(seconds: 2 * (attempt + 1))); // Backoff
           continue;
        }
      }
    }

    // 2. Edge/On-Device Secondary fallback
    try {
      debugPrint('VideoService: Falling back to ON-DEVICE generation (OpenModel ONNX)...');
      onStatusMessage?.call('Trying alternative generation method...');
      final onDeviceResult = await OpenModelService.generatePreviewOnDevice(effectivePrompt);
      if (onDeviceResult.isNotEmpty && !onDeviceResult.startsWith('IMAGE:')) {
        stopwatch.stop();
        debugPrint('VideoService: ✅ On-device preview success in ${stopwatch.elapsed.inSeconds}s!');
        onProgress?.call(1.0);
        onStatusMessage?.call('Preview ready!');
        return onDeviceResult;
      }
    } catch (e) {
      debugPrint('VideoService: On-device generation failed: $e');
    }

    // 3. Last Resort Fallback (Imagen Storyboard)
    debugPrint('VideoService: 🚨 All real video tiers exhausted. Using last-resort storyboards.');
    onStatusMessage?.call('Using static storyboard (video unavailable)');
    final result = await _generateImagenFallback(effectivePrompt);
    return result.startsWith('https') ? 'IMAGE:$result' : result;
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
    Function(String)? onStatusMessage,
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
          return await _pollProxyVeoOperation(
            opName, 
            originalPrompt: prompt, 
            onProgress: onProgress,
            onStatusMessage: onStatusMessage,
          );
        } else if (proxyResponse['custom_type'] == 'veo_result') {
           final predictions = proxyResponse['predictions'] as List?;
           if (predictions != null && predictions.isNotEmpty) {
             final videoUrl = predictions[0]['url'] ?? predictions[0]['videoUri'];
             if (videoUrl != null) {
               onProgress?.call(1.0);
               onStatusMessage?.call('Video ready!');
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
          final fallback = _getStaticFallbackUrl("Generation Error: $e");
          return 'IMAGE:$fallback';
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
    Function(String)? onStatusMessage,
    int maxRetries = 1, // Allow 1 fresh retry on persistent error
  }) async {
    int consecutiveErrors = 0;
    int total404Count = 0;
    int persistent400Count = 0;
    const maxConsecutiveErrors = 5;
    const max404Retries = 20; // Increased for Veo propagation delay
    const maxPersistent400 = 3; // Trigger fresh retry after 3x 400 errors
    
    // EXTENDED TIMEOUT: 600s (60 polls with progressive intervals)
    const int maxPolls = 60;
    
    debugPrint('VideoService: 🎬 Starting REAL Veo video poll (Operation: $operationName)');
    debugPrint('VideoService: ⏱️ Max duration: ~600 seconds (2-5 min expected)');
    onStatusMessage?.call('Generating your video... This may take 2-5 minutes.');
    
    final pollStartTime = DateTime.now();
    
    for (int i = 0; i < maxPolls; i++) {
        // PROGRESSIVE BACKOFF STRATEGY
        int backoffSeconds = 10; // Default
        if (i > 10 && i <= 30) backoffSeconds = 15;  // Polls 11-30: patience phase
        if (i > 30) backoffSeconds = 20;              // Polls 31+: final waiting
        
        // EXPONENTIAL BACKOFF ON ERRORS
        if (consecutiveErrors > 0) {
          int errorBackoff = 5 * (1 << (consecutiveErrors - 1)); // 5s, 10s, 20s
          backoffSeconds = errorBackoff.clamp(5, 20);
        }

        await Future.delayed(Duration(seconds: backoffSeconds));
        
        // Smoothed progress (never reach 100% until done)
        double simulatedProgress = 0.1 + (i / maxPolls) * 0.85;
        if (simulatedProgress > 0.95) simulatedProgress = 0.95;
        onProgress?.call(simulatedProgress);
        
        final elapsed = DateTime.now().difference(pollStartTime);
        final elapsedSec = elapsed.inSeconds;
        
        // User-friendly status updates every 30s
        if (i > 0 && i % 3 == 0) {
          onStatusMessage?.call('Still generating... (${elapsedSec}s elapsed)');
        }
        
        debugPrint('VideoService: 🔄 Poll ${i + 1}/$maxPolls (${elapsedSec}s elapsed, next in ${backoffSeconds}s)');
        
        try {
            final data = await AIProxyService.pollOperation(operationName)
                .timeout(const Duration(seconds: 50));
            
            debugPrint('VideoService: 📥 Poll response: done=${data['done']}, hasError=${data['error'] != null}');
            
            if (data['done'] == true) {
                if (data['error'] != null) {
                   final errorMsg = data['error']['message'] ?? 'Unknown error';
                   final errorCode = data['error']['code'];
                   debugPrint('VideoService: ❌ Operation failed: $errorMsg (code: $errorCode)');
                   
                   // Quota/Rate Limit - Immediate fallback
                   if (errorMsg.contains('quota') || errorMsg.contains('rate limit')) {
                      debugPrint('📊 [Telemetry] video_quota_exceeded: elapsed=${elapsedSec}s');
                      onStatusMessage?.call('Video generation quota exceeded. Using fallback.');
                      final fallback = _getStaticFallbackUrl("Quota exceeded");
                      return 'IMAGE:$fallback';
                   }
                   
                   // INVALID_ARGUMENT - Should be fixed now, but handle gracefully
                   if (errorMsg.contains('must be a Long') || errorMsg.contains('INVALID_ARGUMENT')) {
                      debugPrint('VideoService: 🚨 CRITICAL: INVALID_ARGUMENT still occurring!');
                      debugPrint('📊 [Telemetry] video_invalid_argument_error: operation=$operationName');
                      try {
                        onStatusMessage?.call('Trying alternative generation method...');
                        final edgeResult = await OpenModelService.generatePreviewOnDevice(originalPrompt);
                        if (edgeResult.isNotEmpty && !edgeResult.startsWith('IMAGE:')) return edgeResult;
                      } catch (e) { /* Edge fallback failed */ }
                      final fallback = _getStaticFallbackUrl("Operation format error");
                      return 'IMAGE:$fallback';
                   }
                   
                   // Generic error fallback
                   debugPrint('📊 [Telemetry] video_generation_error: reason="$errorMsg", elapsed=${elapsedSec}s');
                   onStatusMessage?.call('Generation failed. Using fallback.');
                   final fallback = _getStaticFallbackUrl(errorMsg);
                   return 'IMAGE:$fallback';
                }
                
                // SUCCESS - Extract video URL
                final respObj = data['response'];
                if (respObj != null) {
                    final predictions = respObj['predictions'];
                    if (predictions != null && (predictions as List).isNotEmpty) {
                        final pred = predictions[0];
                        final videoUrl = pred['url'] ?? pred['videoUri'] ?? pred['gcsUri'];
                        
                        if (videoUrl != null) {
                          final totalTime = DateTime.now().difference(pollStartTime);
                          debugPrint('VideoService: ✅ REAL video generated in ${totalTime.inSeconds}s!');
                          debugPrint('📊 [Telemetry] video_success: duration=${totalTime.inMilliseconds}ms, polls=${i + 1}, url_preview=${videoUrl.substring(0, 50)}');
                          onStatusMessage?.call('Video ready!');
                          onProgress?.call(1.0);
                          return _sanitizeMediaUrl(videoUrl);
                        }
                    }
                }
                 
                 // Check metadata for output
                 final metadata = data['metadata'];
                 if (metadata != null && metadata['outputUri'] != null) {
                    debugPrint('VideoService: 🎥 Video from metadata: ${metadata['outputUri']}');
                    onProgress?.call(1.0);
                    onStatusMessage?.call('Video ready!');
                    return _sanitizeMediaUrl(metadata['outputUri']);
                 }
                 
                 debugPrint('VideoService: ⚠️ Operation done but no URL found');
                 debugPrint('📊 [Telemetry] video_missing_url: response=${data.toString().substring(0, 200)}');
                 return 'IMAGE:${_getStaticFallbackUrl('Video generated but URL missing')}';
            } else {
                // Still processing
                debugPrint('VideoService: ⏳ Processing... (poll ${i + 1})');
                consecutiveErrors = 0;
                persistent400Count = 0;
            }
            
        } catch (e) {
            consecutiveErrors++;
            final errorStr = e.toString();
            
            debugPrint('VideoService: ⚠️ Poll error (${consecutiveErrors}/$maxConsecutiveErrors): $e');
            
            // 404 handling - Operation may still be propagating
            if (errorStr.contains('404') || errorStr.contains('not found')) {
                total404Count++;
                debugPrint('VideoService: 404 Not Found ($total404Count/$max404Retries) - Waiting for operation to propagate...');
                if (total404Count >= max404Retries) {
                    debugPrint('📊 [Telemetry] video_404_timeout: after_retries=$total404Count, elapsed=${elapsedSec}s');
                    onStatusMessage?.call('Operation not found after ${total404Count} retries.');
                    final fallback = _getStaticFallbackUrl('Operation lost (404)');
                    return 'IMAGE:$fallback';
                }
                consecutiveErrors = 0; // Don't penalize 404s
                continue;
            }
            
            // 400 handling - May indicate operation name issue
            if (errorStr.contains('400') || errorStr.contains('INVALID_ARGUMENT')) {
                persistent400Count++;
                debugPrint('VideoService: 400 Error ($persistent400Count/$maxPersistent400)');
                
                // After 3 consecutive 400s, try fresh generation (if retries available)
                if (persistent400Count >= maxPersistent400 && maxRetries > 0) {
                    debugPrint('VideoService: 🔄 Persistent 400 errors. Attempting fresh generation retry...');
                    debugPrint('📊 [Telemetry] video_fresh_retry: after_400_count=$persistent400Count');
                    onStatusMessage?.call('First attempt failed. Retrying generation...');
                    
                    // Trigger fresh generation (recursive call with maxRetries-1)
                    try {
                      return await generatePreview(
                        originalPrompt,
                        onProgress: onProgress,
                        maxRetries: maxRetries - 1,
                      );
                    } catch (retryErr) {
                      debugPrint('VideoService: Fresh retry also failed: $retryErr');
                    }
                }
            }
            
            // Network errors - Use backoff
            if (consecutiveErrors >= maxConsecutiveErrors) {
               debugPrint('📊 [Telemetry] video_network_failure: consecutive_errors=$consecutiveErrors');
               onStatusMessage?.call('Network errors occurred. Using fallback.');
               final fallback = _getStaticFallbackUrl('Network failures');
               return 'IMAGE:$fallback';
            }
        }
    }
    
    // TIMEOUT - Exhausted all polls
    final totalTime = DateTime.now().difference(pollStartTime);
    debugPrint('VideoService: ⏰ Polling timeout after ${totalTime.inSeconds}s (${maxPolls} polls)');
    debugPrint('📊 [Telemetry] video_timeout: duration=${totalTime.inSeconds}s, polls=$maxPolls');
    onStatusMessage?.call('Video generation timed out. Using fallback image.');
    
    final fallback = await _generateImagenFallback(originalPrompt);
    return fallback.startsWith('https') ? 'IMAGE:$fallback' : fallback;
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
    
    final staticUrl = _getStaticFallbackUrl('Video generation timed out and Imagen fallback failed.');
    return 'IMAGE:$staticUrl';
  }

  static String _getStaticFallbackUrl(String reason) {
    debugPrint('VideoService: 🚨 [LAST RESORT FALLBACK] Using static storyboard');
    debugPrint('VideoService: Reason: $reason');
    debugPrint('VideoService: This should be rare - investigate if occurring frequently');
    
    debugPrint('📊 [Telemetry] video_fallback_used: reason="$reason", timestamp=${DateTime.now().toIso8601String()}');
    
    // Return clean URL - prefixing is handled at the service boundary
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
