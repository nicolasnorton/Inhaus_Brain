
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ErrorRecoveryService {
  final _logger = Logger();

  Future<T> runWithRecovery<T>({
    required Future<T> Function() operation,
    required String operationName,
    T? fallbackValue,
    int retries = 2,
  }) async {
    int attempts = 0;
    while (attempts <= retries) {
      try {
        return await operation();
      } catch (e, stack) {
        attempts++;
        _logger.w('[Recovery] $operationName failed (Attempt $attempts/$retries). Error: $e');
        
        if (attempts > retries) {
           _logger.e('[Recovery] $operationName exhausted retries. Using fallback.');
           if (fallbackValue != null) return fallbackValue;
           rethrow;
        }
        
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
    throw Exception("Unreachable");
  }

  static String getFriendlyErrorMessage(dynamic error) {
    final s = error.toString().toLowerCase();
    if (s.contains('timeout') || s.contains('deadline')) {
      return "The AI is taking longer than expected. We're retrying on a faster connection...";
    }
    if (s.contains('network') || s.contains('socket') || s.contains('offline')) {
      return "Network connection unstable. Using cached data where possible.";
    }
    if (s.contains('429') || s.contains('quota')) {
      return "High traffic volume. Cooling down for a moment...";
    }
    if (s.contains('403') || s.contains('permission')) {
      return "Permissions issue. Please verify your authentication.";
    }
    return "Something unexpected happened. Our engineers have been notified.";
  }
}
