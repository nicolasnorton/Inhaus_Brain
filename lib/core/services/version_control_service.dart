import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/version_control_models.dart';
import 'package:uuid/uuid.dart';

final versionControlProvider = StateNotifierProvider<VersionControlNotifier, List<WorkflowCommit>>((ref) {
  return VersionControlNotifier();
});

class VersionControlNotifier extends StateNotifier<List<WorkflowCommit>> {
  VersionControlNotifier() : super([]);

  void commit(String appId, String message, String author, Map<String, dynamic> dsl) {
    final parent = state.where((c) => c.appId == appId).firstOrNull;
    
    final newCommit = WorkflowCommit(
      id: const Uuid().v4(),
      appId: appId,
      message: message,
      author: author,
      timestamp: DateTime.now(),
      dslSnapshot: dsl,
      parentId: parent?.id,
    );
    
    state = [newCommit, ...state];
  }

  List<WorkflowCommit> getHistory(String appId) {
    return state.where((c) => c.appId == appId).toList();
  }

  void rollback(String commitId) {
    // In a real app, this would update the current workflow DSL
    // For now, we just identified it.
  }
  
  void clearHistory(String appId) {
    state = state.where((c) => c.appId != appId).toList();
  }
}
