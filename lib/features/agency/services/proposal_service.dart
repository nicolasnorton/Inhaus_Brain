import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../../agency/models/proposal_model.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../../features/knowledge/providers/knowledge_provider.dart';
import 'proposal_pdf_generator.dart';
import 'proposal_slides_generator.dart';


class ProposalService {
  
  // --- SYSTEM PROMPTS ---


  static String _proposalJsonPrompt(String sources) => """
You are a Sales Operations Expert. Your task is to extract proposal details from the provided context and format them into a strict JSON structure for our invoice generation system.

The JSON format must match this schema EXACTLY:
{
  "clientName": "String (Client Name)",
  "clientDomain": "String (Optional, e.g., company.com)",
  "date": "String (e.g., Febrero, 4 - 2026)",
  "sections": [
    {
      "title": "String (Service Title, e.g., RRSS / FACEBOOK)",
      "description": "String (Short summary)",
      "items": ["String (Deliverable 1)", "String (Deliverable 2)"],
      "price": "String (e.g., \$1,500.00)",
      "frequency": "String (e.g., PRECIO MENSUAL, TOTAL, PAGO ÚNICO)"
    }
  ]
}

Rules:
1.  **Extract real data** from the sources (Service Catalog prices, deliverables, client info).
2.  **Domain**: If a website or domain for the client is found in the sources, include it in "clientDomain".
3.  **Theme**: Use the "Inhaus" agency packages (Starter, Corporate, etc.) if mentioned.
4.  **Tone**: Professional and concise for the descriptions.
5.  **Language**: Spanish (Español) as per the templates.
6.  **Output**: ONLY valid JSON. No markdown fencing.

Sources:
$sources
""";

  static String _proposalSlidesPrompt(String sources) => """
You are a Presentation Design Expert creating a **Sales Deck Outline**.
Your goal is to structure a compelling pitch deck that accompanies the written proposal.

Steps:
1.  Outline 8-12 slides.
2.  For each slide, provide:
    *   **Title**: Catchy and relevant.
    *   **Key Talking Points**: 3-4 bullet points.
    *   **Visual Suggestion**: What should be on the slide (chart, photo, icon).

Standard Flow:
1.  Title Slide
2.  The Challenge (Problem)
3.  The Opportunity (Vision)
4.  Our Solution (Strategy)
5.  Deliverables (What they get)
6.  Social Proof (Case Studies/Testimonials - generic if not in sources)
7.  Investment (Pricing)
8.  Timeline
9.  Next Steps

Rules:
- One key idea per slide.
- Minimal text, high impact.

Output Format (Markdown):
### Slide 1: [Title]
- Point 1
- Point 2
**Visual**: [Description]

Sources:
$sources
""";

  /// UI Entry point for PDF Generation (returns Markdown summary).
  static Future<String> generateProposalPdf(Proposal proposal, dynamic ref, {bool isPreview = true}) async {
      return generateProposalContent(proposal, ref, isPreview: isPreview);
  }

  /// UI Entry point for Slide Generation (returns Markdown outline).
  static Future<String> generateProposalSlides(Proposal proposal, dynamic ref, {bool isPreview = true}) async {
      final sources = _buildContextFromSources(proposal);
      final config = isPreview ? AIModelConfig.geminiFlash : AIModelConfig.geminiPro;
      
      final result = await EdgeAIService.generateText(
          _proposalSlidesPrompt(sources),
          modelConfig: config,
          ref: ref
      );
      return result.text;
  }

  /// Generates a structured Proposal context (Markdown summary).
  static Future<String> generateProposalContent(Proposal proposal, dynamic ref, {bool isPreview = false}) async {
      final sources = _buildContextFromSources(proposal);
      final config = isPreview ? AIModelConfig.geminiFlash : AIModelConfig.geminiPro;
      
      return await EdgeAIService.generateText(
          "Summarize the proposal ${proposal.title} based on these sources. Use Markdown.", 
          modelConfig: config, 
          ref: ref
      ).then((res) => res.text);
  }

  /// Generates the PDF binary data.
  static Future<List<int>> generateProposalPdfBytes(Proposal proposal, dynamic ref) async {
    final sources = _buildContextFromSources(proposal);
    final config = AIModelConfig.geminiPro;

    // 1. Generate JSON Data
    final result = await EdgeAIService.generateText(
      _proposalJsonPrompt(sources),
      modelConfig: config,
      ref: ref,
    );

    // 2. Parse JSON
    String cleanJson = result.text.replaceAll('```json', '').replaceAll('```', '').trim();
    
    try {
        final Map<String, dynamic> dataMap = _parseLooseJson(cleanJson);
        final proposalData = ProposalData.fromJson(dataMap);
        
        // 3. Load Images
        Uint8List? agencyLogo;
        Uint8List? clientLogo;
        
        try {
           final byteData = await rootBundle.load('assets/images/logo_light.png');
           agencyLogo = byteData.buffer.asUint8List();
        } catch (e) {
           print("Error loading agency logo: $e");
        }
        
        // Fetch Client Logo
        if (proposalData.clientName.isNotEmpty) {
             clientLogo = await _fetchClientLogo(proposalData.clientName, domain: proposalData.clientDomain);
        }

        // 4. Render PDF
        return await ProposalPdfGenerator.generate(proposalData, agencyLogo: agencyLogo, clientLogo: clientLogo);
    } catch (e) {
        print("PDF Gen Error: $e");
        throw Exception("Failed to generate PDF: $e");
    }
  }

  /// Generates the Slide Deck binary data (landscape PDF).
  static Future<List<int>> generateProposalSlidesBytes(Proposal proposal, dynamic ref) async {
    final sources = _buildContextFromSources(proposal);
    final config = AIModelConfig.geminiPro;

    // 1. Generate JSON Data (Same structure as PDF, but used for slides)
    final result = await EdgeAIService.generateText(
      _proposalJsonPrompt(sources),
      modelConfig: config,
      ref: ref,
    );

    // 2. Parse JSON
    String cleanJson = result.text.replaceAll('```json', '').replaceAll('```', '').trim();
    
    try {
        final Map<String, dynamic> dataMap = _parseLooseJson(cleanJson);
        final proposalData = ProposalData.fromJson(dataMap);
        
        // 3. Load Images
        Uint8List? agencyLogo;
        try {
           final byteData = await rootBundle.load('assets/images/logo_light.png');
           agencyLogo = byteData.buffer.asUint8List();
        } catch (e) {
           print("Error loading agency logo for slides: $e");
        }

        // 4. Render Slides
        return await ProposalSlidesGenerator.generate(proposalData, agencyLogo: agencyLogo);
    } catch (e) {
        print("Slides Gen Error: $e");
        throw Exception("Failed to generate Slides: $e");
    }
  }

  static Future<Uint8List?> _fetchClientLogo(String clientName, {String? domain}) async {
      // Heuristic: Try Clearbit with some common domains or just use the name
      // Ideally the AI should extract the domain. 
      
      final List<String> domains = [];
      if (domain != null && domain.isNotEmpty) {
          domains.add(domain);
      }
      
      final brand = clientName.split(' ')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (brand.length >= 3) {
          domains.addAll(['$brand.com', '$brand.ec', '$brand.io']);
      }
      
      for (final d in domains) {
          try {
             final response = await http.get(Uri.parse('https://logo.clearbit.com/$d')).timeout(const Duration(seconds: 2));
             if (response.statusCode == 200) {
                return response.bodyBytes;
             }
          } catch (_) {}
      }
      return null;
  }

  // Helper for basic JSON parsing
  static Map<String, dynamic> _parseLooseJson(String text) {
     return jsonDecode(text);
  }


  /// Chat with the Proposal Context (RAG enabled).
  static Stream<String> chatWithProposal(Proposal proposal, String query, dynamic ref) async* {
     String context = _buildContextFromSources(proposal);
     
     // RAG Integration
     if (proposal.datasetId != null && ref != null) {
        try {
           final api = ref.read(knowledgeApiServiceProvider);
           final searchResults = await api.retrieveChunks(
              datasetId: proposal.datasetId!,
              query: query,
              retrievalModel: {'search_mode': 'semantic'}
           );
           
           final results = searchResults['results'] as List?;
           if (results != null && results.isNotEmpty) {
              final ragContext = results.map((c) => c['content']).join('\n\n');
              context = "--- RELEVANT SEARCH RESULTS ---\n$ragContext\n\n--- FALLBACK CONTEXT ---\n$context";
           }
        } catch (e) {
           print("ProposalService: RAG Retrieval failed: $e");
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

  static String _buildContextFromSources(Proposal proposal) {
    if (proposal.sources.isEmpty) {
      return "PROPOSAL CONTEXT: ${proposal.title}\n[WARNING: NO SOURCES PROVIDED. PLEASE DO NOT HALLUCINATE. ASK FOR DATA.]";
    }
    
    final buffer = StringBuffer();
    buffer.writeln("PROPOSAL CONTEXT: ${proposal.title}");
    for (var source in proposal.sources) {
      buffer.writeln("\n--- SOURCE: ${source.name} (${source.type.name}) ---");
      if (source.content != null && source.content!.isNotEmpty) {
        buffer.writeln(source.content!.length > 15000 
            ? source.content!.substring(0, 15000) + "...[TRUNCATED]" 
            : source.content);
      } else {
        buffer.writeln("[Source exists but has no extracted text content]");
      }
    }
    return buffer.toString();
  }
}
