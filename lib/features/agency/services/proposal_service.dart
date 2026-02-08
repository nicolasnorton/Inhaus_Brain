import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Add Intl for date formatting

import '../../agency/models/proposal_model.dart';
import '../../agency/models/proposal_template.dart';
import '../../agency/models/inhaus_proposal_models.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../../features/knowledge/providers/knowledge_provider.dart';
import 'proposal_pdf_generator.dart';
import 'proposal_slides_generator.dart';
import 'templated_proposal_pdf_generator.dart';
import 'inhaus_proposal_pdf_generator.dart';
import 'inhaus_proposal_slides_generator.dart';
import 'service_catalog_repository.dart';
import '../models/agency_service_model.dart';
import '../../services/services/services_repository.dart' as new_repo;
import '../../services/models/service_model.dart' as new_sm;

class ProposalService {
  static final ServiceCatalogRepository _catalogRepository = ServiceCatalogRepository();
  
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

  // --- INHAUS PROPOSAL GENERATION (NEW) ---

  /// Generate INHAUS-style PDF (One Page Quote or Detailed)
  static Future<Uint8List> generateInhausProposalPdf(
    Proposal proposal,
    dynamic ref, {
    required ProposalType type,
    required ProposalLanguage language,
  }) async {
    final sources = _buildContextFromSources(proposal);
    final catalog = await _catalogRepository.getCatalog();
    final catalogContext = catalog != null ? _buildCatalogContext(catalog) : "";
    
     // Fetch specific services if selected
    String selectedServicesContext = "";
    if (proposal.serviceIds.isNotEmpty) {
      final repo = new_repo.ServicesRepository();
      final selectedServices = await repo.getServicesByIds(proposal.serviceIds);
      if (selectedServices.isNotEmpty) {
        selectedServicesContext = "\n--- SERVICIOS SELECCIONADOS (ADHERENCIA ESTRICTA REQUERIDA) ---\n";
        for (var s in selectedServices) {
          selectedServicesContext += """
SERVICIO: ${s.nameEs} (${s.name})
- Ejecución: ${s.execution}
- Equipo: ${s.team.join(', ')}
- Entregables: ${s.deliverables.join(', ')}
- Incluye: ${s.includes.join(', ')}
- No incluye: ${s.excludes.join(', ')}
- Precio: \$${s.basePrice}

""";
        }
      }
    }
    
    // Inject Date & Language Context
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM, d - yyyy', 'es'); // Always Spanish format
    final dateStr = dateFormat.format(now);
    final dateContext = "CURRENT DATE: ${dateStr[0].toUpperCase()}${dateStr.substring(1)}";
    
    final fullSources = "$catalogContext\n$selectedServicesContext\n\n$dateContext\n\n$sources";
    
    // Check for search sources and perform explicit research step
    String researchContext = "";
    List<String> searchQueries = [];
    
    for (var source in proposal.sources) {
      if (source.name.startsWith("Search:")) {
        searchQueries.add(source.name.replaceAll("Search:", "").trim());
      }
    }

    if (searchQueries.isNotEmpty) {
      debugPrint("ProposalService: Performing research step for ${searchQueries.length} queries...");
      try {
        final researchPrompt = """
You are a senior market researcher.
TASK: Conduct a deep web search for the following entities/queries: ${searchQueries.join(', ')}.

OUTPUT: Provide a comprehensive dossier including:
1. Business Description (Industry, offering, positioning)
2. Target Audience
3. Key Competitors
4. Any public pricing or pricing indications (if available)
5. Recent news or campaigns

CRITICAL: Return only the factual summary. Do not use placeholders. If info is missing, state what was found.
""";
        
        // Use Gemini Flash for speed, or Pro if needed. Using Pro for quality.
        // Explicitly enable Google Search and ensure text mode (no JSON mimeType)
        final researchConfig = AIModelConfig.geminiPro.copyWith(
          useGoogleSearch: true,
          responseMimeType: null, // Ensure text mode for tools
        );

        final researchResult = await EdgeAIService.generateText(
          researchPrompt,
          modelConfig: researchConfig,
          ref: ref,
        );
        
        researchContext = "\n\n=== AI RESEARCH DOSSIER ===\n${researchResult.text}\n===========================\n";
        debugPrint("ProposalService: Research complete. Length: ${researchContext.length}");
        
      } catch (e) {
        debugPrint("ProposalService: Research step failed: $e. Proceeding with basic context.");
        researchContext = "\n\n[Research Attempt Failed: $e]\n";
      }
    }

    // Combine all context
    final combinedSources = "$fullSources$researchContext";
    
    // Final Generation Config (Tools disabled to avoid conflicts with JSON, relying on Research Context)
    final config = AIModelConfig.geminiPro.copyWith(useGoogleSearch: false);

    // 1. Generate INHAUS JSON
    final result = await EdgeAIService.generateText(
      _inhausProposalPrompt(combinedSources, type, language),
      modelConfig: config,
      ref: ref,
    );

    // 2. Parse JSON with robustness
    Map<String, dynamic> jsonData;
    try {
      jsonData = _parseModularJson(result.text);
    } catch (e) {
      debugPrint("ProposalService: Initial JSON parse failed: $e. Retrying with loose parsing...");
      try {
        jsonData = jsonDecode(_stripMarkdown(result.text));
      } catch (innerE) {
        throw Exception("Failed to parse AI response as valid Inhaus JSON. Please try again with a more specific prompt.");
      }
    }

    // 3. Load logos
    Uint8List? agencyLogo;
    Uint8List? clientLogo;

    try {
      // FIX: Use logo_light.png instead of missing logo_inhaus_white.png
      final logoBytes = await rootBundle.load('assets/images/logo_light.png');
      agencyLogo = logoBytes.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error loading agency logo: $e");
    }

    final clientName = jsonData['header']?['client_name'] ?? '';
    if (clientName.isNotEmpty) {
      clientLogo = await _fetchClientLogo(clientName);
    }

    // Fetch embedded images (NEW)
    List<Uint8List> additionalImages = [];
    final imageList = jsonData['embedded_images'] as List<dynamic>?;
    if (imageList != null && imageList.isNotEmpty) {
      for (var url in imageList) {
        if (url is String && url.isNotEmpty) {
          final img = await InhausProposalPdfGenerator.fetchImage(url);
          if (img != null) additionalImages.add(img);
        }
      }
    }

    // 4. Generate PDF based on type
    if (type == ProposalType.onePageQuote) {
      final quote = InhausOnePageQuote.fromJson(jsonData);
      return InhausProposalPdfGenerator.generateOnePageQuote(
        quote,
        agencyLogo: agencyLogo,
        clientLogo: clientLogo,
        additionalImages: additionalImages,
      );
    } else {
      final detailed = InhausDetailedProposal.fromJson(jsonData);
      return InhausProposalPdfGenerator.generateDetailedProposal(
        detailed,
        agencyLogo: agencyLogo,
        clientLogo: clientLogo,
        additionalImages: additionalImages,
      );
    }
  }

  /// Generate INHAUS-style Slides (One Page Quote or Detailed)
  static Future<Uint8List> generateInhausProposalSlides(
    Proposal proposal,
    dynamic ref, {
    required ProposalType type,
    required ProposalLanguage language,
  }) async {
    final sources = _buildContextFromSources(proposal);
    final catalog = await _catalogRepository.getCatalog();
    final catalogContext = catalog != null ? _buildCatalogContext(catalog) : "";
    
    // Fetch specific services if selected
    String selectedServicesContext = "";
    if (proposal.serviceIds.isNotEmpty) {
      final repo = new_repo.ServicesRepository();
      final selectedServices = await repo.getServicesByIds(proposal.serviceIds);
      if (selectedServices.isNotEmpty) {
        selectedServicesContext = "\n--- SERVICIOS SELECCIONADOS (ADHERENCIA ESTRICTA REQUERIDA) ---\n";
        for (var s in selectedServices) {
          selectedServicesContext += """
SERVICIO: ${s.nameEs} (${s.name})
- Ejecución: ${s.execution}
- Equipo: ${s.team.join(', ')}
- Entregables: ${s.deliverables.join(', ')}
- Incluye: ${s.includes.join(', ')}
- No incluye: ${s.excludes.join(', ')}
- Precio: \$${s.basePrice}

""";
        }
      }
    }

    // Inject Date & Language Context
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM, d - yyyy', 'es'); 
    final dateStr = dateFormat.format(now);
    final dateContext = "CURRENT DATE: ${dateStr[0].toUpperCase()}${dateStr.substring(1)}";

    final fullSources = "$catalogContext\n$selectedServicesContext\n\n$dateContext\n\n$sources";

    // Check for search sources and perform explicit research step
    String researchContext = "";
    List<String> searchQueries = [];
    
    for (var source in proposal.sources) {
      if (source.name.startsWith("Search:")) {
        searchQueries.add(source.name.replaceAll("Search:", "").trim());
      }
    }

    if (searchQueries.isNotEmpty) {
      debugPrint("ProposalService (Slides): Performing research step for ${searchQueries.length} queries...");
      try {
        final researchPrompt = """
You are a senior market researcher.
TASK: Conduct a deep web search for the following entities/queries: ${searchQueries.join(', ')}.

OUTPUT: Provide a comprehensive dossier including:
1. Business Description (Industry, offering, positioning)
2. Target Audience
3. Key Competitors
4. Any public pricing or pricing indications (if available)
5. Recent news or campaigns

CRITICAL: Return only the factual summary. Do not use placeholders. If info is missing, state what was found.
""";
        
        final researchConfig = AIModelConfig.geminiPro.copyWith(
          useGoogleSearch: true,
          responseMimeType: null,
        );

        final researchResult = await EdgeAIService.generateText(
          researchPrompt,
          modelConfig: researchConfig,
          ref: ref,
        );
        
        researchContext = "\n\n=== AI RESEARCH DOSSIER ===\n${researchResult.text}\n===========================\n";
        
      } catch (e) {
        debugPrint("ProposalService (Slides): Research step failed: $e. Proceeding with basic context.");
        researchContext = "\n\n[Research Attempt Failed: $e]\n";
      }
    }

    final combinedSources = "$fullSources$researchContext";
    final config = AIModelConfig.geminiPro.copyWith(useGoogleSearch: false);

    // 1. Generate INHAUS JSON
    final result = await EdgeAIService.generateText(
      _inhausProposalPrompt(combinedSources, type, language),
      modelConfig: config,
      ref: ref,
    );

    // 2. Parse JSON with robustness
    Map<String, dynamic> jsonData;
    try {
      jsonData = _parseModularJson(result.text);
    } catch (e) {
      debugPrint("ProposalService: Initial JSON parse failed: $e. Retrying with loose parsing...");
      try {
        jsonData = jsonDecode(_stripMarkdown(result.text));
      } catch (innerE) {
        throw Exception("Failed to parse AI response as valid Inhaus JSON. Please try again with a more specific prompt.");
      }
    }

    // 3. Load logos
    Uint8List? agencyLogo;
    Uint8List? clientLogo;

    try {
      // FIX: Use logo_light.png
      final logoBytes = await rootBundle.load('assets/images/logo_light.png');
      agencyLogo = logoBytes.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error loading agency logo: $e");
    }

    final clientName = jsonData['header']?['client_name'] ?? '';
    if (clientName.isNotEmpty) {
      clientLogo = await _fetchClientLogo(clientName);
    }

    // Fetch embedded images (NEW)
    List<Uint8List> additionalImages = [];
    final imageList = jsonData['embedded_images'] as List<dynamic>?;
    if (imageList != null && imageList.isNotEmpty) {
      for (var url in imageList) {
        if (url is String && url.isNotEmpty) {
          final img = await InhausProposalSlidesGenerator.fetchImage(url);
          if (img != null) additionalImages.add(img);
        }
      }
    }

    // 4. Generate Slides based on type
    if (type == ProposalType.onePageQuote) {
      final quote = InhausOnePageQuote.fromJson(jsonData);
      return InhausProposalSlidesGenerator.generateOnePageQuote(
        quote,
        agencyLogo: agencyLogo,
        clientLogo: clientLogo,
        additionalImages: additionalImages,
      );
    } else {
      final detailed = InhausDetailedProposal.fromJson(jsonData);
      return InhausProposalSlidesGenerator.generateDetailedProposal(
        detailed,
        agencyLogo: agencyLogo,
        clientLogo: clientLogo,
        additionalImages: additionalImages,
      );
    }
  }

  /// System prompt for building INHAUS style JSON v2.0
  static String _inhausProposalPrompt(
      String sources, ProposalType type, ProposalLanguage language) {
    
    String targetLang = language == ProposalLanguage.english ? "English" : "Spanish";

    return '''
Bilingual Client Proposal Specialist - INHAUS Edition (v2.0)

You are the Bilingual Client Proposal Specialist for Inhaus Brain. Your goal is to generate professional, stunning, and conversion-focused business proposals in the authentic INHAUS style.

🎯 CORE OBJECTIVE
Generate valid JSON objects that represent business proposals.

🎨 INHAUS VISUAL IDENTITY
* Backgrounds: Dark/Black (#05050B).
* Headers: Rounded purple bars (#1A1423).
* Typography: Montserrat. White (#FFFFFF) for titles, Light Gray (#A0A0A0) for body text.

💰 PRICING RULES (STRICT)
1. **NO PLACEHOLDERS**: Never use "USD XXX", "TBD", or "\$0.00".
2. **REALISTIC ESTIMATES**: If you don't find a price in the sources/catalog, use these standard INHAUS ranges:
   - Monthly Management (RRSS/Ads): \$1,200.00 - \$3,500.00 USD
   - Content Creation Day: \$800.00 - \$1,500.00 USD
   - Strategy/Audit: \$500.00 - \$1,200.00 USD
   - Branding/Web Dev: \$1,500.00 - \$5,000.00 USD
3. **Currency**: Always use the currency indicated in the sources (Default: USD).

📋 STRUCTURED SERVICE PRESENTATION (CRITICAL)
When "SERVICIOS SELECCIONADOS" are provided in sources, you MUST present each service with this EXACT structure:

### [Nombre del Servicio en Español]

**Descripción Personalizada**: [AI-generated description based on execution details, tailored to client needs - this is the ONLY field you can customize]

**Ejecución**: [Copy EXACTLY from service execution]

**Equipo**: 
- [Team member 1]
- [Team member 2]
- [etc.]

**Entregables**:
- [Deliverable 1]
- [Deliverable 2]
- [etc.]

**Incluye**:
- [Included item 1]
- [Included item 2]
- [etc.]

**No incluye**:
- [Excluded item 1]
- [Excluded item 2]
- [etc.]

**Precio**: \$[exact price from catalog]

⚠️ CRITICAL: You MUST use the EXACT values from the service catalog. Do NOT modify prices, team members, deliverables, includes, or excludes. Only the "Descripción Personalizada" should be AI-generated and contextual.

SOURCES FOR CONTEXT:
$sources

PROPOSAL CONFIGURATION:
- TYPE: ${type == ProposalType.onePageQuote ? "ONE PAGE QUOTE" : "DETAILED MULTI-PAGE"}
- TARGET LANGUAGE: $targetLang

GUIDELINES:
1. **Language**: Translate ALL content to $targetLang.
2. **Hierarchy**: Map client needs to services like SEO, AEO, Paid Media, Creative, Strategy, Dev, RRSS, Content.
3. **Selected Services**: If "SERVICIOS SELECCIONADOS" are provided in the sources, you MUST prioritize them and use the structured format above.
4. **JSON Only**: Return ONLY the JSON object.

JSON SCHEMA:
${type == ProposalType.onePageQuote ? 
    '''{
  "header": {"agency_title": "INHAUS ESTUDIO CREATIVO", "client_name": "...", "date": "Month, Day - Year"},
  "summary": {"intro": "...", "key_services": ["..."], "total_price": {"label": "INVERSIÓN MENSUAL:", "amount": "\$1,500.00 USD"}, "cta": "..."},
  "footer": "inhauscorp.com"
}''' : 
    '''{
  "header": {"agency_title": "INHAUS ESTUDIO CREATIVO", "client_name": "...", "date": "Month, Day - Year"},
  "sections": [{
    "title": "...",
    "description": "...",
    "bullets": ["..."],
    "includes": ["..."],
    "excludes": ["..."],
    "price": {"label": "PRECIO MENSUAL:", "amount": "\$1,500.00 USD"}
  }],
  "footer": "inhauscorp.com"
}'''}
''';
  }

  // --- LEGACY PROPOSAL GENERATION (PRESERVED) ---

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
          memoryContext: sources,
          ref: ref
      ).then((res) => res.text);
  }

  /// Generates the PDF binary data using a template.
  static Future<List<int>> generateProposalPdfBytes(Proposal proposal, dynamic ref, {ProposalTemplate? template}) async {
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
           debugPrint("Error loading agency logo: $e");
        }
        
        // Fetch Client Logo
        if (proposalData.clientName.isNotEmpty) {
             clientLogo = await _fetchClientLogo(proposalData.clientName, domain: proposalData.clientDomain);
        }

        // 4. Render PDF (use template if provided, otherwise use default generator)
        if (template != null) {
          return await TemplatedProposalPdfGenerator.generate(proposalData, template, agencyLogo: agencyLogo, clientLogo: clientLogo);
        } else {
          return await ProposalPdfGenerator.generate(proposalData, agencyLogo: agencyLogo, clientLogo: clientLogo);
        }
    } catch (e) {
        debugPrint("PDF Gen Error: $e");
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
           debugPrint("Error loading agency logo for slides: $e");
        }

        // 4. Render Slides
        return await ProposalSlidesGenerator.generate(proposalData, agencyLogo: agencyLogo);
    } catch (e) {
        debugPrint("Slides Gen Error: $e");
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

  // Helper for modular JSON parsing (extract from tags or direct)
  static Map<String, dynamic> _parseModularJson(String text) {
     final clean = _stripMarkdown(text);
     return jsonDecode(clean);
  }

  static Map<String, dynamic> _parseLooseJson(String text) => _parseModularJson(text);

  static String _stripMarkdown(String text) {
    if (text.contains('```json')) {
      final parts = text.split('```json');
      if (parts.length > 1) {
        return parts[1].split('```')[0].trim();
      }
    } else if (text.contains('```')) {
      final parts = text.split('```');
      if (parts.length > 1) {
        return parts[1].split('```')[0].trim();
      }
    }
    return text.trim();
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
           debugPrint("ProposalService: RAG Retrieval failed: $e");
        }
     }
     
     final String systemPrompt = """
You are the BRIAN Lead Strategist at Inhaus. Your goal is to help the user build a winning proposal.
1.  **Analyze Sources**: Use the provided context to justify every recommendation.
2.  **Creative Thinking**: Don't just list services; describe the 'Why' and the 'Value'.
3.  **Visual Language**: When the user asks 'how it should look', describe a premium, dark-themed aesthetic with gold accents.
4.  **Tone**: Professional, confident, LatAm-focused (Ecuador/Colombia).
5.  **Direct Action**: If the user is satisfied, suggest generating the PDF or Slide Deck using the Studio buttons.
""";

     final catalog = await _catalogRepository.getCatalog();
     final catalogContext = catalog != null ? _buildCatalogContext(catalog) : "";
     context = "$catalogContext\n\n$context";

     final stream = EdgeAIService.generateTextStream(
       query,
       config: AIModelConfig.geminiFlash,
       systemInstruction: systemPrompt,
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
            ? "${source.content!.substring(0, 15000)}...[TRUNCATED]" 
            : source.content);
      } else {
        buffer.writeln("[Source exists but has no extracted text content]");
      }
    }
    return buffer.toString();
  }

  static String _buildCatalogContext(ServiceCatalog catalog) {
    final buffer = StringBuffer();
    buffer.writeln("--- AGENCY SERVICE CATALOG (Use these for pricing and details) ---");
    for (var service in catalog.services) {
      buffer.writeln("\nID: ${service.id}");
      buffer.writeln("Name: ${service.name}");
      buffer.writeln("Description: ${service.description}");
      buffer.writeln("Price: ${service.price} (${service.frequency})");
      if (service.details.isNotEmpty) buffer.writeln("Details: ${service.details.join(', ')}");
      if (service.includes.isNotEmpty) buffer.writeln("Includes: ${service.includes.join(', ')}");
      if (service.excludes.isNotEmpty) buffer.writeln("Excludes: ${service.excludes.join(', ')}");
      if (service.timeEstimate != null) buffer.writeln("Time Estimate: ${service.timeEstimate}");
      if (service.minAdSpend != null) buffer.writeln("Min Ad Spend: ${service.minAdSpend}");
    }
    buffer.writeln("\n--- END OF CATALOG ---");
    return buffer.toString();
  }
}
