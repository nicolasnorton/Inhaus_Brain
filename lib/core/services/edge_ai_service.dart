import 'dart:js_interop';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/knowledge/models/knowledge_source.dart';

@JS('getAISystemStatus')
external JSPromise getAISystemStatus();

@JS('promptBuiltInAI')
external JSPromise promptBuiltInAI(String query);

enum AIProximity {
  local,     // Chrome Prompt API or Gemini Nano
  cloud,     // Vertex AI Fallback
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
  EdgeAIResult(this.text, this.proximity);
}

class EdgeAIService {
  static Future<EdgeAIResult> generateText(String prompt, {List<KnowledgeSource> context = const [], String? apiKey, String? gemmaKey}) async {
    final effectivePrompt = _buildPromptWithContext(prompt, context);
    debugPrint('EdgeAI: Generating text. Context items: ${context.length}, API Key provided: ${apiKey != null}, Gemma Key: ${gemmaKey != null}');
    
    // 1. BYO-Key Cloud Execution
    if (gemmaKey != null && gemmaKey.isNotEmpty) {
       // Gemma Model (Google Cloud Vertex / Local Server)
       await Future.delayed(const Duration(seconds: 1));
       return EdgeAIResult(
         "Gemma (7B/2B): Analyzed logic via custom model key.\n\n$effectivePrompt", 
         AIProximity.cloud
       );
    }

    if (apiKey != null && apiKey.isNotEmpty) {
       try {
         // Try gemini-1.5-flash (standard stable string)
         final model = GenerativeModel(
           model: 'gemini-1.5-flash', 
           apiKey: apiKey,
         );
         
         final content = [Content.text(effectivePrompt)];
         final response = await model.generateContent(content);
         
         if (response.text != null) {
           return EdgeAIResult(response.text!, AIProximity.cloud);
         }
       } catch (e) {
         debugPrint('EdgeAI: Gemini-1.5-Flash Error: $e. Trying Gemini-1.5-Pro fallback...');
         try {
           final model = GenerativeModel(
             model: 'gemini-1.5-pro', 
             apiKey: apiKey,
           );
           final response = await model.generateContent([Content.text(effectivePrompt)]);
           if (response.text != null) {
             return EdgeAIResult(response.text!, AIProximity.cloud);
           }
         } catch (e2) {
           debugPrint('EdgeAI: Gemini-Pro Error: $e2. Falling back to Edge.');
         }
       }
    }

    // 2. Chrome Built-in AI (Local)
    if (kIsWeb) {
      try {
        final statusPromise = getAISystemStatus();
        final status = (await statusPromise.toDart as JSString).toDart;
        
        if (status == 'readily') {
          debugPrint('EdgeAI: Attempting Chrome Built-in AI...');
          final JSPromise promise = promptBuiltInAI(effectivePrompt);
          final JSString? response = (await promise.toDart as JSString?);
          if (response != null) {
            return EdgeAIResult(response.toDart, AIProximity.local);
          }
        }
      } catch (e) {
        debugPrint('EdgeAI: JS Interop Error: $e');
      }
    }

    // 3. Local Mock (Fallback)
    debugPrint('EdgeAI: Using Local Reasoning Mock...');
    final mockResult = await _generateLocalMock(effectivePrompt);
    debugPrint('EdgeAI: Local Mock Success.');
    return EdgeAIResult(mockResult, AIProximity.simulated);
  }

  static Future<String> generateImage(String prompt, {String? imagenKey, String? bananaKey}) async {
    if (imagenKey != null && imagenKey.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      return "https://via.placeholder.com/1024x1024.png?text=Imagen+3+Generated+Art"; // Simulated Cloud URL
    }
    if (bananaKey != null && bananaKey.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      return "https://via.placeholder.com/1024x1024.png?text=Nano+Banana+Edit"; // Simulated Edit
    }
    // Local Mock
    return "assets/images/mock_concept.png"; 
  }

  static Future<String> generateVideo(String prompt, {String? veoKey}) async {
    if (veoKey != null && veoKey.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 3));
      return "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4"; // Simulated Cloud URL
    }
    // Local Mock
    return "assets/videos/mock_render.mp4";
  }

  static Future<String> generateAudio(String prompt, {String? lyriaKey}) async {
    if (lyriaKey != null && lyriaKey.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 3));
      return "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"; // Simulated Cloud URL
    }
    // Local Mock
    return "assets/audio/mock_soundtrack.mp3"; 
  }



  static Future<String> _generateLocalMock(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulating local inference time
    
    final lowerPrompt = prompt.toLowerCase();
    
    // Agentic Local Reasoning
    if (lowerPrompt.contains('target audience')) {
      final topic = _extractTopic(lowerPrompt);
      return "Local Edge Analysis: For $topic, we've identified a 'Values-Driven' segment. (Processed locally)";
    }
    
    if (lowerPrompt.contains('competitor')) {
      final topic = _extractTopic(lowerPrompt);
      return "In-Browser Research: $topic competitors are currently over-indexing on high-contrast visuals. (Calculated on-device)";
    }

    if (lowerPrompt.contains('strategy')) {
      final topic = _extractTopic(lowerPrompt);
      return "On-Device Simulation: $topic distribution should prioritize high-retention vertical video. (Edge Optimized)";
    }

    return "Edge AI: Processing complete for '$prompt'.";
  }

  static String _extractTopic(String prompt) {
    if (prompt.contains('campaign:')) return prompt.split('campaign:').last.split('.').first.trim();
    if (prompt.contains('titled')) return prompt.split('titled').last.split('.').first.trim();
    return "this campaign";
  }

  static String _buildPromptWithContext(String prompt, List<KnowledgeSource> context) {
    if (context.isEmpty) return prompt;

    final contextBuffer = StringBuffer();
    contextBuffer.writeln('CONTEXT FROM KNOWLEDGE BASE:');
    for (final source in context) {
      contextBuffer.writeln('--- Source: ${source.title} (${source.type.name}) ---');
      // Truncate content for simulation/size limits
      final safeContent = source.content.length > 500 ? '${source.content.substring(0, 500)}...' : source.content;
      contextBuffer.writeln(safeContent);
      contextBuffer.writeln('--- End Source ---');
    }
    contextBuffer.writeln('\nUSER PROMPT:');
    contextBuffer.writeln(prompt);

    return contextBuffer.toString();
  }
}

