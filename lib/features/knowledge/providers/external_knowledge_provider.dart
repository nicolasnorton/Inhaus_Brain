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
