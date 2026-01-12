import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/external_knowledge_models.dart';
import '../services/external_knowledge_service.dart';

/// Provider for ExternalKnowledgeService
final externalKnowledgeServiceProvider = Provider<ExternalKnowledgeService>((ref) {
  return ExternalKnowledgeService();
});

/// Provider for list of configured external connections
final externalConnectionsProvider =
    StateNotifierProvider<ExternalConnectionsNotifier, List<ExternalConnection>>((ref) {
  return ExternalConnectionsNotifier();
});

/// Provider for currently selected connection ID
final selectedConnectionProvider = StateProvider<String?>((ref) => null);

/// Provider for query results cache
final queryResultsProvider = StateProvider<ExternalKnowledgeResponse?>((ref) => null);

/// Provider for connection status map
final connectionStatusProvider = StateProvider<Map<String, ConnectionStatus>>((ref) => {});

/// State notifier for managing external connections
class ExternalConnectionsNotifier extends StateNotifier<List<ExternalConnection>> {
  ExternalConnectionsNotifier() : super([]);

  /// Add a new connection
  void addConnection(ExternalConnection connection) {
    state = [...state, connection];
  }

  /// Update an existing connection
  void updateConnection(ExternalConnection connection) {
    state = [
      for (final conn in state)
        if (conn.id == connection.id) connection else conn,
    ];
  }

  /// Remove a connection
  void removeConnection(String id) {
    state = state.where((conn) => conn.id != id).toList();
  }

  /// Update connection status
  void updateConnectionStatus(String id, ConnectionStatus status, {DateTime? lastSync}) {
    state = [
      for (final conn in state)
        if (conn.id == id)
          conn.copyWith(status: status, lastSync: lastSync ?? conn.lastSync)
        else
          conn,
    ];
  }

  /// Get connection by ID
  ExternalConnection? getConnection(String id) {
    try {
      return state.firstWhere((conn) => conn.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Test a connection
  Future<bool> testConnection(WidgetRef ref, String connectionId) async {
    final connection = getConnection(connectionId);
    if (connection == null) return false;

    updateConnectionStatus(connectionId, ConnectionStatus.pending);
    
    final service = ref.read(externalKnowledgeServiceProvider);
    final success = await service.testConnection(connection.endpoint, connection.apiKey);
    
    if (success) {
      updateConnectionStatus(connectionId, ConnectionStatus.active, lastSync: DateTime.now());
    } else {
      updateConnectionStatus(connectionId, ConnectionStatus.error);
    }
    
    return success;
  }

  /// Perform a knowledge query
  Future<void> queryKnowledge(WidgetRef ref, String connectionId, String query) async {
    final connection = getConnection(connectionId);
    if (connection == null) return;

    final service = ref.read(externalKnowledgeServiceProvider);
    
    try {
      final request = ExternalKnowledgeRequest(
        query: query,
        knowledgeId: connection.knowledgeId!,
        retrievalSetting: const RetrievalSetting(topK: 5, scoreThreshold: 0.5),
      );
      
      final response = await service.queryKnowledge(
        request: request,
        endpoint: connection.endpoint,
        apiKey: connection.apiKey,
      );
      
      ref.read(queryResultsProvider.notifier).state = response;
    } catch (e) {
      // In a real app, we'd handle this with a specific error state
      ref.read(queryResultsProvider.notifier).state = null;
      updateConnectionStatus(connectionId, ConnectionStatus.error);
    }
  }

  /// Create a new LlamaCloud connection
  ExternalConnection createLlamaCloudConnection({
    required String apiKey,
    required String pipelineId,
    required String region,
  }) {
    final endpoint = ExternalKnowledgeService.generateLlamaCloudEndpoint(region);
    return ExternalConnection(
      id: const Uuid().v4(),
      name: 'LlamaCloud - $pipelineId',
      endpoint: endpoint,
      apiKey: apiKey,
      status: ConnectionStatus.pending,
      knowledgeId: pipelineId,
    );
  }

  /// Create a custom API connection
  ExternalConnection createCustomConnection({
    required String name,
    required String endpoint,
    String? apiKey,
    String? knowledgeId,
  }) {
    return ExternalConnection(
      id: const Uuid().v4(),
      name: name,
      endpoint: endpoint,
      apiKey: apiKey,
      status: ConnectionStatus.pending,
      knowledgeId: knowledgeId,
    );
  }
}
