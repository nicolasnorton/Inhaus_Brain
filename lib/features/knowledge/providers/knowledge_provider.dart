import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/knowledge_source.dart';
import '../models/knowledge_api_models.dart';
import '../services/knowledge_api_service.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/services/vertex_ai_service.dart';
import '../../../core/auth/secret_vault_service.dart';

// --- Legacy Source Management ---

class KnowledgeNotifier extends StateNotifier<List<KnowledgeSource>> {
  KnowledgeNotifier() : super([]);

  void addSource(KnowledgeSource source) {
    state = [...state, source];
  }

  void removeSource(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  void updateSource(KnowledgeSource updatedSource) {
    state = [
      for (final source in state)
        if (source.id == updatedSource.id) updatedSource else source,
    ];
  }

  void clearSources() {
    state = [];
  }
}

final knowledgeProvider = StateNotifierProvider<KnowledgeNotifier, List<KnowledgeSource>>((ref) {
  return KnowledgeNotifier();
});

// --- INHAUS BRAIN-style Dataset & Document Management ---

final vertexApiServiceProvider = Provider<VertexApiService>((ref) => VertexApiService());

final knowledgeApiServiceProvider = Provider<KnowledgeApiService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final vault = ref.watch(secretVaultProvider);
  final vertex = ref.watch(vertexApiServiceProvider);
  
  return KnowledgeApiService(
    vertexService: vertex,
    tokenProvider: () async {
      // 1. Try Dify Key (serving as Vertex/Generic key slot if needed)
      // Or 1.5 Try Vertex API Key specifically if added
      // 2. Fallback to Dify Key logic (reused for MVP to pass ANY key)
      final difyKey = await vault.getDifyKey();
      if (difyKey != null && difyKey.isNotEmpty) return difyKey;

      // 3. Fallback to Gemini Key?
      final geminiKey = await vault.getGeminiKey();
      if (geminiKey != null && geminiKey.isNotEmpty) return geminiKey;
      
      // 4. Fallback to user token (Access Token for Cloud)
      return (await authService.currentUser)?.getIdToken();
    },
  );
});

final selectedDatasetIdProvider = StateProvider<String?>((ref) => null);

final knowledgeBasesProvider = FutureProvider.autoDispose<List<KnowledgeBase>>((ref) async {
  final service = ref.watch(knowledgeApiServiceProvider);
  return service.listKnowledgeBases();
});

final documentsProvider = FutureProvider.autoDispose.family<List<KnowledgeDocument>, String>((ref, datasetId) async {
  final service = ref.watch(knowledgeApiServiceProvider);
  return service.listDocuments(datasetId: datasetId);
});

final documentChunksProvider = FutureProvider.family<List<DocumentChunk>, ({String datasetId, String documentId})>((ref, arg) async {
  final service = ref.watch(knowledgeApiServiceProvider);
  return service.getChunks(datasetId: arg.datasetId, documentId: arg.documentId);
});
