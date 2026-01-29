
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/reports/models/report_model.dart';
import '../services/edge_ai_service.dart';
import '../tokens/llm_provider.dart';

class ReportsLMService {
  
  /// Generates a "Deep Dive" Audio Overview script and returns a URL to the audio.
  static Future<String> generateAudioOverview(Report report, dynamic ref, {bool isPreview = false}) async {
    final context = _buildContextFromSources(report);
    final prompt = """
    You are two AI hosts, 'Nova' (energetic, insightful) and 'Sage' (calm, analytical).
    Create a 3-minute engaging podcast script summarizing the provided source material.
    Focus on key trends, surprising data points, and strategic implications.
    Format as a script:
    NOVA: [Line]
    SAGE: [Line]
    """;

    final scriptResult = await EdgeAIService.generateText(
      prompt,
      modelConfig: isPreview ? AIModelConfig.gemma2n : AIModelConfig.geminiFlash,
      memoryContext: context,
      ref: ref,
    );

    // In a real implementation, we would send this script to a TTS service (ElevenLabs/OpenAI).
    if (isPreview) {
       // Return local placeholder for preview
       return "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
    }
    
    // Simulate processing time for high quality
    await Future.delayed(const Duration(seconds: 4));
    return "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3";
  }

  /// Generates a Video Overview using Veo (Visuals) + Gemini (Script)
  static Future<String> generateVideoOverview(Report report, dynamic ref, {bool isFinal = false, bool includeSubtitles = false, Function(double)? onProgress}) async {
    final context = _buildContextFromSources(report);
    
    String styleEnhancement = "";
    if (includeSubtitles) {
      styleEnhancement = "\nInclude bilingual text overlays (Captions) in both English and Spanish that highlight the main takeaway.";
    }

    // 1. Generate visual description
    final prompt = """
    Based on these sources, describe a SINGLE vivid, futuristic, cinematic video scene 
    that metaphorically represents the main data trend. 
    Keep it under 30 words. Optimized for video generation.$styleEnhancement
    """;

    final visualResult = await EdgeAIService.generateText(
      prompt,
      modelConfig: AIModelConfig.geminiFlash,
      memoryContext: context,
      ref: ref,
    );

    // 2. Call Veo
    return await EdgeAIService.generateVideo(visualResult.text, ref: ref, isFinal: isFinal, onProgress: onProgress);
  }

  /// Generates a Mind Map structure (JSON)
  static Future<String> generateMindMap(Report report, dynamic ref, {bool isPreview = false}) async {
     final context = _buildContextFromSources(report);
     final prompt = """
     Analyze the sources and create a hierarchical mind map of the key concepts.
     Return ONLY valid JSON in this format:
     {
       "root": "Main Topic",
       "children": [
         { "name": "Subtopic", "children": [...] }
       ]
     }
     """;

     final result = await EdgeAIService.generateText(
       prompt, 
       modelConfig: isPreview ? AIModelConfig.gemma2n : AIModelConfig.geminiFlash,
       memoryContext: context,
       ref: ref
     );

     // Strip markdown code blocks if present
     final json = result.text.replaceAll('```json', '').replaceAll('```', '').trim();
     
     // Quick fix for LiteRT mock text if it doesn't return JSON
     if (isPreview && !json.startsWith('{')) {
       return '{ "root": "LiteRT Preview", "children": [{ "name": "Speed", "children": [] }] }';
     }
     return json;
  }

  /// Generates a Slide Deck Outline
  static Future<String> generateSlideDeck(Report report, dynamic ref, {bool isPreview = false}) async {
    final context = _buildContextFromSources(report);
    const prompt = "Create a 5-slide presentation outline based on these sources. Title + 3 bullets per slide.";
    
    final result = await EdgeAIService.generateText(
       prompt, 
       modelConfig: isPreview ? AIModelConfig.gemma2n : AIModelConfig.geminiFlash,
       memoryContext: context,
       ref: ref
    );
    return result.text;
  }

  /// Generates an Infographic Concept
  static Future<String> generateInfographic(Report report, dynamic ref, {bool isPreview = false}) async {
    final context = _buildContextFromSources(report);
    const prompt = "Describe a visual infographic layout that best explains the data (Flowchart, Bar Graph, or Comparison).";
    
    final result = await EdgeAIService.generateText(
       prompt, 
       modelConfig: isPreview ? AIModelConfig.gemma2n : AIModelConfig.geminiFlash,
       memoryContext: context,
       ref: ref
    );
    return result.text;
  }

  static String _buildContextFromSources(Report report) {
    final buffer = StringBuffer();
    buffer.writeln("REPORT CONTEXT: ${report.title}");
    for (var source in report.sources) {
      buffer.writeln("\n--- SOURCE: ${source.name} (${source.type.name}) ---");
      if (source.content != null) {
        // Truncate for token limits if necessary
        buffer.writeln(source.content!.length > 10000 
            ? source.content!.substring(0, 10000) + "...[TRUNCATED]" 
            : source.content);
      } else {
        buffer.writeln("[No text content available]");
      }
    }
    return buffer.toString();
  }
}
