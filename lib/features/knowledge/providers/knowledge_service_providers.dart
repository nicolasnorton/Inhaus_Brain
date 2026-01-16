import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/knowledge_api_service.dart';
import '../services/knowledge_ingestion_service.dart';
import '../services/knowledge_librarian_service.dart';

final knowledgeIngestionServiceProvider = Provider<KnowledgeIngestionService>((ref) {
  final api = ref.watch(knowledgeApiServiceProvider);
  return KnowledgeIngestionService(api);
});

final knowledgeLibrarianServiceProvider = Provider<KnowledgeLibrarianService>((ref) {
  final api = ref.watch(knowledgeApiServiceProvider);
  return KnowledgeLibrarianService(api);
});

// Mocking the API provider for now as it might be defined elsewhere
final knowledgeApiServiceProvider = Provider<KnowledgeApiService>((ref) {
  return KnowledgeApiService(
    baseUrl: 'https://api.inhaus.ai', // Placeholder
    apiKey: 'sk-inhaus-brain-key', // Placeholder
  );
});
