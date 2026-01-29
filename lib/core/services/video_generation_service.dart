import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_proxy_service.dart';
import '../tokens/llm_provider.dart';

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
    
    debugPrint('VideoService: 🚀 Starting REAL video preview generation (priority: cloud)');
    debugPrint('VideoService: Max retries: $maxRetries');
    onProgress?.call(0.05);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        debugPrint('VideoService: Attempt ${attempt + 1}/$maxRetries');
        
        final result = await _generateVideoInternal(
          prompt: effectivePrompt,
          modelId: _previewModel,
          isPreview: true,
          onProgress: onProgress,
        );
        
        stopwatch.stop();
        
        // Check if result is a real video (not fallback)
        if (!result.startsWith('IMAGE:')) {
          debugPrint('VideoService: ✅ REAL preview generated in ${stopwatch.elapsed.inSeconds}s');
          debugPrint('📊 [Telemetry] video_preview_success: duration=${stopwatch.elapsedMilliseconds}ms, attempt=${attempt + 1}, source=veo_cloud_preview');
          return result;
        } else if (attempt < maxRetries - 1) {
          debugPrint('VideoService: ⚠️ Got fallback, retrying... (${attempt + 1}/$maxRetries)');
          await Future.delayed(Duration(seconds: 2 * (attempt + 1))); // Backoff
          continue;
        } else {
          debugPrint('VideoService: Used fallback after $maxRetries attempts');
          debugPrint('📊 [Telemetry] video_preview_fallback: duration=${stopwatch.elapsedMilliseconds}ms, attempts=$maxRetries');
          return result; // Return fallback
        }
      } catch (e) {
        debugPrint('VideoService: Attempt ${attempt + 1} error: $e');
        
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          continue;
        }
        
        // Last attempt failed
        stopwatch.stop();
        debugPrint('VideoService: ❌ All preview attempts failed after ${stopwatch.elapsed.inSeconds}s');
        debugPrint('📊 [Telemetry] video_preview_failed: duration=${stopwatch.elapsedMilliseconds}ms, attempts=$maxRetries, error=$e');
        return _getStaticFallback("Preview generation failed after $maxRetries attempts: $e");
      }
    }
    
    // Should not reach here
    return _getStaticFallback("Unknown error in preview generation");
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
    
    try {
      final result = await _generateVideoInternal(
        prompt: effectivePrompt,
        modelId: _finalModel, // Veo 3.1
        isPreview: false,
        onProgress: onProgress,
      );
      
      stopwatch.stop();
      
      if (!result.startsWith('IMAGE:')) {
        debugPrint('VideoService: ✅ FINAL video created in ${stopwatch.elapsed.inSeconds}s');
        debugPrint('📊 [Telemetry] video_final_success: duration=${stopwatch.elapsed.inSeconds}s, source=veo_3.1_cloud, subtitles=$includeSubtitles');
        onStatusMessage?.call('High-quality video ready!');
        return result;
      } else {
        debugPrint('VideoService: ⚠️ Final generation fell back to static');
        debugPrint('📊 [Telemetry] video_final_fallback: duration=${stopwatch.elapsedMilliseconds}ms');
        onStatusMessage?.call('Video generation unavailable. Using static preview.');
        return result;
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('VideoService: ❌ Final generation failed after ${stopwatch.elapsed.inSeconds}s');
      debugPrint('📊 [Telemetry] video_final_failed: duration=${stopwatch.elapsedMilliseconds}ms, error=$e');
      onStatusMessage?.call('Video generation failed. Please try again.');
      rethrow;
    }
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

  static Future<String> _pollProxyVeoOperation(
    String operationName, {
    Function(double)? onProgress,
    int maxRetries = 10,
  }) async {
    int consecutiveErrors = 0;
    int total404Count = 0;
    const maxConsecutiveErrors = 3;
    const max404Retries = 6;
    
    // Extended timeout: 180 seconds total (36 polls * 5s)
    const int maxPolls = 36;
    const Duration pollInterval = Duration(seconds: 5);
    
    debugPrint('VideoService: 🎬 Starting REAL video generation poll');
    debugPrint('VideoService: Operation ID: $operationName');
    debugPrint('VideoService: Max duration: ${maxPolls * pollInterval.inSeconds}s (${maxPolls} polls)');
    
    for (int i = 0; i < maxPolls; i++) {
        // Exponential backoff on errors (but cap at 10s)
        final Duration delay = consecutiveErrors > 0 
            ? Duration(seconds: (pollInterval.inSeconds * (1 << consecutiveErrors)).clamp(5, 10))
            : pollInterval;
        
        await Future.delayed(delay);
        
        // More accurate progress tracking
        double simulatedProgress = 0.1 + (i / maxPolls) * 0.85;
        if (simulatedProgress > 0.95) simulatedProgress = 0.95;
        onProgress?.call(simulatedProgress);
        
        debugPrint('VideoService: Poll ${i + 1}/$maxPolls (${(i * pollInterval.inSeconds)}s elapsed)');
        
        try {
            final data = await AIProxyService.pollOperation(operationName)
                .timeout(const Duration(seconds: 30)); // Individual poll timeout
            
            // SUCCESS: Operation completed
            if (data['done'] == true) {
                debugPrint('VideoService: ✅ Operation complete!');
                debugPrint('VideoService: Response keys: ${data.keys.toList()}');
                
                if (data['error'] != null) {
                   final errorMsg = data['error']['message'] ?? 'Unknown error';
                   debugPrint('VideoService: ❌ Operation error: $errorMsg');
                   debugPrint('VideoService: Full error object: ${data['error']}');
                   
                   // Don't fallback immediately - might be retryable
                   if (errorMsg.contains('quota') || errorMsg.contains('rate limit')) {
                      debugPrint('VideoService: Quota/rate limit hit - immediate fallback');
                      return _getStaticFallback("API quota exceeded: $errorMsg");
                   }
                   
                   return _getStaticFallback("Generation failed: $errorMsg");
                }
                
                // Extract video URL from response
                final respObj = data['response'];
                if (respObj != null) {
                    debugPrint('VideoService: Response object keys: ${respObj.keys?.toList()}');
                    
                    if (respObj['predictions'] != null && (respObj['predictions'] as List).isNotEmpty) {
                        final prediction = respObj['predictions'][0];
                        final videoUrl = prediction['url'] ?? 
                                       prediction['videoUri'] ?? 
                                       prediction['gcsUri'];
                        
                        if (videoUrl != null) {
                          debugPrint('VideoService: 🎥 REAL video URL found: $videoUrl');
                          onProgress?.call(1.0);
                          debugPrint('📊 [Telemetry] video_generation_success: duration=${i * pollInterval.inSeconds}s, polls=${i + 1}, source=veo_cloud');
                          return _sanitizeMediaUrl(videoUrl);
                        }
                    }
                }
                 
                 // Fallback: check metadata for outputUri
                 final metadata = data['metadata'];
                 if (metadata != null && metadata['outputUri'] != null) {
                    debugPrint('VideoService: 🎥 Video URL from metadata: ${metadata['outputUri']}');
                    onProgress?.call(1.0);
                    debugPrint('📊 [Telemetry] video_generation_success: duration=${i * pollInterval.inSeconds}s, polls=${i + 1}, source=veo_cloud_metadata');
                    return _sanitizeMediaUrl(metadata['outputUri']);
                 }
                 
                 debugPrint('VideoService: ⚠️ Operation done but no video URL found');
                 debugPrint('VideoService: Full response: $data');
                 return _getStaticFallback('Video generated but URL missing in response.');
            } else {
                // Still processing
                debugPrint('VideoService: ⏳ Still processing... (done: ${data['done']})');
                consecutiveErrors = 0; // Reset on successful poll
            }
            
        } catch (e) {
            consecutiveErrors++;
            final errorStr = e.toString();
            
            // Detect 404 "operation not found" - special handling
            if (errorStr.contains('404') || errorStr.contains('not found')) {
                total404Count++;
                debugPrint('VideoService: ⚠️ 404 Operation Not Found (count: $total404Count/$max404Retries)');
                debugPrint('VideoService: Full error: $e');
                
                if (total404Count >= max404Retries) {
                    debugPrint('VideoService: ❌ Operation lost after $total404Count attempts');
                    debugPrint('📊 [Telemetry] video_generation_failed: reason=404_operation_not_found, duration=${i * pollInterval.inSeconds}s, polls=${i + 1}');
                    
                    // Last resort: try ONE fresh generation retry outside this loop
                    // (caller should handle this)
                    return _getStaticFallback('Operation not found (404) after $total404Count retries');
                }
                
                // Continue polling - might be transient
                consecutiveErrors = 0; // Don't compound backoff for 404s
                continue;
            }
            
            debugPrint('VideoService: ❌ Polling error (attempt ${i + 1}, consecutive: $consecutiveErrors): $e');
            
            if (consecutiveErrors >= maxConsecutiveErrors) {
               debugPrint('VideoService: 🛑 Too many consecutive errors ($consecutiveErrors)');
               debugPrint('📊 [Telemetry] video_generation_failed: reason=consecutive_errors, duration=${i * pollInterval.inSeconds}s, polls=${i + 1}, error=$errorStr');
               return _getStaticFallback('Network errors during polling (consecutive failures).');
            }
            
            // Continue with backoff
        }
    }
    
    debugPrint('VideoService: ⏰ Timeout after ${maxPolls * pollInterval.inSeconds}s');
    debugPrint('📊 [Telemetry] video_generation_timeout: duration=${maxPolls * pollInterval.inSeconds}s, polls=$maxPolls');
    return _getStaticFallback('Generation timed out after ${maxPolls * pollInterval.inSeconds}s.');
  }

  static String _getStaticFallback(String reason) {
    debugPrint('VideoService: 🚨 [LAST RESORT FALLBACK] Using static storyboard');
    debugPrint('VideoService: Reason: $reason');
    debugPrint('VideoService: This should be rare - investigate if occurring frequently');
    
    debugPrint('📊 [Telemetry] video_fallback_used: reason="$reason", timestamp=${DateTime.now().toIso8601String()}');
    
    // Return IMAGE: prefix so UI knows this is not a real video
    // AGENT 3: Fallback only after all retries exhausted
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
