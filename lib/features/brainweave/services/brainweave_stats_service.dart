import 'package:flutter/foundation.dart';
import 'brainweave_mcp_client.dart';

/// Service for fetching BrainWeave graph stats (node/edge counts, daily cost).
class BrainWeaveStatsService {
  final BrainWeaveMcpClient _mcp = BrainWeaveMcpClient();

  /// Returns stats map: {node_count, edge_count, daily_interactions, est_cost_usd}
  Future<Map<String, dynamic>> getStats() async {
    try {
      return await _mcp.getStats();
    } catch (e) {
      debugPrint('BrainWeaveStatsService: Failed to fetch stats: $e');
      return {
        'node_count': 0,
        'edge_count': 0,
        'daily_interactions': 0,
        'est_cost_usd': 0.0,
      };
    }
  }
}
