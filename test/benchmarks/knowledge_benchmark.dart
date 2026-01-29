import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../lib/features/knowledge/services/knowledge_api_service.dart';

class KnowledgeBenchmark {
  final KnowledgeApiService _service;

  KnowledgeBenchmark(this._service);

  Future<void> runBenchmarks() async {
    debugPrint('--- Knowledge Retrieval Benchmarks ---');
    
    final queries = [
      'What is Inhaus Brain?',
      'How to create a campaign?',
      'Tell me about the Knowledge Module.',
    ];

    for (var query in queries) {
      final stopwatch = Stopwatch()..start();
      
      await _service.retrieveChunks(
        datasetId: 'benchmark-dataset',
        query: query,
        retrievalModel: {'top_k': 3},
      );
      
      stopwatch.stop();
      debugPrint('Query: "$query" -> Latency: ${stopwatch.elapsedMilliseconds}ms');
    }
    
    debugPrint('--- Benchmark Complete ---');
  }
}
