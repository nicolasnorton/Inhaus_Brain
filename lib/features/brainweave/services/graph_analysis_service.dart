import '../models/brainweave_node.dart';

/// Client-side graph analysis service implementing arscontexta's key operations.
/// Works purely on in-memory node/edge data — no Firestore calls needed.
class GraphAnalysisService {
  /// Adjacency list: nodeId → set of connected nodeIds
  final Map<String, Set<String>> _adjacency;
  final Map<String, GraphNodeInfo> _nodeInfo;

  GraphAnalysisService._(this._adjacency, this._nodeInfo);

  factory GraphAnalysisService.fromData({
    required List<GraphNodeInfo> nodes,
    required List<GraphEdgeInfo> edges,
  }) {
    final adj = <String, Set<String>>{};
    final nodeMap = <String, GraphNodeInfo>{};

    for (final n in nodes) {
      adj.putIfAbsent(n.id, () => {});
      nodeMap[n.id] = n;
    }

    for (final e in edges) {
      adj.putIfAbsent(e.sourceId, () => {}).add(e.targetId);
      adj.putIfAbsent(e.targetId, () => {}).add(e.sourceId);
    }

    return GraphAnalysisService._(adj, nodeMap);
  }

  // ── Triangles (Synthesis Opportunities) ──────────────────────────────────

  /// Find open triadic closures: A→B, A→C but B↛C.
  /// These are synthesis opportunities — pairs that share a common parent
  /// but aren't directly connected.
  List<TriangleResult> findTriangles({int limit = 20}) {
    final results = <TriangleResult>[];
    final seen = <String>{};

    for (final a in _adjacency.keys) {
      final neighbors = _adjacency[a]!.toList();
      for (int i = 0; i < neighbors.length; i++) {
        for (int j = i + 1; j < neighbors.length; j++) {
          final b = neighbors[i];
          final c = neighbors[j];

          // Check if B and C are NOT connected
          if (_adjacency[b]?.contains(c) == true) continue;

          final key = _pairKey(b, c);
          if (seen.contains(key)) continue;
          seen.add(key);

          final nodeB = _nodeInfo[b];
          final nodeC = _nodeInfo[c];
          final nodeA = _nodeInfo[a];
          if (nodeB == null || nodeC == null || nodeA == null) continue;

          // Skip trivial: both in same topic (already implicitly related)
          if (nodeB.type == BrainWeaveNodeType.moc ||
              nodeC.type == BrainWeaveNodeType.moc) continue;

          results.add(TriangleResult(
            parentId: a,
            parentTitle: nodeA.title,
            nodeAId: b,
            nodeATitle: nodeB.title,
            nodeBId: c,
            nodeBTitle: nodeC.title,
          ));
        }
      }
    }

    // Sort by parent degree (more connected parents → more interesting)
    results.sort((a, b) =>
        (_adjacency[b.parentId]?.length ?? 0)
            .compareTo(_adjacency[a.parentId]?.length ?? 0));
    return results.take(limit).toList();
  }

  // ── Bridges (Structurally Critical Nodes) ────────────────────────────────

  /// Find bridge nodes whose removal would disconnect the graph.
  List<BridgeResult> findBridges() {
    final results = <BridgeResult>[];
    final baseComponents = _countComponents();

    for (final nodeId in _adjacency.keys) {
      // Temporarily remove node
      final saved = _adjacency[nodeId]!.toList();
      _adjacency[nodeId]!.clear();
      for (final neighbor in saved) {
        _adjacency[neighbor]?.remove(nodeId);
      }

      final newComponents = _countComponents(exclude: nodeId);
      if (newComponents > baseComponents) {
        final node = _nodeInfo[nodeId];
        results.add(BridgeResult(
          nodeId: nodeId,
          title: node?.title ?? '',
          degree: saved.length,
          componentsSplit: newComponents - baseComponents,
        ));
      }

      // Restore
      _adjacency[nodeId]!.addAll(saved);
      for (final neighbor in saved) {
        _adjacency[neighbor]?.add(nodeId);
      }
    }

    results.sort((a, b) => b.componentsSplit.compareTo(a.componentsSplit));
    return results;
  }

  // ── Clusters (Connected Components) ─────────────────────────────────────

  /// Find connected components via BFS.
  List<ClusterResult> findClusters() {
    final visited = <String>{};
    final clusters = <ClusterResult>[];

    for (final startId in _adjacency.keys) {
      if (visited.contains(startId)) continue;

      final component = <String>[];
      final queue = [startId];
      visited.add(startId);

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        component.add(current);

        for (final neighbor in _adjacency[current] ?? <String>{}) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }

      // Determine key node (highest degree within cluster)
      String? keyNodeId;
      int maxDegree = -1;
      for (final id in component) {
        final degree = _adjacency[id]?.length ?? 0;
        if (degree > maxDegree) {
          maxDegree = degree;
          keyNodeId = id;
        }
      }

      // Collect topics
      final topics = <String>{};
      for (final id in component) {
        topics.addAll(_nodeInfo[id]?.topics ?? []);
      }

      clusters.add(ClusterResult(
        nodeIds: component,
        size: component.length,
        keyNodeId: keyNodeId ?? component.first,
        keyNodeTitle: _nodeInfo[keyNodeId]?.title ?? '',
        topics: topics.toList(),
      ));
    }

    clusters.sort((a, b) => b.size.compareTo(a.size));
    return clusters;
  }

  // ── Hubs (Authority & Hub Scoring) ──────────────────────────────────────

  /// Rank nodes by influence: incoming links (authority) and outgoing links (hub).
  List<HubResult> findHubs({int limit = 10}) {
    final results = <HubResult>[];

    for (final entry in _adjacency.entries) {
      final node = _nodeInfo[entry.key];
      if (node == null) continue;

      final degree = entry.value.length;
      results.add(HubResult(
        nodeId: entry.key,
        title: node.title,
        type: node.type,
        degree: degree,
        description: node.description,
      ));
    }

    results.sort((a, b) => b.degree.compareTo(a.degree));
    return results.take(limit).toList();
  }

  // ── Siblings (Same Topic, Not Connected) ────────────────────────────────

  /// Find nodes sharing a topic but not directly linked.
  List<SiblingResult> findSiblings(String topic) {
    final topicNodes = _nodeInfo.entries
        .where((e) => e.value.topics
            .any((t) => t.toLowerCase() == topic.toLowerCase()))
        .map((e) => e.key)
        .toList();

    final results = <SiblingResult>[];
    for (int i = 0; i < topicNodes.length; i++) {
      for (int j = i + 1; j < topicNodes.length; j++) {
        final a = topicNodes[i];
        final b = topicNodes[j];
        if (_adjacency[a]?.contains(b) != true) {
          results.add(SiblingResult(
            nodeAId: a,
            nodeATitle: _nodeInfo[a]?.title ?? '',
            nodeBId: b,
            nodeBTitle: _nodeInfo[b]?.title ?? '',
            sharedTopic: topic,
          ));
        }
      }
    }
    return results;
  }

  // ── Health Report ──────────────────────────────────────────────────────

  GraphHealthReport healthReport() {
    final clusters = findClusters();
    final orphans = _adjacency.entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key)
        .toList();
    final bridges = findBridges();

    int totalEdges = 0;
    for (final entry in _adjacency.entries) {
      totalEdges += entry.value.length;
    }
    totalEdges ~/= 2; // undirected

    final totalNodes = _adjacency.length;
    final avgDegree =
        totalNodes > 0 ? totalEdges * 2 / totalNodes : 0.0;

    return GraphHealthReport(
      totalNodes: totalNodes,
      totalEdges: totalEdges,
      clusterCount: clusters.length,
      largestCluster: clusters.isNotEmpty ? clusters.first.size : 0,
      orphanCount: orphans.length,
      bridgeCount: bridges.length,
      avgDegree: avgDegree,
      orphanIds: orphans,
      bridgeIds: bridges.map((b) => b.nodeId).toList(),
    );
  }

  // ── Helpers ──

  int _countComponents({String? exclude}) {
    final visited = <String>{};
    if (exclude != null) visited.add(exclude);
    int count = 0;

    for (final startId in _adjacency.keys) {
      if (visited.contains(startId)) continue;
      if (_adjacency[startId]!.isEmpty && exclude == null) {
        visited.add(startId);
        count++;
        continue;
      }

      final queue = [startId];
      visited.add(startId);
      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        for (final neighbor in _adjacency[current] ?? <String>{}) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }
      count++;
    }
    return count;
  }

  String _pairKey(String a, String b) =>
      a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
}

// ── Data Transfer Objects ──────────────────────────────────────────────────

class GraphNodeInfo {
  final String id;
  final String title;
  final String description;
  final BrainWeaveNodeType type;
  final List<String> topics;

  const GraphNodeInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.topics,
  });
}

class GraphEdgeInfo {
  final String sourceId;
  final String targetId;
  const GraphEdgeInfo({required this.sourceId, required this.targetId});
}

class TriangleResult {
  final String parentId, parentTitle;
  final String nodeAId, nodeATitle;
  final String nodeBId, nodeBTitle;
  const TriangleResult({
    required this.parentId,
    required this.parentTitle,
    required this.nodeAId,
    required this.nodeATitle,
    required this.nodeBId,
    required this.nodeBTitle,
  });
}

class BridgeResult {
  final String nodeId, title;
  final int degree, componentsSplit;
  const BridgeResult({
    required this.nodeId,
    required this.title,
    required this.degree,
    required this.componentsSplit,
  });
}

class ClusterResult {
  final List<String> nodeIds;
  final int size;
  final String keyNodeId, keyNodeTitle;
  final List<String> topics;
  const ClusterResult({
    required this.nodeIds,
    required this.size,
    required this.keyNodeId,
    required this.keyNodeTitle,
    required this.topics,
  });
}

class HubResult {
  final String nodeId, title, description;
  final BrainWeaveNodeType type;
  final int degree;
  const HubResult({
    required this.nodeId,
    required this.title,
    required this.type,
    required this.degree,
    required this.description,
  });
}

class SiblingResult {
  final String nodeAId, nodeATitle;
  final String nodeBId, nodeBTitle;
  final String sharedTopic;
  const SiblingResult({
    required this.nodeAId,
    required this.nodeATitle,
    required this.nodeBId,
    required this.nodeBTitle,
    required this.sharedTopic,
  });
}

class GraphHealthReport {
  final int totalNodes, totalEdges, clusterCount, largestCluster;
  final int orphanCount, bridgeCount;
  final double avgDegree;
  final List<String> orphanIds, bridgeIds;

  const GraphHealthReport({
    required this.totalNodes,
    required this.totalEdges,
    required this.clusterCount,
    required this.largestCluster,
    required this.orphanCount,
    required this.bridgeCount,
    required this.avgDegree,
    required this.orphanIds,
    required this.bridgeIds,
  });
}
