import 'package:flutter/material.dart';

/// Log levels for execution logs
enum LogLevel {
  info,
  warning,
  error;

  String get displayName {
    switch (this) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  Color get color {
    switch (this) {
      case LogLevel.info:
        return Colors.blueAccent;
      case LogLevel.warning:
        return Colors.orangeAccent;
      case LogLevel.error:
        return Colors.redAccent;
    }
  }
}

enum LogScope {
  user,
  system
}

/// A single execution log entry
class LogEntry {
  final String id;
  final String appId; // If tied to an app
  final String? userId; // For user logs
  final LogScope scope; // System or User
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? traceId;
  final Map<String, dynamic>? metadata;
  final Annotation? annotation;

  const LogEntry({
    required this.id,
    required this.appId,
    this.userId,
    this.scope = LogScope.user,
    required this.timestamp,
    required this.level,
    required this.message,
    this.traceId,
    this.metadata,
    this.annotation,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] as String,
      appId: json['app_id'] as String,
      userId: json['user_id'] as String?,
      scope: json['scope'] != null 
          ? LogScope.values.firstWhere((e) => e.name == json['scope']) 
          : LogScope.user,
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: LogLevel.values.byName(json['level'] as String),
      message: json['message'] as String,
      traceId: json['trace_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      annotation: json['annotation'] != null 
          ? Annotation.fromJson(json['annotation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'app_id': appId,
    'user_id': userId,
    'scope': scope.name,
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    'trace_id': traceId,
    'metadata': metadata,
    'annotation': annotation?.toJson(),
  };
}

/// Feedback annotation for a log entry
class Annotation {
  final String id;
  final String logId;
  final int rating; // 1-5
  final String? comment;
  final String? suggestedCorrection;
  final DateTime createdAt;

  const Annotation({
    required this.id,
    required this.logId,
    required this.rating,
    this.comment,
    this.suggestedCorrection,
    required this.createdAt,
  });

  factory Annotation.fromJson(Map<String, dynamic> json) {
    return Annotation(
      id: json['id'] as String,
      logId: json['log_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      suggestedCorrection: json['suggested_correction'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'log_id': logId,
    'rating': rating,
    'comment': comment,
    'suggested_correction': suggestedCorrection,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Summary metrics for an app (INHAUS BRAIN-style)
class MetricSummary {
  final int totalMessages;
  final int activeUsers;
  final double avgInteractions;
  final int totalTokens;
  final double estimatedCost;

  const MetricSummary({
    required this.totalMessages,
    required this.activeUsers,
    required this.avgInteractions,
    required this.totalTokens,
    required this.estimatedCost,
  });

  factory MetricSummary.fromJson(Map<String, dynamic> json) {
    return MetricSummary(
      totalMessages: json['total_messages'] as int,
      activeUsers: json['active_users'] as int,
      avgInteractions: (json['avg_interactions'] as num).toDouble(),
      totalTokens: json['total_tokens'] as int,
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
    );
  }
}

/// Data point for time-series charts
class MetricDataPoint {
  final DateTime timestamp;
  final double value;

  const MetricDataPoint({
    required this.timestamp,
    required this.value,
  });
}
