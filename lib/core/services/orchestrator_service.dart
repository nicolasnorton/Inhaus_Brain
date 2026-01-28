import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrchestratorService {
  final _logger = Logger();

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
  Future<String> auditResponse(String originalResponse, String senderName) async {
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

    return processed;
  }
}

final orchestratorProvider = Provider<OrchestratorService>((ref) => OrchestratorService());
