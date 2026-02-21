/// FunctionGemma Router — lightweight intent classification.
///
/// Uses FunctionGemma (270M) via the Python proxy to classify user
/// intents and determine which agent + tools to invoke. This replaces
/// heavy Gemini-based router calls for simple intents, saving ~80% cost.
///
/// Staging-gated via [AppConfig.enableGemma].
library;

import 'dart:convert';
import 'package:logger/logger.dart';
import '../../config/app_environment.dart';
import 'ai_generation_request.dart';
import 'gemma_strategy.dart';
import '../../tokens/llm_provider.dart';

/// Result of intent classification.
class AgentDispatch {
  final String agentName;
  final List<String> suggestedTools;
  final double confidence;
  final String rawClassification;

  const AgentDispatch({
    required this.agentName,
    this.suggestedTools = const [],
    this.confidence = 1.0,
    this.rawClassification = '',
  });
}

class FunctionGemmaRouter {
  static final _logger = Logger();
  static final _gemma = GemmaStrategy();

  /// Agents that FunctionGemma can route to.
  static const _validAgents = {
    'research', 'creative', 'copywriter', 'developer', 'orchestrator',
    'trend_scout', 'account_director', 'strategist', 'seo', 'aeo',
    'media_buyer', 'performance_analyst', 'design', 'video', 'proposal',
    'data_analyst', 'service', 'crm', 'csuite', 'brian',
  };

  /// Classify user intent and return which agent to dispatch to.
  ///
  /// Uses FunctionGemma (~50ms latency). Falls back to a default
  /// agent if classification fails or Gemma is disabled.
  static Future<AgentDispatch> classifyIntent(String userMessage) async {
    if (!AppConfig.enableGemma) {
      _logger.i('FunctionGemma: Disabled, returning default dispatch');
      return _defaultDispatch(userMessage);
    }

    try {
      final request = AIGenerationRequest(
        prompt: '''Classify the following user message into exactly one agent.
Valid agents: ${_validAgents.join(', ')}

Respond with JSON only: {"agent": "<name>", "tools": ["<tool1>"], "confidence": 0.95}

User message: $userMessage''',
        config: AIModelConfig(
          modelId: 'functiongemma-270m',
          provider: AIProvider.gemma,

          // displayName: 'FunctionGemma', // Removed from config
          temperature: 0.1,
          maxTokens: 128,
          responseMimeType: 'application/json',
        ),
        outputMode: 'json',
      );

      final result = await _gemma.generate(request);
      final parsed = jsonDecode(result.text) as Map<String, dynamic>;

      final agent = parsed['agent'] as String? ?? 'brian';
      final tools = (parsed['tools'] as List?)?.cast<String>() ?? [];
      final confidence = (parsed['confidence'] as num?)?.toDouble() ?? 0.8;

      if (!_validAgents.contains(agent)) {
        _logger.w('FunctionGemma: Unknown agent "$agent", defaulting to brian');
        return _defaultDispatch(userMessage);
      }

      return AgentDispatch(
        agentName: agent,
        suggestedTools: tools,
        confidence: confidence,
        rawClassification: result.text,
      );
    } catch (e) {
      _logger.w('FunctionGemma: Classification failed: $e');
      return _defaultDispatch(userMessage);
    }
  }

  /// Default dispatch when Gemma is unavailable.
  static AgentDispatch _defaultDispatch(String message) {
    // Simple keyword-based fallback
    final lower = message.toLowerCase();
    if (lower.contains('research') || lower.contains('find') || lower.contains('search')) {
      return const AgentDispatch(agentName: 'research', confidence: 0.5);
    }
    if (lower.contains('write') || lower.contains('copy') || lower.contains('content')) {
      return const AgentDispatch(agentName: 'copywriter', confidence: 0.5);
    }
    if (lower.contains('design') || lower.contains('visual') || lower.contains('image')) {
      return const AgentDispatch(agentName: 'creative', confidence: 0.5);
    }
    if (lower.contains('video') || lower.contains('animate')) {
      return const AgentDispatch(agentName: 'video', confidence: 0.5);
    }
    if (lower.contains('proposal') || lower.contains('pitch')) {
      return const AgentDispatch(agentName: 'proposal', confidence: 0.5);
    }
    return const AgentDispatch(agentName: 'brian', confidence: 0.3);
  }
}
