import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/knowledge_source.dart';

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
