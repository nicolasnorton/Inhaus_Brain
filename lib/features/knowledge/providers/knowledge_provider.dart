import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/knowledge_source.dart';
import '../models/knowledge_api_models.dart';
import '../services/knowledge_api_service.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/services/vertex_ai_service.dart';
import '../../../core/auth/secret_vault_service.dart';
import '../../../core/services/semantic_cache_service.dart';

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

  void initDemoData() {
    state = [
      KnowledgeSource(
        id: 'ks-services',
        title: 'Agency Services Catalog 2024',
        content: """
        /knowledge/services
        Service: AI Social Media Suite
        Description: High-frequency social content generated using Veo and Gemini.
        Pricing: \$2,500 / month
        
        Service: Strategic Research Deep Dive
        Description: Comprehensive market and competitive analysis using Google Search grounding.
        Pricing: \$1,500 / report
        
        Service: Brand Identity Refresh
        Description: Modern visual concepts using Imagen 3 and Design Agents.
        Pricing: \$3,000 / project
        """,
        type: KnowledgeSourceType.text,
        createdAt: DateTime.now(),
      )
    ];
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
  final cache = ref.watch(semanticCacheServiceProvider);
  return KnowledgeApiService(
    vertexService: vertex,
    vault: vault,
    cache: cache,
    tokenProvider: () async {
      // 1. Try to get a fresh token from Google account (refreshes if needed)
      final freshToken = await authService.getFreshVertexToken();
      if (freshToken != null) return freshToken;

      // 2. Try Vertex Key from Vault
      final vertexKey = await vault.getVertexKey();
      if (vertexKey != null && vertexKey.isNotEmpty) return vertexKey;

      // 3. Fallback to Gemini Key
      final geminiKey = await vault.getGeminiKey();
      if (geminiKey != null && geminiKey.isNotEmpty) return geminiKey;
      
      // 4. Final fallback to user ID token (Firebase)
      return await authService.currentUser?.getIdToken();
    },
  );
});

final selectedDatasetIdProvider = StateProvider<String?>((ref) => null);

final knowledgeViewProvider = StateProvider<String>((ref) => 'content');

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
