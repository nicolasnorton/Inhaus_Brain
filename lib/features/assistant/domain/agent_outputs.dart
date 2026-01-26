import 'dart:convert';

/// Base class for all typed agent outputs
abstract class AgentOutput {
  Map<String, dynamic> toJson();
}

/// Represents the structured output from the Strategist Agent
class StrategyOutput implements AgentOutput {
  final String coreConcept;
  final List<String> targetAudience;
  final List<String> keyChannels;
  final bool isReadyForCopy;
  final String? reasoning;

  StrategyOutput({
    required this.coreConcept,
    required this.targetAudience,
    required this.keyChannels,
    required this.isReadyForCopy,
    this.reasoning,
  });

  factory StrategyOutput.fromJson(Map<String, dynamic> json) {
    return StrategyOutput(
      coreConcept: json['coreConcept'] ?? '',
      targetAudience: List<String>.from(json['targetAudience'] ?? []),
      keyChannels: List<String>.from(json['keyChannels'] ?? []),
      isReadyForCopy: json['isReadyForCopy'] ?? false,
      reasoning: json['reasoning'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'coreConcept': coreConcept,
      'targetAudience': targetAudience,
      'keyChannels': keyChannels,
      'isReadyForCopy': isReadyForCopy,
      'reasoning': reasoning,
    };
  }

  static const String schemaDescription = '''
  {
    "type": "object",
    "properties": {
      "coreConcept": {"type": "string", "description": "The main strategic angle or big idea."},
      "targetAudience": {"type": "array", "items": {"type": "string"}, "description": "List of specific audience segments."},
      "keyChannels": {"type": "array", "items": {"type": "string"}, "description": "Proposed marketing channels."},
      "isReadyForCopy": {"type": "boolean", "description": "Set to true ONLY if the strategy is solid enough to move to copywriting."},
      "reasoning": {"type": "string", "description": "Optional explanation of the strategy."}
    },
    "required": ["coreConcept", "targetAudience", "keyChannels", "isReadyForCopy"]
  }
  ''';
}

/// Represents the structured output from the Research Agent (Trend Scout)
class ResearchOutput implements AgentOutput {
  final String keyInsight;
  final List<String> sources;
  final double confidenceScore;
  final bool needsMoreData;

  ResearchOutput({
    required this.keyInsight,
    required this.sources,
    required this.confidenceScore,
    required this.needsMoreData,
  });

  factory ResearchOutput.fromJson(Map<String, dynamic> json) {
    return ResearchOutput(
      keyInsight: json['keyInsight'] ?? '',
      sources: List<String>.from(json['sources'] ?? []),
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      needsMoreData: json['needsMoreData'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'keyInsight': keyInsight,
      'sources': sources,
      'confidenceScore': confidenceScore,
      'needsMoreData': needsMoreData,
    };
  }
}
