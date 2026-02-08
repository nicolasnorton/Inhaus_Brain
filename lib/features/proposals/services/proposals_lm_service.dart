import '../models/proposal_model.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../knowledge/providers/knowledge_provider.dart';
import 'proposal_pdf_service.dart';
import 'dart:typed_data';

class GenerationResult {
  final String content;
  final Uint8List? pdfBytes;
  final String? uri;

  GenerationResult({required this.content, this.pdfBytes, this.uri});
}

class ProposalsLMService {
  // --- SYSTEM PROMPTS ---

  static const String _retrievalPrompt =
      "Analyze the provided sources and extract: client needs, target audience, services requested, budget constraints, timeline requirements, and key selling points. Prepare this data for a proposal specialist.";

  static const String _outlinerPrompt =
      "Based on the extracted information, create a structured outline for a professional proposal. Include: Executive Summary, Client Needs Analysis, Proposed Services, Pricing Structure, Timeline, and Call to Action.";

  static String _detailedGeneratorPrompt(String sources) => """
You are an expert proposal specialist for INHAUS ESTUDIO CREATIVO creating a detailed client proposal.

STRICT RULES:
- Ground everything in the provided sources; no external knowledge.
- Output MUST be valid JSON matching the 'detailed' schema from the proposal_specialist.md prompt.
- Use Spanish as primary language (bilingual optional).
- Apply INHAUS visual style: dark purple theme (#1A0F2E), purple accents (#6B46C1).

REQUIRED JSON STRUCTURE:
{
  "type": "detailed",
  "format": "pdf",
  "header": {
    "agency_title": "INHAUS ESTUDIO CREATIVO",
    "client_name": "...",
    "date": "..."
  },
  "sections": [
    {
      "title": "RRSS" (or service name),
      "description": "...",
      "bullets": ["..."],
      "includes": ["..."],
      "excludes": ["..."],
      "price": {"label": "PRECIO:", "amount": "USD XXX"}
    }
  ],
  "footer": "..."
}

Sources: $sources
""";

  static String _onePageGeneratorPrompt(String sources) => """
You are an expert proposal specialist for INHAUS ESTUDIO CREATIVO creating a one-page quote.

STRICT RULES:
- Ground everything in the provided sources; no external knowledge.
- Output MUST be valid JSON matching the 'one_page' schema from the proposal_specialist.md prompt.
- Use Spanish as primary language.
- Apply INHAUS visual style.

REQUIRED JSON STRUCTURE:
{
  "type": "one_page",
  "format": "pdf",
  "header": {
    "agency_title": "INHAUS ESTUDIO CREATIVO",
    "client_name": "...",
    "date": "..."
  },
  "summary": {
    "intro": "...",
    "key_services": ["...", "..."],
    "total_price": {"label": "TOTAL:", "amount": "USD XXX"},
    "cta": "..."
  }
}

Sources: $sources
""";

  /// Generates a Detailed Proposal PDF
  static Future<GenerationResult> generateDetailedProposal(
    Proposal proposal,
    dynamic ref, {
    bool isPreview = false,
  }) async {
    final sources = _buildContextFromSources(proposal);

    if (isPreview) {
      final res = await EdgeAIService.generateText(
        _detailedGeneratorPrompt(sources),
        modelConfig: AIModelConfig.gemma2n,
        ref: ref,
      );
      return GenerationResult(content: res.text);
    }

    // Agentic Workflow
    // 1. Retrieval
    final retrieval = await EdgeAIService.generateText(
      "Retrieval Agent: $_retrievalPrompt",
      memoryContext: sources,
      ref: ref,
    );

    // 2. Outliner
    final outline = await EdgeAIService.generateText(
      "Outliner Agent: $_outlinerPrompt\n\nContext:\n${retrieval.text}",
      memoryContext: sources,
      ref: ref,
    );

    // 3. Generator (Proposal Specialist)
    final proposalJson = await EdgeAIService.generateText(
      _detailedGeneratorPrompt(sources) +
          "\n\nUse this outline:\n${outline.text}",
      modelConfig: AIModelConfig.geminiFlash,
      outputMode: 'json',
      ref: ref,
    );

    // 4. PDF Generation
    try {
      final proposalData = ProposalData.fromRawJson(proposalJson.text);
      final pdfBytes = await ProposalPdfService.generateProposalPdf(proposalData);

      return GenerationResult(
        content: proposalJson.text,
        pdfBytes: pdfBytes,
      );
    } catch (e) {
      return GenerationResult(
        content: "Error generating PDF: $e\n\nRaw JSON:\n${proposalJson.text}",
      );
    }
  }

  /// Generates a One-Page Quote PDF
  static Future<GenerationResult> generateOnePageQuote(
    Proposal proposal,
    dynamic ref, {
    bool isPreview = false,
  }) async {
    final sources = _buildContextFromSources(proposal);

    if (isPreview) {
      final res = await EdgeAIService.generateText(
        _onePageGeneratorPrompt(sources),
        modelConfig: AIModelConfig.gemma2n,
        ref: ref,
      );
      return GenerationResult(content: res.text);
    }

    // Agentic Workflow (simplified for one-page)
    final retrieval = await EdgeAIService.generateText(
      "Retrieval Agent: $_retrievalPrompt",
      memoryContext: sources,
      ref: ref,
    );

    final proposalJson = await EdgeAIService.generateText(
      _onePageGeneratorPrompt(sources) + "\n\nContext:\n${retrieval.text}",
      modelConfig: AIModelConfig.geminiFlash,
      outputMode: 'json',
      ref: ref,
    );

    // PDF Generation
    try {
      final proposalData = ProposalData.fromRawJson(proposalJson.text);
      final pdfBytes = await ProposalPdfService.generateProposalPdf(proposalData);

      return GenerationResult(
        content: proposalJson.text,
        pdfBytes: pdfBytes,
      );
    } catch (e) {
      return GenerationResult(
        content: "Error generating PDF: $e\n\nRaw JSON:\n${proposalJson.text}",
      );
    }
  }

  /// Generates Google Slides (Future Implementation)
  static Future<GenerationResult> generateGoogleSlides(
    Proposal proposal,
    dynamic ref,
  ) async {
    // TODO: Implement Google Slides generation
    return GenerationResult(
      content: "Google Slides generation not yet implemented.",
    );
  }

  /// Chat with Proposal (RAG-enabled)
  static Stream<String> chatWithProposal(
    Proposal proposal,
    String query,
    dynamic ref,
  ) async* {
    String context = _buildContextFromSources(proposal);

    // INTEGRATION: If proposal has a linked Knowledge Base, perform RAG
    if (proposal.datasetId != null && ref != null) {
      try {
        final api = ref.read(knowledgeApiServiceProvider);
        final searchResults = await api.retrieveChunks(
          datasetId: proposal.datasetId!,
          query: query,
          retrievalModel: {'search_mode': 'semantic'},
        );

        final results = searchResults['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final ragContext = results.map((c) => c['content']).join('\n\n');
          context =
              "--- RELEVANT SEARCH RESULTS ---\n$ragContext\n\n--- FALLBACK CONTEXT ---\n$context";
        }
      } catch (e) {
        print("ProposalsLM: RAG Retrieval failed: $e");
      }
    }

    final systemPrompt = """
You are an expert proposal specialist at INHAUS.
Your goal is to help the user refine their proposal strategy.
CRITICAL:
- Be concise and direct. No fluff.
- Do NOT repeat the user's question.
- Focus on actionable advice for the proposal.
- Use bullet points for clarity.
- Stay professional and on-brand (INHAUS).
""";

    final stream = EdgeAIService.generateTextStream(
      "$systemPrompt\n\nCONTEXT:\n$context\n\nUSER QUERY: $query",
      config: AIModelConfig.geminiFlash,
      ref: ref,
    );

    await for (final result in stream) {
      yield result.text;
    }
  }

  static String _buildContextFromSources(Proposal proposal) {
    final buffer = StringBuffer();
    buffer.writeln("PROPOSAL CONTEXT: ${proposal.title}");
    buffer.writeln("CLIENT: ${proposal.clientName}");
    for (var source in proposal.sources) {
      buffer.writeln("\n--- SOURCE: ${source.name} (${source.type.displayName}) ---");
      if (source.content != null) {
        // Reduced to 8000 to stay within safe payload limits for Web/Proxy
        buffer.writeln(source.content!.length > 8000
            ? source.content!.substring(0, 8000) + "...[TRUNCATED]"
            : source.content);
      } else {
        buffer.writeln("[No text content available]");
      }
    }
    return buffer.toString();
  }
}
