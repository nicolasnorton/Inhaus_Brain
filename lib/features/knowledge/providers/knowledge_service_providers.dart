import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/knowledge_api_service.dart';
import '../services/knowledge_ingestion_service.dart';
import '../services/knowledge_librarian_service.dart';
import '../../../core/auth/auth_service.dart';

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
  final authService = ref.watch(authServiceProvider);
  
  return KnowledgeApiService(
    baseUrl: 'https://api.inhaus.ai',
    tokenProvider: () async {
      return authService.currentUser?.getIdToken();
    },
  );
});
