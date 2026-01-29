import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_proxy_service.dart';
import '../tokens/llm_provider.dart';

/// Service dedicated to Video Generation using Veo models via Secure Proxy.
/// Implements cost-aware routing (Preview vs Final) and cultural safety checks.
class VideoGenerationService {
  static const String _previewModel = 'veo-3.0-fast-generate-preview';
  // Assuming 'veo-3.1-generate' is the model ID for the high quality version.
  // If not available, we can fallback or use the standard veo-3.0-generate.
  static const String _finalModel = 'veo-3.0-generate'; // Using 3.0 standard as safe high-quality, can update to 3.1 if confirmed

  static const int _defaultPreviewDuration = 5; // seconds
  static const int _defaultFinalDuration = 10; // seconds

  /// Generates a video preview (Fast/Cheap model).
  /// Always use this for initial requests.
  static Future<String> generatePreview(
    String prompt, {
    bool useCulturalSafety = true,
    bool includeSubtitles = false,
    Function(double)? onProgress,
  }) async {
    String effectivePrompt = useCulturalSafety ? _appendCulturalSafety(prompt) : prompt;
    if (includeSubtitles) {
      effectivePrompt += " Include bilingual subtitles: English and Spanish (LatAm).";
    }
    
    return _generateVideoInternal(
      prompt: effectivePrompt,
      modelId: _previewModel,
      isPreview: true,
      onProgress: onProgress,
    );
  }

  /// Generates the final high-quality video (Flagship model).
  /// REQUIRED: User confirmation must be obtained before calling this.
  /// Throws [UserConfirmationMissingException] if not invoked correctly (this is more of a logical check for the caller).
  static Future<String> generateFinal(
    String prompt, {
    bool confirmedByUser = false,
    bool useCulturalSafety = true,
    bool includeSubtitles = false,
    Function(double)? onProgress,
  }) async {
    if (!confirmedByUser) {
      throw Exception('VideoGenerationService: User confirmation required for final render.');
    }

    String effectivePrompt = useCulturalSafety ? _appendCulturalSafety(prompt) : prompt;
    if (includeSubtitles) {
      effectivePrompt += " Include bilingual subtitles: English and Spanish (LatAm).";
    }

    return _generateVideoInternal(
      prompt: effectivePrompt,
      modelId: _finalModel,
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
    // WEB PROXY PATH (Recommended for all environments)
    if (kIsWeb) {
      debugPrint('VideoService: Requesting $modelId via Secure Proxy (Preview: $isPreview)...');
      onProgress?.call(0.1);
      try {
        final proxyResponse = await AIProxyService.generateContent(
          prompt: prompt,
          config: AIModelConfig(
            provider: AIProvider.vertex, 
            modelId: modelId,
            temperature: 0.5, 
            maxTokens: 100, 
          ),
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

    // FALLBACK/MOCK (Only for non-web environments during development)
    debugPrint('VideoService: Non-Web environment. Returning development mock.');
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      onProgress?.call(i / 10.0);
    }
    return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  }

  static Future<String> _pollProxyVeoOperation(String operationName, {Function(double)? onProgress}) async {
    for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 5));
        onProgress?.call(0.1 + (i / 60.0) * 0.8);
        
        try {
            final data = await AIProxyService.pollOperation(operationName);
            if (data['done'] == true) {
                if (data['error'] != null) throw Exception('Video Generation Failed: ${data['error']}');
                
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
                 throw Exception('Video operation finished but no video URL found.');
            }
        } catch (e) {
            debugPrint('VideoService: Polling error/retry: $e');
            if (i > 50) rethrow; 
        }
    }
     throw Exception('Video generation timed out.');
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
