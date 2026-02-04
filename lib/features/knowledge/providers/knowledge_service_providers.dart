import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/knowledge_ingestion_service.dart';
import '../services/knowledge_librarian_service.dart';
import 'knowledge_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/services/google_drive_service.dart';

final knowledgeIngestionServiceProvider = Provider<KnowledgeIngestionService>((ref) {
  final api = ref.watch(knowledgeApiServiceProvider);
  return KnowledgeIngestionService(api);
});

final knowledgeLibrarianServiceProvider = Provider<KnowledgeLibrarianService>((ref) {
  final api = ref.watch(knowledgeApiServiceProvider);
  return KnowledgeLibrarianService(api);
});

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  final auth = ref.watch(authServiceProvider);
  return GoogleDriveService(auth);
});
