import '../models/proposal_model.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';
import '../../knowledge/providers/knowledge_provider.dart';
import '../../agency/models/agency_service_model.dart';
import '../../agency/models/inhaus_proposal_models.dart';
import '../../agency/services/inhaus_proposal_pdf_generator.dart';
import '../../clients/models/client_model.dart';
import 'dart:convert';
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
You are the Bilingual Client Proposal Specialist for INHAUS ESTUDIO CREATIVO.
Your goal is to generate professional, stunning, and conversion-focused business proposals in the authentic INHAUS style (v2.0).

STRICT RULES:
1. Ground everything in the provided sources and SERVICE CATALOG data. Do NOT invent prices — use the EXACT prices from the SERVICE CATALOG.
2. Output MUST be valid JSON matching the v2.0 schema below.
3. Use Spanish (ES) for all content.
4. Create one section per selected service from the catalog.
5. Each section MUST include the service's real price from the catalog.

REQUIRED JSON STRUCTURE (InhausDetailedProposal):
{
  "type": "detailed",
  "format": "pdf",
  "header": {
    "agency_title": "INHAUS ESTUDIO CREATIVO",
    "client_name": "...",
    "client_logo_url": null,
    "date": "Febrero 17, 2026"
  },
  "sections": [
    {
      "title": "NOMBRE DEL SERVICIO",
      "intro_paragraph": "Descripción profesional del servicio...",
      "ejecucion": "Detalle del proceso de ejecución y timeline...",
      "incluye": ["Entregable 1", "Entregable 2"],
      "no_incluye": ["Exclusión 1", "Exclusión 2"],
      "equipo": ["Director Creativo", "Diseñador"],
      "entregables": ["Archivo final en PDF", "Manual de marca"],
      "price": {
        "label": "INVERSIÓN:",
        "amount": "USD 1,500.00"
      }
    }
  ],
  "footer": "inhauscorp.com"
}

Sources: $sources
""";

  static String _onePageGeneratorPrompt(String sources) => """
You are the Bilingual Client Proposal Specialist for INHAUS ESTUDIO CREATIVO creating a high-impact summary quote.

STRICT RULES:
1. Ground everything in the provided sources and SERVICE CATALOG data. Use EXACT prices from the catalog.
2. Output MUST be valid JSON matching the one_page schema below.
3. Use Spanish (ES).
4. Calculate the total price by summing ALL selected services from the catalog.

REQUIRED JSON STRUCTURE (InhausOnePageQuote):
{
  "type": "one_page",
  "format": "pdf",
  "header": {
    "agency_title": "INHAUS ESTUDIO CREATIVO",
    "client_name": "...",
    "client_logo_url": null,
    "date": "Febrero 17, 2026"
  },
  "summary": {
    "intro_paragraph": "Resumen ejecutivo de la propuesta para el cliente...",
    "ejecucion": "Timeline y proceso general...",
    "incluye": ["Servicio 1: Beneficio principal", "Servicio 2: Valor agregado"],
    "no_incluye": ["Exclusión 1"],
    "equipo": ["Director Creativo", "Community Manager"],
    "entregables": ["Informe mensual", "Contenido digital"],
    "precio": {"label": "TOTAL INVERSIÓN:", "amount": "USD X,XXX.00"},
    "cta": "Próximos pasos y contacto."
  },
  "footer": "inhauscorp.com"
}

Sources: $sources
""";

  /// Build service catalog context string from selected services
  static String _buildServiceCatalogContext(List<AgencyService> services) {
    if (services.isEmpty) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('\n--- SERVICE CATALOG (Selected Services) ---');
    for (var service in services) {
      buffer.writeln('\nSERVICIO: ${service.name}');
      buffer.writeln('  Descripción: ${service.description}');
      buffer.writeln('  Precio: USD ${service.basePrice.toStringAsFixed(2)}');
      buffer.writeln('  Frecuencia: ${service.frequency}');
      if (service.details.isNotEmpty) {
        buffer.writeln('  Detalles: ${service.details.join(', ')}');
      }
      if (service.includes.isNotEmpty) {
        buffer.writeln('  Incluye: ${service.includes.join(', ')}');
      }
      if (service.excludes.isNotEmpty) {
        buffer.writeln('  No Incluye: ${service.excludes.join(', ')}');
      }
      if (service.timeEstimate != null) {
        buffer.writeln('  Tiempo estimado: ${service.timeEstimate}');
      }
      if (service.minAdSpend != null) {
        buffer.writeln('  Pauta mínima: USD ${service.minAdSpend}');
      }
    }
    return buffer.toString();
  }

  /// Build client context string
  static String _buildClientContext(Client? client) {
    if (client == null) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('\n--- CLIENT DETAILS ---');
    buffer.writeln('Nombre: ${client.name}');
    buffer.writeln('Tipo: ${client.clientType == ClientType.corporate ? 'Corporativo' : 'Independiente'}');
    buffer.writeln('Industria: ${client.industry}');
    if (client.description != null && client.description!.isNotEmpty) {
      buffer.writeln('Descripción: ${client.description}');
    }
    if (client.website != null && client.website!.isNotEmpty) {
      buffer.writeln('Website: ${client.website}');
    }
    if (client.size != null && client.size!.isNotEmpty) {
      buffer.writeln('Tamaño: ${client.size}');
    }
    if (client.primaryContactEmail != null && client.primaryContactEmail!.isNotEmpty) {
      buffer.writeln('Email: ${client.primaryContactEmail}');
    }
    if (client.contacts.isNotEmpty) {
      buffer.writeln('Contactos:');
      for (var contact in client.contacts) {
        buffer.writeln('  - ${contact.firstName} ${contact.lastName} (${contact.role})');
      }
    }
    return buffer.toString();
  }

  /// Generates a Detailed Proposal PDF
  static Future<GenerationResult> generateDetailedProposal(
    Proposal proposal,
    dynamic ref, {
    bool isPreview = false,
    List<AgencyService> selectedServices = const [],
    Client? client,
  }) async {
    final sources = _buildContextFromSources(proposal) +
        _buildServiceCatalogContext(selectedServices) +
        _buildClientContext(client);

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

    // 4. PDF Generation using INHAUS PDF Generator
    try {
      final jsonStr = _extractJson(proposalJson.text);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final inhausProposal = InhausDetailedProposal.fromJson(data);
      
      // Try to load agency logo
      Uint8List? agencyLogo;
      try {
        final logoBytes = await InhausProposalPdfGenerator.fetchImage(
          client?.logoUrl ?? '',
        );
        agencyLogo = logoBytes;
      } catch (_) {}
      
      final pdfBytes = await InhausProposalPdfGenerator.generateDetailedProposal(
        inhausProposal,
        agencyLogo: null, // Will use text fallback from header
        clientLogo: agencyLogo,
      );

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
    List<AgencyService> selectedServices = const [],
    Client? client,
  }) async {
    final sources = _buildContextFromSources(proposal) +
        _buildServiceCatalogContext(selectedServices) +
        _buildClientContext(client);

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

    // PDF Generation using INHAUS PDF Generator
    try {
      final jsonStr = _extractJson(proposalJson.text);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final inhausQuote = InhausOnePageQuote.fromJson(data);
      
      Uint8List? clientLogo;
      if (client?.logoUrl != null && client!.logoUrl!.isNotEmpty) {
        clientLogo = await InhausProposalPdfGenerator.fetchImage(client.logoUrl!);
      }
      
      final pdfBytes = await InhausProposalPdfGenerator.generateOnePageQuote(
        inhausQuote,
        clientLogo: clientLogo,
      );

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
    dynamic ref, {
    List<AgencyService> selectedServices = const [],
    Client? client,
  }) async* {
    String context = _buildContextFromSources(proposal) +
        _buildServiceCatalogContext(selectedServices) +
        _buildClientContext(client);

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
You are an expert proposal specialist at INHAUS estudio creativo (Cuenca, Ecuador).
Your goal is to help the user (the Proformador) build a business proposal by extracting structured actions from the conversation.

CONTEXT:
- IVA in Ecuador: 15%.
- "client" is the client's name.

INSTRUCCIONES:
Responde SIEMPRE con un JSON válido. No incluyas texto fuera del JSON.
{
  "reply": "Tu respuesta conversacional en español, amigable y eficiente.",
  "action": "none|add|remove|set_client|set_discount|set_iva_on|set_iva_off|save|new_package",
  "client": "Nombre del cliente (si se menciona)",
  "packages": ["ID del paquete/servicio"],
  "removeIds": ["ID a remover"],
  "discount": null
}

REGLAS:
- Si el usuario pide agregar servicios → action: "add", paquetes: [IDs exactos del catálogo].
- Si el usuario pide quitar algo → action: "remove", removeIds: [IDs].
- Si menciona cliente → incluir en "client".
- Si menciona descuento → "discount" como número (ej: 10).
- Si dice "con IVA" → "set_iva_on", "sin IVA" → "set_iva_off".
- Si quiere guardar → "save".
- Si quiere crear algo nuevo → "new_package".
- Sé amigable y profesional.
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

  /// Extract JSON from LLM response (handles markdown code fences)
  static String _extractJson(String raw) {
    // Strip markdown code fences if present
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  static String _buildContextFromSources(Proposal proposal) {
    final buffer = StringBuffer();
    buffer.writeln("PROPOSAL CONTEXT: ${proposal.title}");
    buffer.writeln("CLIENT: ${proposal.clientName}");
    if (proposal.serviceIds.isNotEmpty) {
      buffer.writeln("SELECTED SERVICE IDS: ${proposal.serviceIds.join(', ')}");
    }
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
