import 'dart:typed_data';
import 'dart:convert';
import '../models/agency_service_model.dart';
import '../../../core/services/edge_ai_service.dart';
import '../../../core/tokens/llm_provider.dart';

/// Service for extracting agency services from PDF proposals using Gemini via EdgeAIService
class ServicePdfParserService {
  
  ServicePdfParserService();

  /// Extract services from a PDF file
  Future<List<AgencyService>> extractServicesFromPdf(Uint8List pdfBytes, String filename) async {
    try {
      print('Extracting services from PDF: $filename');

      // Create multimodal prompt with PDF via EdgeAIService
      final prompt = _buildExtractionPrompt();
      
      final result = await EdgeAIService.generateText(
        prompt,
        imageBytes: pdfBytes, // EdgeAIService uses imageBytes for multimodal data
        imageMimeType: 'application/pdf',
        modelConfig: AIModelConfig.geminiFlash, // Using Flash for speed/extraction
      );

      final text = result.text;
      if (text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      print('Received response from Gemini, parsing JSON...');
      
      // Extract JSON from response (handle markdown code blocks)
      final jsonText = _extractJson(text);
      final parsed = jsonDecode(jsonText);

      if (parsed is! List) {
        throw Exception('Expected JSON array, got: ${parsed.runtimeType}');
      }

      final services = <AgencyService>[];
      for (final item in parsed) {
        if (item is Map<String, dynamic>) {
          try {
            services.add(AgencyService.fromJson(item));
          } catch (e) {
            print('Failed to parse service: $e');
            print('Item: $item');
          }
        }
      }

      print('Successfully extracted ${services.length} services from PDF');
      return services;
    } catch (e) {
      print('Error extracting services from PDF: $e');
      rethrow;
    }
  }

  /// Extract services from text content (for pasted text)
  Future<List<AgencyService>> extractServicesFromText(String text) async {
    try {
      print('Extracting services from text (${text.length} chars)');

      final prompt = _buildExtractionPrompt() + '\n\nText content:\n$text';

      final result = await EdgeAIService.generateText(
        prompt,
        modelConfig: AIModelConfig.geminiFlash,
      );

      final responseText = result.text;
      if (responseText.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      final jsonText = _extractJson(responseText);
      final parsed = jsonDecode(jsonText);

      if (parsed is! List) {
        throw Exception('Expected JSON array, got: ${parsed.runtimeType}');
      }

      final services = <AgencyService>[];
      for (final item in parsed) {
        if (item is Map<String, dynamic>) {
          try {
            services.add(AgencyService.fromJson(item));
          } catch (e) {
            print('Failed to parse service: $e');
          }
        }
      }

      print('Successfully extracted ${services.length} services from text');
      return services;
    } catch (e) {
      print('Error extracting services from text: $e');
      rethrow;
    }
  }

  /// Build the extraction prompt for Gemini
  String _buildExtractionPrompt() {
    return '''
You are an expert at extracting agency service offerings from proposal documents.

Extract ALL services/products mentioned in the document and return them as a JSON array.

For each service, extract:
- id: generate a kebab-case ID from the service name (e.g., "web-refresh", "social-starter")
- name: the service name
- description: brief description
- details: array of detailed features/deliverables
- includes: array of what's included
- excludes: array of what's excluded
- price: price as string (e.g., "1500.00" or "1000.00-1500.00" for ranges)
- frequency: "one-time", "monthly", "bimonthly", "quarterly", or "yearly"
- time_estimate: optional time estimate (e.g., "1.5 months")
- min_ad_spend: optional minimum ad spend for pauta services

IMPORTANT RULES:
1. Return ONLY valid JSON array, no markdown, no explanations
2. Extract ALL services found in the document
3. Use Spanish text as-is from the document
4. For prices, use only numbers and decimal point (no currency symbols)
5. Generate unique IDs for each service
6. If a field is not present, use empty array [] or omit optional fields

Example output format:
[
  {
    "id": "web-refresh",
    "name": "Refresh Look & Feel Web",
    "description": "Renovación digital en CMS existente",
    "details": ["Rediseño HOME", "SEO inicial"],
    "includes": [],
    "excludes": ["Hosting/dominio"],
    "price": "1700.00",
    "frequency": "one-time",
    "time_estimate": "1.5 months"
  }
]

Now extract all services from the provided document:
''';
  }

  /// Extract JSON from response (handles markdown code blocks)
  String _extractJson(String text) {
    // Remove markdown code blocks if present
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = codeBlockRegex.firstMatch(text);
    
    if (match != null) {
      return match.group(1)!.trim();
    }

    // Try to find JSON array in text
    final arrayRegex = RegExp(r'\[\s*\{[\s\S]*\}\s*\]');
    final arrayMatch = arrayRegex.firstMatch(text);
    
    if (arrayMatch != null) {
      return arrayMatch.group(0)!;
    }

    // Return as-is and let JSON parser handle it
    return text.trim();
  }
}
