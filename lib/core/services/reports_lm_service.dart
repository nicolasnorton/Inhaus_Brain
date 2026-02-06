import '../../features/reports/models/report_model.dart';
import '../services/edge_ai_service.dart';
import '../tokens/llm_provider.dart';
import '../../features/knowledge/providers/knowledge_provider.dart';
import 'dart:convert';

class GenerationResult {
  final String content;
  final String? uri;
  final String? preview;

  GenerationResult({required this.content, this.uri, this.preview});
}

class ReportsLMService {
  
  // --- SYSTEM PROMPTS (Unified & Production Graded) ---

  static const String _audioRetrievalPrompt = "Identify the key themes, significant quotes, and a timeline of events from the provided sources. Prepare this data for a podcast producer.";
  
  static const String _audioOutlinerPrompt = "Based on these themes and quotes, build a discussion arc for a podcast. Structure: Intro -> Broad Overview -> Deep Dives into specific themes -> Implications -> Wrap-up. Ensure a logical progression for a 10-minute conversation.";

  static String _audioGeneratorPrompt(String topicFocus, String sources) => """
You are an expert podcast producer creating an engaging Audio Overview from uploaded sources only. Simulate two hosts: Host 1 (energetic, leads with questions/excitement) and Host 2 (insightful, builds with explanations/analogies). Use informal, conversational tone with contractions, colloquialisms ("you know," "I mean"), affirmations ("Exactly," "Right," "You've hit the nail on the head"), and rhetorical questions.

Strict rules:
- Ground everything in the sources provided; no external knowledge or invention.
- Structure: 
  1. Intro: "Hey everyone, welcome to our deep dive on ${topicFocus.isNotEmpty ? topicFocus : 'the main theme'}."
  2. Broad overview of key ideas.
  3. Introduce sources naturally.
  4. Back-and-forth discussion: Short punches alternating with longer explanations.
  5. Use analogies, break down complex ideas.
  6. Implications and open questions.
  7. Wrap-up: "As we wrap things up..." + final takeaway question + "Stay curious!" + sign-off.
- Length: Aim for 8-12 minutes spoken (~1500-2500 words).
- Output format: Markdown script with [Host 1]: and [Host 2]: labels.

Sources: $sources
""";

  static const String _videoOutlinerPrompt = "Outline 10-15 slides based on sources: Title -> Key concepts -> Evidence -> Implications -> Summary. Provide titles and core message for each.";

  static String _videoGeneratorPrompt(String sources) => """
You are a video producer creating a narrated slideshow Video Overview grounded only in sources.

Steps:
1. Outline 10-15 slides: Title -> Key concepts -> Evidence -> Implications -> Summary.
2. For each slide: Title, bullet points (minimal text), visual description (e.g., "Pull quote: '[exact quote]'", "Diagram: timeline from source X").
3. Write single-voice narration script synced to slides.

Rules:
- Visuals derived strictly from sources.
- Engaging, clear narration.

Output:
- JSON array of slides: [{"slide_number": 1, "title": "...", "bullets": [...], "visual_desc": "...", "narration": "..."}]
- Full narration script at end.

Sources: $sources
""";

  static String _mindMapPrompt(String sources) => """
You are an expert visualizer creating a Mind Map strictly from sources.

Steps:
1. Identify central theme.
2. Extract 4-7 main branches.
3. Add sub-branches and connections.

Rules:
- Concise labels.
- Balanced hierarchy.

Output JSON:
{
  "central_node": "Main Theme",
  "branches": [
    {"name": "Branch 1", "color": "blue", "subnodes": [...], "connections": [{"to": "Branch 2", "label": "influences"}]}
  ]
}

Sources: $sources
""";

  static String _reportPrompt(String topicFocus, String sources) => """
You are an expert analyst creating a professional Report from sources only.

Template:
- **Executive Summary**
- **Key Findings** (bulleted, cited)
- **Detailed Analysis** (themed sections)
- **Implications/Recommendations**
- **FAQ**
- **Tables** if data present

Rules:
- Formal tone.
- Inline citations [Source X].
- Objective.

Output: Markdown with headings.

Sources: $sources

${topicFocus.isNotEmpty ? "TOPIC FOCUS: $topicFocus" : ""}
""";

  static String _infographicPrompt(String sources) => """
You are a graphic designer creating an Infographic strictly derived from sources.

Steps:
1. Choose format (timeline, by-the-numbers, process flow, etc.).
2. Specify: Portrait orientation, minimal bold style, color palette, exact elements (hero stat, icons, charts, quotes).

Rules:
- Accurate data only.
- Clean, accessible design.

Output: Complete image generation prompt starting with "Create an infographic in minimal bold style..."

Sources: $sources
""";

  static String _slideDeckPrompt(String sources) => """
You are a presentation expert creating a Slide Deck from sources.

Steps:
1. Outline 10-15 slides: Title -> Agenda -> Content -> Summary.
2. Per slide: Title, minimal bullets, visual suggestions.

Rules:
- One idea per slide.
- Minimalist style.

Output: Markdown
### Slide X: Title
- Bullets
Visual: description

Sources: $sources
""";

  /// Generates a "Deep Dive" Audio Overview script and handle Audio Synthesis.
  static Future<GenerationResult> generateAudioOverview(Report report, dynamic ref, {bool isPreview = false, String topicFocus = ""}) async {
    final sources = _buildContextFromSources(report);
    
    if (isPreview) {
      final res = await EdgeAIService.generateText(
        _audioGeneratorPrompt(topicFocus, sources),
        modelConfig: AIModelConfig.gemma2n,
        ref: ref,
      );
      return GenerationResult(content: res.text);
    }

    // Agentic Workflow
    // 1. Retrieval
    final themes = await EdgeAIService.generateText("Retrieval Agent: $_audioRetrievalPrompt", memoryContext: sources, ref: ref);
    
    // 2. Outliner
    final outline = await EdgeAIService.generateText("Outliner Agent: $_audioOutlinerPrompt\n\nContext:\n${themes.text}", memoryContext: sources, ref: ref);
    
    // 3. Dialog Generator
    final scriptRes = await EdgeAIService.generateText(
      _audioGeneratorPrompt(topicFocus, sources) + "\n\nUse this outline:\n${outline.text}",
      modelConfig: AIModelConfig.geminiFlash,
      ref: ref,
    );

    // 4. Audio Synthesis (DeepMind Lyria)
    final audioUrl = await EdgeAIService.generateAudio(scriptRes.text);
    
    return GenerationResult(
      content: scriptRes.text,
      uri: audioUrl,
    );
  }

  /// Generates a Video Overview using Veo (Visuals) + Gemini (Script)
  static Future<GenerationResult> generateVideoOverview(Report report, dynamic ref, {bool isPreview = false}) async {
    final sources = _buildContextFromSources(report);
    
    if (isPreview) {
      final res = await EdgeAIService.generateText(
        _videoGeneratorPrompt(sources),
        modelConfig: AIModelConfig.gemma2n,
        ref: ref,
      );
      return GenerationResult(content: res.text);
    }

    // Agentic Workflow
    // 1. Retrieval + Outliner
    final outline = await EdgeAIService.generateText("Outliner: $_videoOutlinerPrompt", memoryContext: sources, ref: ref);
    
    // 2. Content Generator + Visualizer
    final contentRes = await EdgeAIService.generateText(
      _videoGeneratorPrompt(sources) + "\n\nFollow this outline:\n${outline.text}",
      modelConfig: AIModelConfig.geminiFlash,
      ref: ref,
    );

    // 3. Video Render (Veo)
    final videoUrl = await EdgeAIService.generateVideo(
       "Video overview for: ${report.title}. Summary: ${contentRes.text.length > 500 ? contentRes.text.substring(0, 500) : contentRes.text}",
       isFinal: true,
       ref: ref
    );
    
    return GenerationResult(
      content: contentRes.text,
      uri: videoUrl
    );
  }

  /// Generates a Mind Map structure (JSON)
  static Future<GenerationResult> generateMindMap(Report report, dynamic ref, {bool isPreview = false}) async {
    final sources = _buildContextFromSources(report);
    
    final prompt = _mindMapPrompt(sources);

    final result = await EdgeAIService.generateText(
      prompt, 
      modelConfig: isPreview ? AIModelConfig.gemma2n : AIModelConfig.geminiFlash,
      ref: ref
    );

    final json = _extractCodeBlock(result.text, 'json');
    return GenerationResult(content: json);
  }

  /// Generates a professional Report (Markdown)
  static Future<GenerationResult> generateReport(Report report, dynamic ref, {bool isPreview = false, String topicFocus = ""}) async {
    final sources = _buildContextFromSources(report);
    
    if (isPreview) {
      final res = await EdgeAIService.generateText(
        _reportPrompt(topicFocus, sources),
        modelConfig: AIModelConfig.gemma2n,
        ref: ref,
      );
      return GenerationResult(content: res.text);
    }

    // Retrieval -> Outliner -> Writer -> Refiner
    final retrieval = await EdgeAIService.generateText("Retrieval: Extract core metrics and quotes.", memoryContext: sources, ref: ref);
    final outline = await EdgeAIService.generateText("Outliner: Create a professional report structure based on: ${retrieval.text}", memoryContext: sources, ref: ref);
    
    final reportRes = await EdgeAIService.generateText(
      _reportPrompt(topicFocus, sources) + "\n\nUse this structure: ${outline.text}",
      modelConfig: AIModelConfig.geminiFlash,
      ref: ref,
    );
    
    return GenerationResult(content: reportRes.text);
  }

  /// Generates a Slide Deck Outline
  static Future<GenerationResult> generateSlideDeck(Report report, dynamic ref, {bool isPreview = false}) async {
    final sources = _buildContextFromSources(report);
    
    final result = await EdgeAIService.generateText(
       _slideDeckPrompt(sources), 
       modelConfig: isPreview ? AIModelConfig.gemma2n : AIModelConfig.geminiFlash,
       ref: ref
    );
    return GenerationResult(content: result.text);
  }

  /// Generates an Infographic Concept (Prompt for Imagen) + Image Generation
  static Future<GenerationResult> generateInfographic(Report report, dynamic ref, {bool isPreview = false}) async {
    final sources = _buildContextFromSources(report);
    
    final result = await EdgeAIService.generateText(
       _infographicPrompt(sources), 
       modelConfig: isPreview ? AIModelConfig.gemma2n : AIModelConfig.geminiFlash,
       ref: ref
    );

    if (isPreview) {
      return GenerationResult(content: result.text);
    }

    // Generate Final Image (Imagen 3)
    final imageUrl = await EdgeAIService.generateImage(result.text, ref: ref);

    return GenerationResult(
      content: result.text,
      uri: imageUrl
    );
  }

  static Stream<String> chatWithReport(Report report, String query, dynamic ref) async* {
     String context = _buildContextFromSources(report);
     
     // INTEGRATION: If report has a linked Knowledge Base, perform RAG
     if (report.datasetId != null && ref != null) {
        try {
           final api = ref.read(knowledgeApiServiceProvider);
           final searchResults = await api.retrieveChunks(
              datasetId: report.datasetId!,
              query: query,
              retrievalModel: {'search_mode': 'semantic'}
           );
           
           final results = searchResults['results'] as List?;
           if (results != null && results.isNotEmpty) {
              final ragContext = results.map((c) => c['content']).join('\n\n');
              context = "--- RELEVANT SEARCH RESULTS ---\n$ragContext\n\n--- FALLBACK CONTEXT ---\n$context";
           }
        } catch (e) {
           print("ReportsLM: RAG Retrieval failed: $e");
        }
     }
     
     final stream = EdgeAIService.generateTextStream(
       query,
       config: AIModelConfig.geminiFlash,
       memoryContext: context,
       ref: ref
     );

     await for (final result in stream) {
        yield result.text;
     }
  }

  static String _buildContextFromSources(Report report) {
    final buffer = StringBuffer();
    buffer.writeln("REPORT CONTEXT: ${report.title}");
    for (var source in report.sources) {
      buffer.writeln("\n--- SOURCE: ${source.name} (${source.type.name}) ---");
      if (source.content != null) {
        buffer.writeln(source.content!.length > 15000 
            ? source.content!.substring(0, 15000) + "...[TRUNCATED]" 
            : source.content);
      } else {
        buffer.writeln("[No text content available]");
      }
    }
    return buffer.toString();
  }

  static String _extractCodeBlock(String text, String lang) {
    if (!text.contains('```')) return text.trim();
    
    final pattern = RegExp('```$lang?\\s*([\\s\\S]*?)\\s*```');
    final match = pattern.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }
    return text.trim();
  }
}

