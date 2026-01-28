import 'dart:async';
import 'package:flutter/foundation.dart';

class BenchmarkHelper {
  static Future<Map<String, dynamic>> runLatencyTest(
      String label, Future<dynamic> Function() task) async {
    final stopwatch = Stopwatch()..start();
    try {
      await task();
      stopwatch.stop();
      return {
        'label': label,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'success': true
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'label': label,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'success': false,
        'error': e.toString()
      };
    }
  }

  static void printReport(List<Map<String, dynamic>> results) {
    debugPrint('\n--- PERFORMANCE BENCHMARK REPORT ---');
    for (var r in results) {
      final status = r['success'] ? '✅' : '❌';
      debugPrint('$status ${r['label']}: ${r['duration_ms']}ms');
    }
    debugPrint('-----------------------------------\n');
  }
}
