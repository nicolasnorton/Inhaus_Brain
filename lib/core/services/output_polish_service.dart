import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:inhaus_brain/core/services/edge_ai_service.dart';
import 'package:inhaus_brain/core/tokens/llm_provider.dart';

/// A specialized service to "polish" agent outputs.
/// It fixes grammar, structure, tone errors, and ensures bilingual consistency.
class OutputPolishService {
  final _logger = Logger();
  final Ref _ref;

  OutputPolishService(this._ref);

  Future<String> polishText(String rawText, {String locale = 'en'}) async {
    // Skip short texts to save latency
    if (rawText.length < 50) return rawText;

    final prompt = """
You are the Inhaus Brain Editor-in-Chief.
Your task is to POLISH the following text to perfection.

GUIDELINES:
1. Fix all grammar, spelling, and punctuation errors.
2. Tone: Professional, confident, concise (Executive Level). No fluff.
3. Language: Keep the target locale ($locale) consistent. 
   - If Spanish: Use "Usted" for B2B, "Tú" for B2C/Creative context. Avoid Spain-specific terms (e.g. "coger", "vosotros"). Use LatAm standard.
4. Structure: improve readability (bullet points, bolding).
5. DO NOT change the core meaning or facts.
6. JSON: If the input contains JSON, DO NOT touch the JSON structure or keys. Only polish the values if they are user-facing strings.

INPUT TEXT:
$rawText

OUTPUT:
Return ONLY the polished text. No meta-commentary.
""";

    try {
      final result = await EdgeAIService.generateText(
        prompt,
        modelConfig: const AIModelConfig(
          provider: AIProvider.gemini,
          modelId: 'gemini-1.5-flash', // Use Flash for speed
          temperature: 0.3,
        ),
        ref: _ref,
      );
      return result.text;
    } catch (e) {
      _logger.e('OutputPolishService failed: $e');
      return rawText; // Fallback to original
    }
  }
}

final outputPolishServiceProvider = Provider<OutputPolishService>((ref) => OutputPolishService(ref));
