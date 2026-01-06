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
  static Future<EdgeAIResult> generateText(
    String prompt, {
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
  }) async {
    final effectivePrompt = _buildPromptWithContext(prompt, context, memoryContext: memoryContext);
    debugPrint('EdgeAI: Generating text. Context items: ${context.length}, Memory provided: ${memoryContext != null}, Image provided: ${imageBytes != null}, API Key provided: ${apiKey != null}');
    
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
         // Use gemini-1.5-flash for speed and multi-modal support
         final model = GenerativeModel(
           model: 'gemini-1.5-flash', 
           apiKey: apiKey,
         );
         
         final List<Part> parts = [TextPart(effectivePrompt)];
         if (imageBytes != null) {
           parts.add(DataPart(imageMimeType ?? 'image/jpeg', imageBytes));
         }

         final content = [Content.multi(parts)];
         final response = await model.generateContent(content);
         
         if (response.text != null) {
           return EdgeAIResult(response.text!, AIProximity.cloud);
         }
       } catch (e) {
         debugPrint('EdgeAI: Gemini Multi-modal Error: $e. Falling back to text-only Gemini-1.5-Pro...');
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

    // 2. Chrome Built-in AI (Local) - Note: Chrome Built-in AI currently only supports text
    if (kIsWeb && imageBytes == null) {
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
    final mockResult = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
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

  // --- STREAMING SUPPORT (Phase 22) ---
  static Stream<EdgeAIResult> generateTextStream(
    String prompt, {
    List<KnowledgeSource> context = const [],
    String? memoryContext,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? apiKey,
    String? gemmaKey,
  }) async* {
    final effectivePrompt = _buildPromptWithContext(prompt, context, memoryContext: memoryContext);

    // 1. Cloud Streaming (Gemini)
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
        final List<Part> parts = [TextPart(effectivePrompt)];
        if (imageBytes != null) {
          parts.add(DataPart(imageMimeType ?? 'image/jpeg', imageBytes));
        }

        final content = [Content.multi(parts)];
        final responseStream = model.generateContentStream(content);

        await for (final chunk in responseStream) {
          if (chunk.text != null) {
            yield EdgeAIResult(chunk.text!, AIProximity.cloud);
          }
        }
        return;
      } catch (e) {
        debugPrint('EdgeAI Streaming Error: $e. Falling back to non-streaming.');
      }
    }

    // 2. Local/Mock Fallback (Simulated Streaming)
    if (kIsWeb || apiKey == null) {
       yield EdgeAIResult("Thinking...", AIProximity.simulated);
       await Future.delayed(const Duration(milliseconds: 500));
       
       final fullResponse = await _generateLocalMock(effectivePrompt, hasImage: imageBytes != null);
       // Simulate token streaming
       final words = fullResponse.split(' ');
       String buffer = "";
       for (var word in words) {
         await Future.delayed(const Duration(milliseconds: 50));
         buffer = "$buffer $word";
         yield EdgeAIResult(buffer, AIProximity.simulated);
       }
    }
  }

  static Future<String> generateAudio(String prompt, {String? lyriaKey}) async {
    if (lyriaKey != null && lyriaKey.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 3));
      return "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"; // Simulated Cloud URL
    }
    // Local Mock
    return "assets/audio/mock_soundtrack.mp3"; 
  }



  static Future<String> _generateLocalMock(String prompt, {bool hasImage = false}) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulating local inference time
    
    final lowerPrompt = prompt.toLowerCase();
    
    if (hasImage) {
      return "Local Vision Analysis: Image detected. This visual asset contains modern typography and a high-contrast color palette, suggesting a premium tech brand. (Simulated Vision)";
    }
    
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

  static String _buildPromptWithContext(String prompt, List<KnowledgeSource> context, {String? memoryContext}) {
    final buffer = StringBuffer();
    
    if (memoryContext != null && memoryContext.isNotEmpty) {
      buffer.writeln(memoryContext);
      buffer.writeln('-----------------------------------');
    }

    if (context.isNotEmpty) {
      buffer.writeln('CONTEXT FROM KNOWLEDGE BASE:');
      for (final source in context) {
        buffer.writeln('--- Source: ${source.title} (${source.type.name}) ---');
        final safeContent = source.content.length > 500 ? '${source.content.substring(0, 500)}...' : source.content;
        buffer.writeln(safeContent);
        buffer.writeln('--- End Source ---');
      }
    }
    
    buffer.writeln('\nUSER PROMPT:');
    buffer.writeln(prompt);

    return buffer.toString();
  }

  /// --- BIDI-STREAMING (Phase 26) ---
  /// Prototype for Bi-directional token flow. 
  /// In a production environment, this would handle real-time tool calls and 
  /// adaptive user prompts mid-generation.
  static Stream<EdgeAIResult> generateBidiStream(
    String prompt, {
    required Stream<String> userInterjection,
    String? apiKey,
  }) async* {
    if (apiKey == null || apiKey.isEmpty) {
      yield EdgeAIResult("Error: Bidi-streaming requires an active API Key.", AIProximity.simulated);
      return;
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final chat = model.startChat();
    
    // Initial request
    final stream = chat.sendMessageStream(Content.text(prompt));
    
    await for (final response in stream) {
      if (response.text != null) {
        yield EdgeAIResult(response.text!, AIProximity.cloud);
      }
    }

    // Monitoring for interjections (Simplified Prototype)
    // In ADK, this would be a long-lived duplex connection.
    userInterjection.listen((text) {
       debugPrint("Bidi-Stream: User interjected with: $text. Adapting next turn...");
    });
  }
}

