/// TranslateGemma Service — multilingual campaign content.
///
/// Uses TranslateGemma 4B for translation across 55 languages.
/// Staging-gated via [AppConfig.enableGemma]. Falls back to
/// Gemini Flash when disabled.
library;

import 'package:logger/logger.dart';
import '../../config/app_environment.dart';
import '../../tokens/llm_provider.dart';
import 'ai_generation_request.dart';
import 'ai_router.dart';

class TranslateGemmaService {
  static final _logger = Logger();

  /// Supported language codes (subset — TranslateGemma supports 55).
  static const supportedLanguages = {
    'en': 'English', 'es': 'Spanish', 'fr': 'French', 'de': 'German',
    'it': 'Italian', 'pt': 'Portuguese', 'nl': 'Dutch', 'ja': 'Japanese',
    'ko': 'Korean', 'zh': 'Chinese', 'ar': 'Arabic', 'hi': 'Hindi',
    'ru': 'Russian', 'tr': 'Turkish', 'pl': 'Polish', 'sv': 'Swedish',
    'da': 'Danish', 'no': 'Norwegian', 'fi': 'Finnish', 'th': 'Thai',
    'vi': 'Vietnamese', 'id': 'Indonesian', 'ms': 'Malay', 'uk': 'Ukrainian',
    'cs': 'Czech', 'ro': 'Romanian', 'hu': 'Hungarian', 'el': 'Greek',
    'he': 'Hebrew', 'bg': 'Bulgarian', 'hr': 'Croatian', 'sk': 'Slovak',
  };

  /// Translate content to the target language.
  ///
  /// Uses TranslateGemma 4B when Gemma is enabled, otherwise falls
  /// back to Gemini Flash with a translation prompt.
  static Future<String> translate(
    String content, {
    required String targetLanguage,
    String sourceLanguage = 'en',
    bool preserveFormatting = true,
  }) async {
    final targetName = supportedLanguages[targetLanguage] ?? targetLanguage;
    final sourceName = supportedLanguages[sourceLanguage] ?? sourceLanguage;

    _logger.d('Translate: $sourceName → $targetName (${content.length} chars)');

    final AIModelConfig config;
    final String prompt;

    if (AppConfig.enableGemma) {
      // Use TranslateGemma for dedicated translation
      config = AIModelConfig(
        modelId: 'translategemma-4b',
        provider: AIProvider.gemma,
        // displayName: 'TranslateGemma',
        temperature: 0.2,
        maxTokens: content.length * 2, // Translations can be longer
      );
      prompt = '<2$targetLanguage>\n$content';
    } else {
      // Fallback to Gemini Flash with translation prompt
      config = AIModelConfig.geminiFlash;
      prompt = '''Translate the following text from $sourceName to $targetName.
${preserveFormatting ? 'Preserve all formatting, markdown, and special characters.' : ''}
Only output the translation, nothing else.

$content''';
    }

    final request = AIGenerationRequest(
      prompt: prompt,
      config: config,
    );

    final result = await AIRouter.generate(request);
    return result.text.trim();
  }

  /// Translate content to multiple languages in parallel.
  static Future<Map<String, String>> translateBatch(
    String content, {
    required List<String> targetLanguages,
    String sourceLanguage = 'en',
  }) async {
    final futures = <String, Future<String>>{};
    for (final lang in targetLanguages) {
      futures[lang] = translate(
        content,
        targetLanguage: lang,
        sourceLanguage: sourceLanguage,
      );
    }

    final results = <String, String>{};
    for (final entry in futures.entries) {
      try {
        results[entry.key] = await entry.value;
      } catch (e) {
        _logger.w('Translate: Failed for ${entry.key}: $e');
        results[entry.key] = '[Translation failed]';
      }
    }
    return results;
  }
}
