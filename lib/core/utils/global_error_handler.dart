import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Global Error Handler for Flutter
/// 
/// Captures all uncaught errors and reports them to monitoring services.
class GlobalErrorHandler {
  static void initialize() {
    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack, details.context);
    };

    // Capture async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack, null);
      return true;
    };
  }

  static void _logError(dynamic error, StackTrace? stack, DiagnosticsNode? context) {
    debugPrint('🚨 Global Error Caught:');
    debugPrint('Error: $error');
    debugPrint('Stack: $stack');
    if (context != null) debugPrint('Context: ${context.toDescription()}');

    // TODO: Send to Cloud Logging / Sentry / Firebase Crashlytics
    // Example:
    // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    
    // For now, we just log to console in development
  }

  /// Manual error reporting for try-catch blocks
  static void reportError(dynamic error, StackTrace? stack, {String? context}) {
    _logError(error, stack, context != null ? DiagnosticsProperty('context', context) : null);
  }
}
