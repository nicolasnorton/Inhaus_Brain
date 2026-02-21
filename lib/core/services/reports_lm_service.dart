import '../../features/reports/models/report_model.dart';
import '../../features/reports/models/source_model.dart';
import '../services/edge_ai_service.dart';
import '../services/ai_proxy_service.dart';
import '../tokens/llm_provider.dart';
import '../../features/knowledge/providers/knowledge_provider.dart';
import 'dart:convert';

class GenerationResult {
  final String content;
  final String? uri;
  final String? preview;
  final List<Citation> citations;

  GenerationResult({required this.content, this.uri, this.preview, this.citations = const []});
}

class ReportsLMService {
  
  // --- SYSTEM PROMPTS (Unified & Production Graded) ---

  static const String _citationInstruction = """
When referencing information from sources, include inline citations in the format [Source: filename, page x].
Every factual claim MUST have a citation. If you cannot cite a source, do not include the claim.
""";

  static const String _audioRetrievalPrompt = "Identify the key themes, significant quotes, and a timeline of events from the provided sources. Prepare this data for a podcast producer. Include source attributions.";
  
  static const String _audioOutlinerPrompt = "Based on these themes and quotes, build a discussion arc for a podcast. Structure: Intro -> Broad Overview -> Deep Dives into specific themes -> Implications -> Wrap-up. Ensure a logical progression for a 10-minute conversation.";

  static String _audioGeneratorPrompt(String topicFocus, String sources) => """
You are an expert podcast producer creating an engaging Audio Overview from uploaded sources only. Simulate two hosts: Host 1 (energetic, leads with questions/excitement) and Host 2 (insightful, builds with explanations/analogies). Use informal, conversational tone with contractions, colloquialisms ("you know," "I mean"), affirmations ("Exactly," "Right," "You've hit the nail on the head"), and rhetorical questions.

Strict rules:
- Ground everything in the sources provided; no external knowledge or invention.
- $_citationInstruction
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
- $_citationInstruction

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
- $_citationInstruction

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
- $_citationInstruction

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
- $_citationInstruction

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
- $_citationInstruction

Output: Markdown
### Slide X: Title
- Bullets
Visual: description

Sources: $sources
""";

  /// Generates a "Deep Dive" Audio Overview script and handle Audio Synthesis.
  static Future<GenerationResult> generateAudioOverview(Report report, dynamic ref, {bool isPreview = false, String topicFocus = ""}) async {
    final sources = await _retrieveRelevantContext(report, ref, query: topicFocus.isNotEmpty ? topicFocus : _audioRetrievalPrompt);
    
    if (isPreview) {
      final res = await EdgeAIService.generateText(
        _audioGeneratorPrompt(topicFocus, sources),
        modelConfig: AIModelConfig.geminiFlash,
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
      citations: _parseCitations(scriptRes.text, report),
    );
  }

  /// Generates a Video Overview using Veo (Visuals) + Gemini (Script)
  static Future<GenerationResult> generateVideoOverview(Report report, dynamic ref, {bool isPreview = false}) async {
    final sources = await _retrieveRelevantContext(report, ref, query: _videoOutlinerPrompt);
    
    // Agentic Workflow
    // 1. Retrieval + Outliner
    final outline = await EdgeAIService.generateText("Outliner: $_videoOutlinerPrompt", memoryContext: sources, ref: ref);
    
    // 2. Content Generator + Visualizer (JSON Enforced)
    final contentRes = await EdgeAIService.generateText(
      _videoGeneratorPrompt(sources) + "\n\nFollow this outline:\n${outline.text}",
      modelConfig: AIModelConfig.geminiFlash,
      ref: ref,
      outputMode: 'json', // STRICT JSON
    );

    // Parse JSON safely
    String visualContext = contentRes.text;
    try {
        // Just extract script for visual prompt generation context if needed
        // For video generation, we might need to parse the JSON to get visual descriptions per slide
        // But for now, we pass the whole JSON as context to visual prompt generator
    } catch (_) {}

    // 3. Visual Prompt Generator
    final visualPromptRes = await EdgeAIService.generateText(
      "Create a single, highly descriptive visual prompt (under 400 words) for a video generation model (Veo) that captures the essence of this content. Style: Cinematic, Professional, Documentary. Content: $visualContext",
      modelConfig: AIModelConfig.geminiFlash,
      ref: ref,
    );

    // 4. Video Render (Veo)
    final videoUrl = await EdgeAIService.generateVideo(
       visualPromptRes.text, 
       isFinal: true,
       ref: ref
    );
    
    return GenerationResult(
      content: contentRes.text, // Returns structured JSON
      uri: videoUrl
    );
  }

  /// Generates a Mind Map structure (JSON)
  static Future<GenerationResult> generateMindMap(Report report, dynamic ref, {bool isPreview = false}) async {
    final sources = await _retrieveRelevantContext(report, ref, query: "Identify the central theme and main branches for a mind map.");
    
    final prompt = _mindMapPrompt(sources);

    final result = await EdgeAIService.generateText(
      prompt, 
      modelConfig: isPreview ? AIModelConfig.geminiFlash : AIModelConfig.geminiPro, // Upgrade to Pro for Drafts
      ref: ref,
      outputMode: 'json', // STRICT JSON
    );

    final json = _extractCodeBlock(result.text, 'json');
    return GenerationResult(content: json);
  }

  /// Generates a professional Report (Markdown)
  static Future<GenerationResult> generateReport(Report report, dynamic ref, {bool isPreview = false, String topicFocus = ""}) async {
    final sources = await _retrieveRelevantContext(report, ref, query: topicFocus.isNotEmpty ? topicFocus : "Extract core metrics, quotes, and data points.");
    
    if (isPreview) {
      final res = await EdgeAIService.generateText(
        _reportPrompt(topicFocus, sources),
        modelConfig: AIModelConfig.geminiFlash,
        ref: ref,
      );
      return GenerationResult(content: res.text);
    }

    // Retrieval -> Outliner -> Writer -> Refiner
    final retrieval = await EdgeAIService.generateText("Retrieval: Extract core metrics and quotes.", memoryContext: sources, ref: ref);
    final outline = await EdgeAIService.generateText("Outliner: Create a professional report structure based on: ${retrieval.text}", memoryContext: sources, ref: ref);
    
    final draftRes = await EdgeAIService.generateText(
      _reportPrompt(topicFocus, sources) + "\n\nUse this structure: ${outline.text}",
      modelConfig: AIModelConfig.geminiPro, // Upgrade to Pro for better reasoning
      ref: ref,
    );

    // Review Pass (New Phase 3)
    final finalContent = await _reviewAndRefine(draftRes.text, _reportPrompt(topicFocus, sources), sources, ref);
    
    return GenerationResult(
      content: finalContent,
      citations: _parseCitations(finalContent, report), 
    );
  }

  // --- Helpers ---

  static Future<String> _reviewAndRefine(String currentDraft, String originalPrompt, String sources, dynamic ref) async {
      try {
        final critique = await EdgeAIService.generateText(
          "Review Agent: You are a strict editor. Review the following draft against sources. Identify hallucinations, missed citations, and flow issues. Return a list of specific improvements. If perfect, say 'NO CHANGES'.\n\nDraft:\n$currentDraft\n\nSources:\n$sources",
          modelConfig: AIModelConfig.geminiFlash, // Fast critique
          ref: ref
        );

        if (critique.text.contains("NO CHANGES")) return currentDraft;

        final refined = await EdgeAIService.generateText(
           "Writer: Refine this draft based on the following critique. Ensure strict adherence to sources and citations.\n\nCritique:\n${critique.text}\n\nOriginal Draft:\n$currentDraft",
           modelConfig: AIModelConfig.geminiPro, // Use Pro for final polish if available, else Flash
           ref: ref
        );

        return refined.text;
      } catch (e) {
          print("Review agent failed: $e");
          return currentDraft; // Fallback
      }
  }

  /// Generates a Slide Deck Outline
  static Future<GenerationResult> generateSlideDeck(Report report, dynamic ref, {bool isPreview = false}) async {
    final sources = await _retrieveRelevantContext(report, ref, query: _slideDeckPrompt(""));
    
    final result = await EdgeAIService.generateText(
       _slideDeckPrompt(sources), 
       modelConfig: isPreview ? AIModelConfig.geminiFlash : AIModelConfig.geminiFlash,
       ref: ref
    );
    return GenerationResult(content: result.text);
  }

  /// Generates an Infographic Concept (Prompt for Imagen) + Image Generation
  static Future<GenerationResult> generateInfographic(Report report, dynamic ref, {bool isPreview = false}) async {
    final sources = await _retrieveRelevantContext(report, ref, query: _infographicPrompt(""));
    
    final result = await EdgeAIService.generateText(
       _infographicPrompt(sources), 
       modelConfig: isPreview ? AIModelConfig.geminiFlash : AIModelConfig.geminiFlash,
       ref: ref
    );

    if (isPreview) {
      return GenerationResult(content: result.text);
    }

    // Generate Final Image (Imagen 3)
    final imageUrl = await EdgeAIService.generateImage(
       result.text, 
       ref: ref,
       generationParams: {'aspectRatio': '3:4', 'sampleCount': 1},
    );

    return GenerationResult(
      content: result.text,
      uri: imageUrl
    );
  }

  static Stream<String> chatWithReport(Report report, String query, dynamic ref) async* {
    // Phase 5.3: Enhanced Chat Pipeline
    // Step 1: Query Understanding — classify the query type
    String queryType = 'factual'; // default
    try {
      final classification = await EdgeAIService.generateText(
        "Classify this question into exactly one category: factual_lookup, comparison, synthesis, opinion, clarification. Answer with just the category.\n\nQuestion: $query",
        modelConfig: AIModelConfig.geminiFlash,
        ref: ref,
      );
      queryType = classification.text.trim().toLowerCase();
    } catch (_) {}

    // Step 2: Multi-query decomposition for complex questions
    List<String> subQueries = [query];
    if (queryType == 'comparison' || queryType == 'synthesis') {
      try {
        final decomposed = await EdgeAIService.generateText(
          "Break this complex question into 2-4 simpler sub-questions that can each be answered from a knowledge base. Return as a JSON array of strings.\n\nQuestion: $query",
          modelConfig: AIModelConfig.geminiFlash,
          outputMode: 'json',
          ref: ref,
        );
        final parsed = json.decode(decomposed.text);
        if (parsed is List) {
          subQueries = parsed.cast<String>();
        }
      } catch (_) {
        // Keep original query
      }
    }

    // Step 3: Multi-query retrieval
    final contextParts = <String>[];
    for (final sq in subQueries) {
      final ctx = await _retrieveRelevantContext(report, ref, query: sq);
      contextParts.add(ctx);
    }
    final combinedContext = contextParts.join('\n\n---\n\n');

    // Step 4: Stream response with citation-aware system instruction
    final systemPrompt = """You are a knowledgeable research assistant answering questions about a report.
Rules:
- Ground ALL answers in the provided context only.
- Include inline citations as [Source: filename, page X] for every factual claim.
- If the context doesn't contain enough information to answer, say so explicitly.
- Be concise but thorough.
- Query type: $queryType

Context:
$combinedContext""";

    final stream = EdgeAIService.generateTextStream(
      query,
      config: AIModelConfig.geminiFlash,
      memoryContext: systemPrompt,
      ref: ref,
    );

    await for (final result in stream) {
      yield result.text;
    }

    // Step 5: Follow-up suggestions
    try {
      final followUps = await EdgeAIService.generateText(
        "Based on this Q&A, suggest 2-3 follow-up questions the user might ask. Return as a JSON array of strings.\n\nQuestion: $query\nContext: ${combinedContext.substring(0, (combinedContext.length > 2000 ? 2000 : combinedContext.length))}",
        modelConfig: AIModelConfig.geminiFlash,
        outputMode: 'json',
        ref: ref,
      );
      yield "\n\n---\n**Suggested follow-ups:**\n${followUps.text}";
    } catch (_) {
      // Silently skip follow-ups if they fail
    }
  }

  // --- Phase 4: Verification ---

  /// Verifies generated output against sources and returns confidence score
  static Future<Map<String, dynamic>> verifyOutput(String output, Report report, dynamic ref) async {
    try {
      final sources = _buildContextFromSources(report);
      final api = ref.read(aiProxyServiceProvider);
      
      final response = await api.post('/verify_output', {
        'output': output,
        'sources': sources,
        'outputType': 'report',
      });
      
      return response;
    } catch (e) {
      print("ReportsLM: Verification failed: $e");
      return {
        'overall_score': -1,
        'error': e.toString(),
      };
    }
  }

  // --- Phase 5.2: Audio Synthesis ---

  /// Synthesizes multi-speaker audio from a podcast script via Cloud TTS
  static Future<GenerationResult> generateAudioWithTTS(Report report, dynamic ref, {String topicFocus = ""}) async {
    final sources = await _retrieveRelevantContext(report, ref, query: topicFocus.isNotEmpty ? topicFocus : _audioRetrievalPrompt);

    // 1. Generate Script (full pipeline)
    final themes = await EdgeAIService.generateText("Retrieval Agent: $_audioRetrievalPrompt", memoryContext: sources, ref: ref);
    final outline = await EdgeAIService.generateText("Outliner Agent: $_audioOutlinerPrompt\n\nContext:\n${themes.text}", memoryContext: sources, ref: ref);
    final scriptRes = await EdgeAIService.generateText(
      _audioGeneratorPrompt(topicFocus, sources) + "\n\nUse this outline:\n${outline.text}",
      modelConfig: AIModelConfig.geminiPro, // Pro for highest quality script
      ref: ref,
    );

    // 2. Review pass
    final finalScript = await _reviewAndRefine(scriptRes.text, _audioGeneratorPrompt(topicFocus, sources), sources, ref);

    // 3. Synthesize via Cloud TTS
    String? audioUrl;
    try {
      final api = ref.read(aiProxyServiceProvider);
      final ttsResponse = await api.post('/synthesize_audio', {
        'script': finalScript,
        'voiceConfig': {
          'host1': 'en-US-Journey-D',
          'host2': 'en-US-Journey-F',
        },
      });
      
      if (ttsResponse['synthesizer'] == 'cloud_tts') {
        // Store base64 audio segments — client will concatenate
        audioUrl = 'tts://multi-speaker'; // Placeholder; real impl stores to GCS
      }
    } catch (e) {
      print("ReportsLM: Cloud TTS failed: $e. Falling back to Edge audio.");
      audioUrl = await EdgeAIService.generateAudio(finalScript);
    }

    return GenerationResult(
      content: finalScript,
      uri: audioUrl,
      citations: _parseCitations(finalScript, report),
    );
  }

  // --- Knowledge Integration ---

  /// Indexes a new source into the Report's Knowledge Base
  static Future<void> indexSource(ReportSource source, String reportDatasetId, dynamic ref) async {
    final api = ref.read(knowledgeApiServiceProvider);
    
    if (source.content != null && source.content!.isNotEmpty) {
       await api.createDocumentFromText(
          datasetId: reportDatasetId,
          name: source.name,
          text: source.content!,
          chunkSize: 1000,
       );
    }
  }

  /// Retrieves relevant context using Semantic Search (RAG)
  static Future<String> _retrieveRelevantContext(Report report, dynamic ref, {required String query}) async {
    if (report.datasetId == null) {
      return _buildContextFromSources(report);
    }

    try {
      final api = ref.read(knowledgeApiServiceProvider);
      final searchResults = await api.retrieveChunks(
          datasetId: report.datasetId!,
          query: query,
          retrievalModel: {'search_mode': 'semantic', 'top_k': 20}
      );
      
      final results = searchResults['records'] as List?;
      
      if (results == null || results.isEmpty) {
          return _buildContextFromSources(report);
      }
      
      final buffer = StringBuffer();
      buffer.writeln("REPORT CONTEXT: ${report.title}");
      buffer.writeln("--- RELEVANT SOURCES (RAG) ---");
      
      for (var item in results) {
          final segment = item['segment'] ?? {};
          final content = segment['content'] ?? "";
          final sourceDoc = segment['document_name'] ?? 'unknown';
          buffer.writeln("\n[From: $sourceDoc]\n$content");
      }
      return buffer.toString();

    } catch (e) {
      print("ReportsLM: RAG retrieval failed: $e. Using fallback.");
      return _buildContextFromSources(report);
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

  // --- Citation Parsing ---

  static List<Citation> _parseCitations(String content, Report report) {
    final citations = <Citation>[];
    final regex = RegExp(r'\[Source:\s*([^,\]]+)(?:,\s*([^\]]+))?\]', caseSensitive: false);
    
    final matches = regex.allMatches(content);
    for (var match in matches) {
      final sourceName = match.group(1)?.trim();
      final extraInfo = match.group(2)?.trim();
      
      if (sourceName != null) {
        String sourceId = 'unknown';
        try {
           final source = report.sources.firstWhere(
             (s) => s.name.toLowerCase() == sourceName.toLowerCase(),
             orElse: () => report.sources.firstWhere(
                (s) => s.name.toLowerCase().contains(sourceName.toLowerCase()),
                orElse: () => report.sources.first
             )
           );
           sourceId = source.id;
        } catch (_) {}
        
        int? pageNum;
        if (extraInfo != null) {
            final pageMatch = RegExp(r'page\s*(\d+)').firstMatch(extraInfo.toLowerCase());
            if (pageMatch != null) {
                pageNum = int.tryParse(pageMatch.group(1)!);
            }
        }

        citations.add(Citation(
            sourceId: sourceId,
            sourceName: sourceName,
            excerpt: match.group(0) ?? "",
            pageNumber: pageNum,
            relevanceScore: 1.0, 
        ));
      }
    }
    return citations;
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

