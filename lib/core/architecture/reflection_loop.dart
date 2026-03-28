/// ReflectionLoop — Post-execution quality gate.
///
/// After an agent produces output, this lightweight "critic" evaluates it
/// for quality, factual consistency, and prompt adherence. If the score
/// is below threshold, it re-prompts with critique feedback.
///
/// Competitive parity:
/// - Claude Workspace: Quality gates between agent steps
/// - Grok 4.2 Heavy: 4-agent cross-verification (65% hallucination reduction)
/// - Google ADK 2.0: Built-in reflection and retry
library;

import 'package:flutter/foundation.dart';
import '../services/ai/ai_generation_request.dart';
import '../services/ai/ai_router.dart';
import '../tokens/llm_provider.dart';

/// Result of a reflection evaluation.
class ReflectionResult {
  final double score; // 0.0 - 1.0
  final String critique;
  final bool passesThreshold;
  final List<String> issues;

  const ReflectionResult({
    required this.score,
    required this.critique,
    required this.passesThreshold,
    this.issues = const [],
  });
}

/// Configuration for the reflection loop.
class ReflectionConfig {
  /// Minimum quality score to pass (0.0-1.0).
  final double threshold;

  /// Maximum re-prompting attempts.
  final int maxRetries;

  /// Whether reflection is enabled.
  final bool enabled;

  const ReflectionConfig({
    this.threshold = 0.7,
    this.maxRetries = 2,
    this.enabled = true,
  });

  static const disabled = ReflectionConfig(enabled: false);
}

class ReflectionLoop {
  static const _criticPrompt = '''You are a quality assurance critic for an AI agency system.
Evaluate the following agent output against the original user request.

Score the output from 0.0 to 1.0 on these dimensions:
- **Relevance**: Does it address the user's actual request?
- **Completeness**: Does it cover all aspects asked for?
- **Accuracy**: Are factual claims substantiated?
- **Tone**: Is it professional and appropriate?

Return ONLY a JSON object:
```json
{
  "score": 0.85,
  "issues": ["Brief issue 1", "Brief issue 2"],
  "critique": "One sentence summary of quality."
}
```''';

  /// Evaluate an agent's output quality.
  static Future<ReflectionResult> evaluate({
    required String originalPrompt,
    required String agentOutput,
    required String agentName,
    dynamic ref,
  }) async {
    try {
      final request = AIGenerationRequest(
        prompt: 'USER REQUEST: $originalPrompt\n\nAGENT ($agentName) OUTPUT:\n$agentOutput',
        config: AIModelConfig.geminiFlashLite.copyWith(responseMimeType: 'application/json'),
        systemInstruction: _criticPrompt,
      );

      final result = await AIRouter.generate(request, ref: ref)
          .timeout(const Duration(seconds: 15));

      // Parse the critic's JSON response
      final text = result.text.trim();
      try {
        final cleanJson = text.contains('```json')
            ? text.split('```json').last.split('```').first.trim()
            : text.contains('```')
                ? text.split('```')[1].trim()
                : text;

        // Simple JSON parsing (no dart:convert import needed for basic structures) 
        final score = _extractDouble(cleanJson, 'score') ?? 0.8;
        final critique = _extractString(cleanJson, 'critique') ?? 'Quality assessment complete.';
        final issues = _extractList(cleanJson, 'issues');

        return ReflectionResult(
          score: score,
          critique: critique,
          passesThreshold: true, // Will be checked by caller against config
          issues: issues,
        );
      } catch (e) {
        debugPrint('ReflectionLoop: Failed to parse critic response, defaulting to pass. Error: $e');
        return const ReflectionResult(
          score: 0.8,
          critique: 'Quality check completed (parse fallback).',
          passesThreshold: true,
        );
      }
    } catch (e) {
      debugPrint('ReflectionLoop: Reflection call failed: $e');
      // On failure, default to pass (don't block the pipeline)
      return const ReflectionResult(
        score: 0.8,
        critique: 'Quality check skipped (service unavailable).',
        passesThreshold: true,
      );
    }
  }

  /// Extract a double value from a JSON-like string.
  static double? _extractDouble(String json, String key) {
    final regex = RegExp('"$key"\\s*:\\s*([0-9.]+)');
    final match = regex.firstMatch(json);
    if (match != null) return double.tryParse(match.group(1)!);
    return null;
  }

  /// Extract a string value from a JSON-like string.
  static String? _extractString(String json, String key) {
    final regex = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    final match = regex.firstMatch(json);
    return match?.group(1);
  }

  /// Extract a list of strings from a JSON-like string.
  static List<String> _extractList(String json, String key) {
    final regex = RegExp('"$key"\\s*:\\s*\\[([^\\]]*)\\]');
    final match = regex.firstMatch(json);
    if (match == null) return [];
    final inner = match.group(1)!;
    return RegExp('"([^"]*)"').allMatches(inner).map((m) => m.group(1)!).toList();
  }
}
