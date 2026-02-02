import 'package:flutter/foundation.dart';

class ErrorService {
  static void logError(Object error, StackTrace? stackTrace, {String? context}) {
    debugPrint('Error in $context: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
