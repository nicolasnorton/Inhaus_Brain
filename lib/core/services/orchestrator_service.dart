import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:inhaus_brain/core/services/output_polish_service.dart';
import 'package:inhaus_brain/core/services/multimodal_scorer.dart';

class OrchestratorService {
  final _logger = Logger();
  final Ref _ref;

  OrchestratorService(this._ref);

  /// Quality Gate: Confidence Threshold
  /// Returns NULL if passable, or a Warning String if below threshold.
  String? checkConfidence(double confidence, {double threshold = 0.7}) {
    if (confidence < threshold) {
      _logger.w('[Quality Gate] Low Confidence detected: $confidence (Threshold: $threshold)');
      // In a real system, we might auto-retry here.
      return "[FLAGGED: Low Confidence ($confidence)]";
    }
    return null;
  }

  /// Multimodal Quality Check
  /// Checks if the generated asset meets the strict quality thresholds.
  String? checkMultimodalQuality(double score, String modality) {
    final rejectionMsg = MultimodalScorer.getRejectionMessage(score, modality);
    if (rejectionMsg != null) {
      _logger.w('[Quality Gate] Multimodal rejection for $modality (Score: $score)');
      return rejectionMsg;
    }
    return null;
  }

  /// Context Compression (Lightweight)
  /// Used before delegating long histories to specialist agents.
  String compressContext(String fullContext) {
    // If context is manageable, return as is.
    if (fullContext.length < 4000) return fullContext;

    _logger.i('[Orchestrator] Compressing context (Original: ${fullContext.length} chars)');
    
    // Strategy: Keep strict System Prompt (start) and recent turns (end).
    // Collapse the middle.
    final int retrainChars = 1500;
    if (fullContext.length <= retrainChars * 2) return fullContext;

    final start = fullContext.substring(0, retrainChars);
    final end = fullContext.substring(fullContext.length - retrainChars);
    
    return "$start\n\n[...Orchestrator Note: Middle context compressed to save tokens...]\n\n$end";
  }

  /// PII Redaction: Regex for emails and phone numbers
  String _redactPII(String text) {
    String redacted = text;
    // Email regex
    final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
    redacted = redacted.replaceAll(emailRegex, '[EMAIL_REDACTED]');

    // Simple phone regex (International & Local formats)
    final phoneRegex = RegExp(r'(\+?\d{1,3}[- ]?)?\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}');
    redacted = redacted.replaceAll(phoneRegex, '[PHONE_REDACTED]');

    return redacted;
  }

  /// Cultural Sensitivity: Check for forbidden/sensitive terms in Ecuador/LatAm context
  String _applyCulturalFilters(String text) {
    final sensitiveTerms = {
      'guayaquil vs quito': '[SENSITIVITY: Regionalism avoided]',
      'pelucon': '[SENSITIVITY: Classist term removed]',
      // Add more as defined by agency guidelines
    };

    String filtered = text;
    sensitiveTerms.forEach((key, value) {
      if (filtered.toLowerCase().contains(key)) {
        filtered = filtered.replaceAll(RegExp(key, caseSensitive: false), value);
      }
    });
    return filtered;
  }

  /// Basic Prompt Injection Detection
  bool _isPotentialInjection(String text) {
    final lower = text.toLowerCase();
    final indicators = [
      'ignore all previous instructions',
      'system prompt',
      'you are now a',
      'forget what you were told',
      'disregard safety guidelines'
    ];
    return indicators.any((indicator) => lower.contains(indicator));
  }

  /// Determines if a message requires auditing.
  bool shouldAudit(String sender) {
    return sender.contains('Agent') || sender == 'User';
  }

  /// Audits the response or input.
  /// [confidence] - Optional score (0.0 - 1.0) from the LLM.
  Future<String> auditResponse(String originalResponse, String senderName, {double? confidence}) async {
    // 0. Quality Gate (Confidence Check)
    if (confidence != null) {
      final flag = checkConfidence(confidence);
      if (flag != null) {
        // We append the flag so the UI/User knows.
        // Ideally, we'd retry, but for now we tag it.
        return "$flag $originalResponse";
      }
    }

    // 1. Check for Prompt Injection if it's from User
    if (senderName == 'User' && _isPotentialInjection(originalResponse)) {
      _logger.w('[Allocated Security] PROMPT INJECTION BLOCKED from User');
      return "[SECURITY INTERVENTION]: Potential prompt injection detected. Request blocked.";
    }

    // 2. Apply PII Redaction
    String processed = _redactPII(originalResponse);
    if (processed != originalResponse) {
      _logger.i('[Orchestrator] PII Redacted from $senderName');
    }

    // 3. Apply Cultural Sensitivity Filters
    String culturallyFiltered = _applyCulturalFilters(processed);
    if (culturallyFiltered != processed) {
      _logger.w('[Orchestrator] Cultural Sensitivity Filter Triggered');
    }
    processed = culturallyFiltered;

    // 4. Specific Forbidden Terms (Client/Brand)
    if (processed.toLowerCase().contains('competitor_brand_x')) {
      _logger.w('[Orchestrator] Competitor Brand Redacted');
      processed = processed.replaceAll(RegExp('competitor_brand_x', caseSensitive: false), '[BRAND_REDACTED]');
    }

    // 5. Automated Polish (Text & Reasoning Agent)
    // Only polish Agent outputs that are client-facing
    if (senderName.contains('Agent') && !originalResponse.contains('```json')) {
       // Heuristic: Don't polish raw JSON or tool calls (e.g. SEO, AEO, Strategy JSONs)
       // SEO Agent and AEO Agent outputs that are substantial should be polished if not raw JSON.
       // Polish only if text is substantial
       if (processed.length > 50) {
          try {
             _logger.i('[Orchestrator] Polishing output from $senderName...');
             final polished = await _ref.read(outputPolishServiceProvider).polishText(processed);
             processed = polished; // Accept polish
          } catch (e) {
             _logger.w('Polish failed, keeping original: $e');
          }
       }
    }

    return processed;
  }
}

final orchestratorProvider = Provider<OrchestratorService>((ref) => OrchestratorService(ref));
