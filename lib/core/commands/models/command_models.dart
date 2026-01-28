import 'package:flutter/material.dart';

/// Command category
enum CommandCategory {
  navigation,
  actions,
  view,
  tools,
  help;

  String get displayName {
    switch (this) {
      case CommandCategory.navigation:
        return 'Navigation';
      case CommandCategory.actions:
        return 'Actions';
      case CommandCategory.view:
        return 'View';
      case CommandCategory.tools:
        return 'Tools';
      case CommandCategory.help:
        return 'Help';
    }
  }

  String get icon {
    switch (this) {
      case CommandCategory.navigation:
        return '🧭';
      case CommandCategory.actions:
        return '⚡';
      case CommandCategory.view:
        return '👁️';
      case CommandCategory.tools:
        return '🔧';
      case CommandCategory.help:
        return '❓';
    }
  }
}

/// Command model
class Command {
  final String id;
  final String name;
  final String description;
  final CommandCategory category;
  final String? icon;
  final String? shortcut;
  final VoidCallback action;
  final List<String> keywords;

  const Command({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.action,
    this.icon,
    this.shortcut,
    this.keywords = const [],
  });

  /// Calculate fuzzy match score
  int matchScore(String query) {
    if (query.isEmpty) return 0;
    
    final lowerQuery = query.toLowerCase();
    final lowerName = name.toLowerCase();
    final lowerDesc = description.toLowerCase();
    
    int score = 0;
    
    // Exact match
    if (lowerName == lowerQuery) score += 100;
    if (lowerDesc == lowerQuery) score += 50;
    
    // Starts with
    if (lowerName.startsWith(lowerQuery)) score += 75;
    if (lowerDesc.startsWith(lowerQuery)) score += 25;
    
    // Contains
    if (lowerName.contains(lowerQuery)) score += 50;
    if (lowerDesc.contains(lowerQuery)) score += 10;
    
    // Keyword match
    for (final keyword in keywords) {
      if (keyword.toLowerCase().contains(lowerQuery)) {
        score += 30;
      }
    }
    
    // Fuzzy match (consecutive characters)
    int fuzzyScore = 0;
    int queryIndex = 0;
    for (int i = 0; i < lowerName.length && queryIndex < lowerQuery.length; i++) {
      if (lowerName[i] == lowerQuery[queryIndex]) {
        fuzzyScore++;
        queryIndex++;
      }
    }
    if (queryIndex == lowerQuery.length) {
      score += fuzzyScore * 5;
    }
    
    return score;
  }
}

/// Command history entry
class CommandHistoryEntry {
  final String commandId;
  final DateTime executedAt;

  const CommandHistoryEntry({
    required this.commandId,
    required this.executedAt,
  });

  Map<String, dynamic> toJson() => {
        'command_id': commandId,
        'executed_at': executedAt.toIso8601String(),
      };

  factory CommandHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CommandHistoryEntry(
      commandId: json['command_id'] as String,
      executedAt: DateTime.parse(json['executed_at'] as String),
    );
  }
}
