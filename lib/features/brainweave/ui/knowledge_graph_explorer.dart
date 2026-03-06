import 'dart:math';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_environment.dart';
import '../services/brainweave_mcp_client.dart';
import '../models/brainweave_link.dart';
import '../models/brainweave_node.dart';
import '../services/graph_analysis_service.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _kGraphBg       = Color(0xFF0F1117);
const _kSidebarBg     = Color(0xFF13151C);
const _kSidebarBorder = Color(0xFF2A2D3A);
const _kAccentPurple  = Color(0xFF7C3AED);
const _kAccentGold    = Color(0xFFD4A574);
const _kAccentGreen   = Color(0xFF10B981);
const _kAccentAmber   = Color(0xFFF59E0B);
const _kTextCream     = Color(0xFFE5DDD0);
const _kTextMuted     = Color(0xFF8B8D97);
const _kNodeMoc       = Color(0xFFD4A574);
const _kNodeTopic     = Color(0xFFF59E0B);
const _kNodeAtomic    = Color(0xFF6B7280);
const _kEdgeColor     = Color(0xFF2A2D3A);

// Cluster color palette (8 distinct hues for connected components)
const _kClusterColors = [
  Color(0xFF7C3AED), // purple
  Color(0xFF10B981), // green
  Color(0xFFF59E0B), // amber
  Color(0xFFEF4444), // red
  Color(0xFF3B82F6), // blue
  Color(0xFFEC4899), // pink
  Color(0xFF14B8A6), // teal
  Color(0xFFF97316), // orange
];

// ─── Physics Node Model ─────────────────────────────────────────────────────

class _GraphNode {
  final BrainWeaveNode data;
  double x, y, vx, vy;
  double radius;
  bool isDragging;
  bool isHovered;
  Color? clusterColor; // Assigned after cluster detection
  int clusterId = 0;

  _GraphNode({
    required this.data,
    required this.x,
    required this.y,
    this.radius = 6,
  })  : vx = 0,
        vy = 0,
        isDragging = false,
        isHovered = false;

  Color get color {
    // Use cluster color if available for atomic nodes
    if (clusterColor != null && data.type == BrainWeaveNodeType.atomic) {
      return clusterColor!;
    }
    switch (data.type) {
      case BrainWeaveNodeType.moc:
        return _kNodeMoc;
      case BrainWeaveNodeType.topic:
        return _kNodeTopic;
      case BrainWeaveNodeType.atomic:
      default:
        return _kNodeAtomic;
    }
  }
}

class _GraphEdge {
  final String sourceId;
  final String targetId;
  final String label; // e.g. 'shared_topic:ai', 'extends', 'contradicts'
  _GraphNode? source;
  _GraphNode? target;

  _GraphEdge({required this.sourceId, required this.targetId, this.label = ''});

  /// Opacity based on relationship type
  double get opacity {
    if (label.startsWith('shared_topic:')) return 0.35;
    if (label == 'extends' || label == 'supports') return 0.8;
    if (label == 'contradicts') return 0.9;
    return 0.5;
  }

  /// Color based on relationship type
  Color get edgeColor {
    if (label == 'contradicts') return const Color(0xFFEF4444);
    if (label == 'extends') return _kAccentGreen;
    if (label == 'supports') return const Color(0xFF3B82F6);
    return _kEdgeColor;
  }
}

// ─── Main Explorer Widget ───────────────────────────────────────────────────

class KnowledgeGraphExplorer extends ConsumerStatefulWidget {
  final bool agencyMode;
  const KnowledgeGraphExplorer({super.key, this.agencyMode = false});

  @override
  ConsumerState<KnowledgeGraphExplorer> createState() =>
      _KnowledgeGraphExplorerState();
}

class _KnowledgeGraphExplorerState
    extends ConsumerState<KnowledgeGraphExplorer>
    with SingleTickerProviderStateMixin {
  // ── Data ──
  List<_GraphNode> _nodes = [];
  List<_GraphEdge> _edges = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _error; // Added for error handling

  // ── View State ──
  _GraphNode? _selectedNode;
  _GraphNode? _hoveredNode;
  BrainWeaveNode? _openedNote; // if non-null, show note reader view

  // ── Analysis ──
  GraphHealthReport? _healthReport;
  String? _activeAnalysis; // 'triangles', 'bridges', 'hubs', 'clusters', null
  List<String> _highlightedNodeIds = [];
  bool _showStats = true;
  String? _expandedCategory; // currently expanded sidebar category

  // ── Transform (pan/zoom) ──
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;
  Offset? _lastPanPosition;

  // ── Physics ──
  late AnimationController _physicsController;
  int _cooldown = 0; // frames of low-energy before pausing
  static const _maxCooldown = 120;

  // ── Drag ──
  _GraphNode? _dragNode;

  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'demo';

  @override
  void initState() {
    super.initState();
    _physicsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick);
    _loadGraphData();
  }

  @override
  void dispose() {
    _physicsController.dispose();
    super.dispose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────────

  BrainWeaveNodeType _parseType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'moc':
        return BrainWeaveNodeType.moc;
      case 'topic':
        return BrainWeaveNodeType.topic;
      case 'atomic':
      default:
        return BrainWeaveNodeType.atomic;
    }
  }

  Future<void> _loadGraphData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rnd = Random(42);
      final centerX = 500.0;
      final centerY = 400.0;

      if (AppConfig.brainweaveV2Enabled) {
        // ── BrainWeave 2.0: Spanner (via MCP API) ──
        final mcp = BrainWeaveMcpClient();
        final result = widget.agencyMode
            ? await mcp.getAgencyGraphData()
            : await mcp.getGraphData();
        
        final nodesData = List<Map<String, dynamic>>.from(result['nodes'] ?? []);
        final edgesData = List<Map<String, dynamic>>.from(result['edges'] ?? []);

        final List<_GraphNode> nodes = [];
        final nodeMap = <String, _GraphNode>{};

        for (final n in nodesData) {
          final bwNode = BrainWeaveNode(
            id: n['node_id'],
            clientId: '', projectId: '', ownerId: _userId,
            title: n['title'] ?? '',
            description: n['description'] ?? '',
            content: n['content'] ?? '',
            type: _parseType(n['node_type']),
            topics: List<String>.from(n['topics'] ?? []),
            metadata: Map<String, dynamic>.from(n['metadata'] ?? {}),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final angle = rnd.nextDouble() * 2 * pi;
          final dist = 100 + rnd.nextDouble() * 300;
          final r = bwNode.type == BrainWeaveNodeType.moc
              ? 14.0
              : bwNode.type == BrainWeaveNodeType.topic
                  ? 10.0
                  : 5.0;

          final node = _GraphNode(
            data: bwNode,
            x: centerX + cos(angle) * dist,
            y: centerY + sin(angle) * dist,
            radius: r,
          );
          nodes.add(node);
          nodeMap[bwNode.id] = node;
        }

        final List<_GraphEdge> edges = [];
        for (final e in edgesData) {
          if (nodeMap.containsKey(e['source_node_id']) &&
              nodeMap.containsKey(e['target_node_id'])) {
            final edge = _GraphEdge(
              sourceId: e['source_node_id'],
              targetId: e['target_node_id'],
              label: e['relationship_type'] ?? 'link',
            );
            edge.source = nodeMap[e['source_node_id']];
            edge.target = nodeMap[e['target_node_id']];
            edges.add(edge);
          }
        }

        if (mounted) {
          setState(() {
            _nodes = nodes;
            _edges = edges;
            _isLoading = false;
          });
        }
      } else {
        // ── BrainWeave 1.x: Firestore (Legacy) ──
        final db = FirebaseFirestore.instance;
        final nodesSnap = await db
            .collection('brainweave_nodes')
            .where('ownerId', isEqualTo: _userId)
            .get();

        _nodes = nodesSnap.docs.map((doc) {
          final node = BrainWeaveNode.fromJson(doc.data(), doc.id);
          final angle = rnd.nextDouble() * 2 * pi;
          final dist = 100 + rnd.nextDouble() * 300;
          final r = node.type == BrainWeaveNodeType.moc
              ? 14.0
              : node.type == BrainWeaveNodeType.topic
                  ? 10.0
                  : 5.0;
          return _GraphNode(
            data: node,
            x: centerX + cos(angle) * dist,
            y: centerY + sin(angle) * dist,
            radius: r,
          );
        }).toList();

        final linksSnap = await db
            .collection('brainweave_links')
            .where('ownerId', isEqualTo: _userId)
            .get();

        final nodeMap = {for (var n in _nodes) n.data.id: n};

        _edges = linksSnap.docs.map((doc) {
          final data = doc.data();
          final edge = _GraphEdge(
              sourceId: data['sourceNodeId'],
              targetId: data['targetNodeId'],
              label: data['relationshipType']);
          edge.source = nodeMap[data['sourceNodeId']];
          edge.target = nodeMap[data['targetNodeId']];
          return edge;
        }).where((e) => e.source != null && e.target != null).toList();
      }

      // Shared topic inference & UI refinements (Shared between V1/V2)
      final nodeMapCommon = {for (var n in _nodes) n.data.id: n};
      final topicIndex = <String, Set<String>>{};
      for (var node in _nodes) {
        for (var topic in node.data.topics) {
          final key = topic.toLowerCase().trim();
          topicIndex.putIfAbsent(key, () => {}).add(node.data.id);
        }
      }

      for (var entry in topicIndex.entries) {
        final ids = entry.value.toList();
        if (ids.length < 2) continue;
        for (int i = 0; i < ids.length; i++) {
          for (int j = i + 1; j < ids.length; j++) {
            final exists = _edges.any((e) =>
                (e.sourceId == ids[i] && e.targetId == ids[j]) ||
                (e.sourceId == ids[j] && e.targetId == ids[i]));
            if (!exists) {
              final edge = _GraphEdge(
                  sourceId: ids[i],
                  targetId: ids[j],
                  label: 'shared_topic:${entry.key}');
              edge.source = nodeMapCommon[ids[i]];
              edge.target = nodeMapCommon[ids[j]];
              _edges.add(edge);
            }
          }
        }
      }

      // Dynamic sizing
      final degreeMap = <String, int>{};
      for (var edge in _edges) {
        degreeMap[edge.sourceId] = (degreeMap[edge.sourceId] ?? 0) + 1;
        degreeMap[edge.targetId] = (degreeMap[edge.targetId] ?? 0) + 1;
      }
      for (var node in _nodes) {
        final degree = degreeMap[node.data.id] ?? 0;
        final baseRadius = node.data.type == BrainWeaveNodeType.moc ? 14.0 
            : node.data.type == BrainWeaveNodeType.topic ? 10.0 : 5.0;
        node.radius = baseRadius + (degree * 1.2).clamp(0, 12);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _physicsController.repeat();
      }
    } catch (e) {
      debugPrint('KnowledgeGraphExplorer: Error loading: $e');
      if (mounted) setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _assignClusterColors(Map<String, _GraphNode> nodeMap) {
    final visited = <String>{};
    int clusterId = 0;

    for (final node in _nodes) {
      if (visited.contains(node.data.id)) continue;

      final queue = [node.data.id];
      visited.add(node.data.id);
      final component = <String>[];

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        component.add(current);

        for (final edge in _edges) {
          String? neighborId;
          if (edge.sourceId == current) neighborId = edge.targetId;
          if (edge.targetId == current) neighborId = edge.sourceId;
          if (neighborId != null && !visited.contains(neighborId)) {
            visited.add(neighborId);
            queue.add(neighborId);
          }
        }
      }

      final clusterColor = _kClusterColors[clusterId % _kClusterColors.length];
      for (final id in component) {
        final n = nodeMap[id];
        if (n != null) {
          n.clusterColor = clusterColor;
          n.clusterId = clusterId;
        }
      }
      clusterId++;
    }
  }

  void _computeHealthReport() {
    final analysisService = GraphAnalysisService.fromData(
      nodes: _nodes.map((n) => GraphNodeInfo(
        id: n.data.id,
        title: n.data.title,
        description: n.data.description,
        type: n.data.type,
        topics: n.data.topics,
      )).toList(),
      edges: _edges.map((e) => GraphEdgeInfo(
        sourceId: e.sourceId,
        targetId: e.targetId,
      )).toList(),
    );
    _healthReport = analysisService.healthReport();
  }

  void _runAnalysis(String type) {
    final analysisService = GraphAnalysisService.fromData(
      nodes: _nodes.map((n) => GraphNodeInfo(
        id: n.data.id,
        title: n.data.title,
        description: n.data.description,
        type: n.data.type,
        topics: n.data.topics,
      )).toList(),
      edges: _edges.map((e) => GraphEdgeInfo(
        sourceId: e.sourceId,
        targetId: e.targetId,
      )).toList(),
    );

    setState(() {
      if (_activeAnalysis == type) {
        _activeAnalysis = null;
        _highlightedNodeIds = [];
        return;
      }
      _activeAnalysis = type;
      switch (type) {
        case 'triangles':
          final triangles = analysisService.findTriangles(limit: 15);
          _highlightedNodeIds = triangles
              .expand((t) => [t.nodeAId, t.nodeBId, t.parentId])
              .toSet()
              .toList();
          break;
        case 'bridges':
          final bridges = analysisService.findBridges();
          _highlightedNodeIds = bridges.map((b) => b.nodeId).toList();
          break;
        case 'hubs':
          final hubs = analysisService.findHubs(limit: 8);
          _highlightedNodeIds = hubs.map((h) => h.nodeId).toList();
          break;
        case 'clusters':
          // Just toggle cluster view — colors already assigned
          _highlightedNodeIds = [];
          break;
      }
    });
  }

  // ── Physics Simulation ──────────────────────────────────────────────────

  void _tick() {
    if (_nodes.isEmpty) return;

    double totalKineticEnergy = 0;

    // Repulsion (all pairs)
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final a = _nodes[i];
        final b = _nodes[j];
        double dx = b.x - a.x;
        double dy = b.y - a.y;
        double dist = sqrt(dx * dx + dy * dy).clamp(1, double.infinity);
        double force = 5000 / (dist * dist);
        double fx = (dx / dist) * force;
        double fy = (dy / dist) * force;
        if (!a.isDragging) {
          a.vx -= fx;
          a.vy -= fy;
        }
        if (!b.isDragging) {
          b.vx += fx;
          b.vy += fy;
        }
      }
    }

    // Attraction (edges)
    for (var edge in _edges) {
      if (edge.source == null || edge.target == null) continue;
      final a = edge.source!;
      final b = edge.target!;
      double dx = b.x - a.x;
      double dy = b.y - a.y;
      double dist = sqrt(dx * dx + dy * dy).clamp(1, double.infinity);
      double force = (dist - 120) * 0.01;
      double fx = (dx / dist) * force;
      double fy = (dy / dist) * force;
      if (!a.isDragging) {
        a.vx += fx;
        a.vy += fy;
      }
      if (!b.isDragging) {
        b.vx -= fx;
        b.vy -= fy;
      }
    }

    // Center gravity
    double cx = 500, cy = 400;
    for (var node in _nodes) {
      if (node.isDragging) continue;
      double dx = cx - node.x;
      double dy = cy - node.y;
      node.vx += dx * 0.0005;
      node.vy += dy * 0.0005;
    }

    // Apply velocity with damping
    for (var node in _nodes) {
      if (node.isDragging) continue;
      node.vx *= 0.85;
      node.vy *= 0.85;
      node.x += node.vx;
      node.y += node.vy;
      totalKineticEnergy += node.vx * node.vx + node.vy * node.vy;
    }

    // Cooldown detection
    if (totalKineticEnergy < 0.1) {
      _cooldown++;
      if (_cooldown > _maxCooldown) {
        _physicsController.stop();
        _cooldown = 0;
      }
    } else {
      _cooldown = 0;
    }

    setState(() {});
  }

  void _ensurePhysicsRunning() {
    if (!_physicsController.isAnimating) {
      _cooldown = 0;
      _physicsController.repeat();
    }
  }

  // ── Hit Test ──────────────────────────────────────────────────────────────

  _GraphNode? _hitTest(Offset localPosition) {
    final worldPos = (localPosition - _panOffset) / _scale;
    for (var node in _nodes.reversed) {
      final dx = node.x - worldPos.dx;
      final dy = node.y - worldPos.dy;
      if (dx * dx + dy * dy <= (node.radius + 8) * (node.radius + 8)) {
        return node;
      }
    }
    return null;
  }

  // ── Category Helpers ──────────────────────────────────────────────────────

  Map<String, List<_GraphNode>> get _categorizedNodes {
    final map = <String, List<_GraphNode>>{};
    for (var node in _filteredNodes) {
      final category = node.data.type == BrainWeaveNodeType.moc
          ? node.data.title
          : node.data.topics.isNotEmpty
              ? node.data.topics.first
              : 'Uncategorized';
      map.putIfAbsent(category, () => []).add(node);
    }
    // Sort by count descending
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    return Map.fromEntries(sorted);
  }

  List<_GraphNode> get _filteredNodes {
    if (_searchQuery.isEmpty) return _nodes;
    final q = _searchQuery.toLowerCase();
    return _nodes.where((n) =>
        n.data.title.toLowerCase().contains(q) ||
        n.data.description.toLowerCase().contains(q) ||
        n.data.topics.any((t) => t.toLowerCase().contains(q))).toList();
  }

  int get _totalNodeCount => _nodes.length;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_openedNote != null) {
      return _buildNoteReader();
    }
    return Container(
      color: _kGraphBg,
      child: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _kAccentPurple),
                  SizedBox(height: 16),
                  Text('Loading Knowledge Graph…',
                      style: TextStyle(color: _kTextMuted, fontSize: 13)),
                ],
              ),
            )
          : _nodes.isEmpty
              ? _buildEmptyState()
              : Row(
                  children: [
                    _buildSidebar(),
                    Expanded(child: _buildGraphCanvas()),
                  ],
                ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.diagramProject,
              color: _kTextMuted.withValues(alpha: 0.3), size: 64),
          const SizedBox(height: 20),
          const Text('No Knowledge Graph Yet',
              style: TextStyle(
                  color: _kTextCream,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Run the 6R Pipeline to populate your knowledge graph.\nNodes and edges will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kTextMuted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Sidebar (Ars Contexta-style) ──────────────────────────────────────────

  Widget _buildSidebar() {
    final categories = _categorizedNodes;
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: _kSidebarBg,
        border: Border(right: BorderSide(color: _kSidebarBorder, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios,
                          size: 14, color: _kTextMuted),
                      const SizedBox(width: 4),
                      Text('Back',
                          style: TextStyle(color: _kTextMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_left, size: 18, color: _kTextMuted),
              ],
            ),
          ),

          // ── Search ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: _kTextCream, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search nodes…',
                hintStyle: TextStyle(color: _kTextMuted.withValues(alpha: 0.6), fontSize: 13),
                prefixIcon: Icon(Icons.search,
                    size: 18, color: _kTextMuted.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Vault Info ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _kAccentPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kAccentPurple.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.brain,
                      size: 12, color: _kAccentPurple),
                  const SizedBox(width: 8),
                  Text('brainweave',
                      style: TextStyle(
                          color: _kAccentPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text('★ $_totalNodeCount',
                      style: TextStyle(color: _kTextMuted, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Categories ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                // MOC categories
                ...categories.entries.map((entry) {
                  final isExpanded = _expandedCategory == entry.key;
                  final mocNodes = entry.value
                      .where((n) => n.data.type == BrainWeaveNodeType.moc)
                      .toList();
                  final isMocCategory = mocNodes.isNotEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedCategory =
                                isExpanded ? null : entry.key;
                          });
                          // Center on first node in category
                          if (entry.value.isNotEmpty) {
                            _focusNode(entry.value.first);
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                isExpanded
                                    ? Icons.expand_more
                                    : Icons.chevron_right,
                                size: 16,
                                color: _kTextMuted,
                              ),
                              const SizedBox(width: 4),
                              if (isMocCategory) ...[
                                FaIcon(FontAwesomeIcons.sitemap,
                                    size: 11, color: _kNodeMoc),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: _kTextCream.withValues(alpha: 0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${entry.value.length}',
                                style: TextStyle(
                                    color: _kTextMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        ...entry.value.map((node) => _buildSidebarNote(node)),
                    ],
                  );
                }),
              ],
            ),
          ),

          // ── Footer ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: _kSidebarBorder, width: 1)),
            ),
            child: Text(
              '$_totalNodeCount nodes · ${_edges.length} edges',
              style: TextStyle(color: _kTextMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNote(_GraphNode node) {
    final isSelected = _selectedNode?.data.id == node.data.id;
    return InkWell(
      onTap: () {
        _focusNode(node);
        setState(() => _selectedNode = node);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.only(left: 36, right: 8, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? _kAccentPurple.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 14, color: _kTextMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                node.data.title,
                style: TextStyle(
                  color: isSelected ? _kAccentPurple : _kTextCream.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _focusNode(_GraphNode node) {
    _ensurePhysicsRunning();
    setState(() {
      _selectedNode = node;
      _scale = 1.5;
      _panOffset = Offset(-node.x * _scale + 400, -node.y * _scale + 300);
    });
  }

  // ── Graph Canvas ──────────────────────────────────────────────────────────

  Widget _buildGraphCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              setState(() {
                final oldScale = _scale;
                _scale = (_scale - event.scrollDelta.dy * 0.001)
                    .clamp(0.2, 4.0);
                // Zoom towards cursor
                final ratio = _scale / oldScale;
                _panOffset = event.localPosition -
                    (event.localPosition - _panOffset) * ratio;
              });
            }
          },
          child: GestureDetector(
            onPanStart: (details) {
              final hit = _hitTest(details.localPosition);
              if (hit != null) {
                _dragNode = hit;
                hit.isDragging = true;
                _ensurePhysicsRunning();
              } else {
                _lastPanPosition = details.localPosition;
              }
            },
            onPanUpdate: (details) {
              if (_dragNode != null) {
                final worldDelta = details.delta / _scale;
                _dragNode!.x += worldDelta.dx;
                _dragNode!.y += worldDelta.dy;
                _dragNode!.vx = 0;
                _dragNode!.vy = 0;
                _ensurePhysicsRunning();
                setState(() {});
              } else if (_lastPanPosition != null) {
                setState(() {
                  _panOffset += details.delta;
                });
              }
            },
            onPanEnd: (details) {
              if (_dragNode != null) {
                _dragNode!.isDragging = false;
                _dragNode = null;
                _ensurePhysicsRunning();
              }
              _lastPanPosition = null;
            },
            onTapUp: (details) {
              final hit = _hitTest(details.localPosition);
              setState(() {
                _selectedNode = hit;
                _hoveredNode = null;
              });
            },
            child: MouseRegion(
              onHover: (event) {
                final hit = _hitTest(event.localPosition);
                if (hit != _hoveredNode) {
                  setState(() => _hoveredNode = hit);
                }
              },
              cursor: _hoveredNode != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.grab,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _GraphPainter(
                      nodes: _nodes,
                      edges: _edges,
                      offset: _panOffset,
                      scale: _scale,
                      selectedNode: _selectedNode,
                      hoveredNode: _hoveredNode,
                      highlightedNodeIds: _highlightedNodeIds,
                      activeAnalysis: _activeAnalysis,
                    ),
                  ),

                  // ── Analysis Toolbar (top) ──
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _analysisButton('🔺', 'Triangles', 'triangles'),
                        const SizedBox(width: 6),
                        _analysisButton('🌉', 'Bridges', 'bridges'),
                        const SizedBox(width: 6),
                        _analysisButton('🎯', 'Hubs', 'hubs'),
                        const SizedBox(width: 6),
                        _analysisButton('🧩', 'Clusters', 'clusters'),
                        const Spacer(),
                        // Mermaid export
                        _iconBtn(Icons.schema_outlined, () {
                          final buf = StringBuffer('graph LR\n');
                          final nodeIds = <String, String>{};
                          for (int i = 0; i < _nodes.length; i++) {
                            final nid = 'N$i';
                            nodeIds[_nodes[i].data.id] = nid;
                            final label = _nodes[i].data.title.replaceAll('"', "'");
                            buf.writeln('  $nid["$label"]');
                          }
                          for (final e in _edges) {
                            final s = nodeIds[e.source?.data.id];
                            final t = nodeIds[e.target?.data.id];
                            if (s != null && t != null) {
                              buf.writeln('  $s --> $t');
                            }
                          }
                          Clipboard.setData(ClipboardData(text: buf.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mermaid graph copied to clipboard')),
                          );
                        }),
                        const SizedBox(width: 4),
                        // Cluster highlight via MCP
                        _iconBtn(Icons.hub_outlined, () async {
                          try {
                            final mcp = BrainWeaveMcpClient();
                            final clusters = await mcp.cluster();
                            final colorMap = <String, Color>{};
                            for (int ci = 0; ci < clusters.length; ci++) {
                              final color = _kClusterColors[ci % _kClusterColors.length];
                              final clusterNodes = List<Map<String, dynamic>>.from(clusters[ci]['nodes'] ?? []);
                              for (final cn in clusterNodes) {
                                colorMap[cn['node_id']] = color;
                              }
                            }
                            setState(() {
                              for (final n in _nodes) {
                                n.clusterColor = colorMap[n.data.id] ?? _kNodeAtomic;
                              }
                            });
                          } catch (e) {
                            debugPrint('Cluster highlight failed: $e');
                          }
                        }),
                        const SizedBox(width: 4),
                        // Zoom controls
                        _iconBtn(Icons.add, () => setState(() => _scale = (_scale * 1.3).clamp(0.2, 4.0))),
                        const SizedBox(width: 4),
                        _iconBtn(Icons.remove, () => setState(() => _scale = (_scale / 1.3).clamp(0.2, 4.0))),
                        const SizedBox(width: 4),
                        _iconBtn(Icons.center_focus_strong, () {
                          setState(() {
                            _scale = 1.0;
                            _panOffset = const Offset(-100, -100);
                          });
                        }),
                      ],
                    ),
                  ),

                  // ── Stats Overlay (bottom-right) ──
                  if (_showStats && _healthReport != null)
                    Positioned(
                      bottom: 84, // Moved higher to clear floating action button
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kSidebarBg.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kSidebarBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _statRow('Nodes', '${_healthReport!.totalNodes}'),
                            _statRow('Edges', '${_healthReport!.totalEdges}'),
                            _statRow('Clusters', '${_healthReport!.clusterCount}'),
                            _statRow('Avg degree', _healthReport!.avgDegree.toStringAsFixed(1)),
                            _statRow('Orphans', '${_healthReport!.orphanCount}'),
                            if (_healthReport!.bridgeCount > 0)
                              _statRow('Bridges', '${_healthReport!.bridgeCount}',
                                  color: _kAccentAmber),
                          ],
                        ),
                      ),
                    ),

                  // ── Hover Tooltip (description) ──
                  if (_hoveredNode != null && _selectedNode == null)
                    Positioned(
                      left: (_hoveredNode!.x * _scale + _panOffset.dx).clamp(8, constraints.maxWidth - 260),
                      top: (_hoveredNode!.y * _scale + _panOffset.dy - 50).clamp(8, constraints.maxHeight - 60),
                      child: IgnorePointer(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xDD1A1D27),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _kSidebarBorder),
                          ),
                          child: Text(
                            _hoveredNode!.data.description.isNotEmpty
                                ? _hoveredNode!.data.description
                                : _hoveredNode!.data.title,
                            style: const TextStyle(color: _kTextCream, fontSize: 11, height: 1.3),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),

                  // ── Node Detail Card Popup ──
                  if (_selectedNode != null)
                    _buildNodeDetailCard(
                        _selectedNode!, constraints),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // ── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _analysisButton(String emoji, String label, String type) {
    final isActive = _activeAnalysis == type;
    return InkWell(
      onTap: () => _runAnalysis(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? _kAccentPurple.withValues(alpha: 0.25)
              : _kSidebarBg.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? _kAccentPurple : _kSidebarBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _kAccentPurple : _kTextMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _kSidebarBg.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kSidebarBorder),
        ),
        child: Icon(icon, size: 16, color: _kTextMuted),
      ),
    );
  }

  Widget _statRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: _kTextMuted, fontSize: 10)),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                color: color ?? _kTextCream,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  // ── Node Detail Card (floating) ───────────────────────────────────────────

  Widget _buildNodeDetailCard(
      _GraphNode node, BoxConstraints constraints) {
    final screenPos = Offset(
            node.x * _scale + _panOffset.dx,
            node.y * _scale + _panOffset.dy)
        .translate(0, -node.radius * _scale - 12);

    // Clamp to viewport
    final cardWidth = 280.0;
    final cardHeight = 200.0;
    double left = screenPos.dx - cardWidth / 2;
    double top = screenPos.dy - cardHeight;
    left = left.clamp(8, constraints.maxWidth - cardWidth - 8);
    top = top.clamp(8, constraints.maxHeight - cardHeight - 8);

    // Connection count
    final connections = _edges.where((e) =>
        e.sourceId == node.data.id || e.targetId == node.data.id).length;

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: cardWidth,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D27),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kSidebarBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                node.data.title,
                style: const TextStyle(
                  color: _kTextCream,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '$connections connection${connections == 1 ? '' : 's'}',
                    style: TextStyle(color: _kTextMuted, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: node.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      node.data.type.name,
                      style: TextStyle(
                          color: node.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                node.data.description.isNotEmpty
                    ? node.data.description
                    : node.data.content.length > 120
                        ? '${node.data.content.substring(0, 120)}…'
                        : node.data.content,
                style: TextStyle(
                    color: _kTextCream.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      setState(() => _openedNote = node.data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccentGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Open note'),
                ),
              ),
              if (node.data.metadata != null && (node.data.metadata!['url'] != null || node.data.metadata!['pdfUrl'] != null)) ...[
                 const SizedBox(height: 8),
                 SizedBox(
                   width: double.infinity,
                   child: OutlinedButton.icon(
                     onPressed: () {
                         final url = node.data.metadata!['url'] ?? node.data.metadata!['pdfUrl'];
                         if (url != null && url.toString().isNotEmpty) {
                             launchUrl(Uri.parse(url.toString()));
                         }
                     },
                     icon: const Icon(Icons.open_in_new, size: 14, color: _kTextCream),
                     label: const Text('View Source Media', style: TextStyle(color: _kTextCream)),
                     style: OutlinedButton.styleFrom(
                       side: const BorderSide(color: _kSidebarBorder),
                       padding: const EdgeInsets.symmetric(vertical: 8),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                     ),
                   ),
                 ),
              ],
              // ── Promote Buttons ──
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          final mcp = BrainWeaveMcpClient();
                          await mcp.promote(nodeId: node.data.id, targetScope: 'CLIENT');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Promoted to CLIENT scope')),
                            );
                          }
                        } catch (e) {
                          debugPrint('Promote failed: $e');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kAccentGold),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Promote to CLIENT', style: TextStyle(color: _kAccentGold, fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          final mcp = BrainWeaveMcpClient();
                          await mcp.promote(nodeId: node.data.id, targetScope: 'AGENCY');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Shared with Agency')),
                            );
                          }
                        } catch (e) {
                          debugPrint('Share failed: $e');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kAccentPurple),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Share with Agency', style: TextStyle(color: _kAccentPurple, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Note Reader View ──────────────────────────────────────────────────────

  Widget _buildNoteReader() {
    final note = _openedNote!;

    // Find parent category
    final parentCategory = note.topics.isNotEmpty ? note.topics.first : 'index';

    // Related nodes (by shared topics)
    final related = _nodes.where((n) =>
        n.data.id != note.id &&
        n.data.topics.any((t) => note.topics.contains(t))).toList();

    return Container(
      color: _kGraphBg,
      child: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                // ── Breadcrumbs ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kSidebarBg,
                    border: Border(
                        bottom: BorderSide(color: _kSidebarBorder)),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() {
                          _openedNote = null;
                        }),
                        child: const Icon(Icons.arrow_back,
                            size: 18, color: _kTextMuted),
                      ),
                      const SizedBox(width: 12),
                      _breadcrumb('index', onTap: () {
                        setState(() => _openedNote = null);
                      }),
                      Text(' > ', style: TextStyle(color: _kTextMuted)),
                      _breadcrumb(parentCategory),
                      Text(' > ', style: TextStyle(color: _kTextMuted)),
                      Expanded(
                        child: Text(
                          note.title,
                          style: TextStyle(
                              color: _kTextCream.withValues(alpha: 0.8),
                              fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            setState(() => _openedNote = null),
                        icon: const Icon(Icons.close,
                            color: _kTextMuted, size: 20),
                        tooltip: 'Return to graph',
                      ),
                    ],
                  ),
                ),

                // ── Content ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 64, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: const TextStyle(
                            color: _kTextCream,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Tags
                        Wrap(
                          spacing: 8,
                          children: [
                            _tag(note.type.name, _kAccentPurple),
                            ...note.topics.map(
                                (t) => _tag(t, _kAccentGold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Description  
                        if (note.description.isNotEmpty)
                          Text(
                            note.description,
                            style: TextStyle(
                              color: _kTextCream.withValues(alpha: 0.6),
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        const SizedBox(height: 24),
                        Divider(color: _kSidebarBorder),
                        const SizedBox(height: 24),
                        // Title (again, as heading)
                        Text(
                          note.title,
                          style: const TextStyle(
                            color: _kTextCream,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Content body
                        Text(
                          note.content,
                          style: TextStyle(
                            color: _kTextCream.withValues(alpha: 0.85),
                            fontSize: 15,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Asset URL Button
                        if (note.metadata != null && (note.metadata!['url'] != null || note.metadata!['pdfUrl'] != null)) ...[
                           SizedBox(
                             width: double.infinity,
                             child: OutlinedButton.icon(
                               onPressed: () {
                                   final url = note.metadata!['url'] ?? note.metadata!['pdfUrl'];
                                   if (url != null && url.toString().isNotEmpty) {
                                       launchUrl(Uri.parse(url.toString()));
                                   }
                               },
                               icon: const Icon(Icons.open_in_new, size: 16, color: _kTextCream),
                               label: const Text('View Source Media', style: TextStyle(color: _kTextCream)),
                               style: OutlinedButton.styleFrom(
                                 side: const BorderSide(color: _kSidebarBorder),
                                 padding: const EdgeInsets.symmetric(vertical: 12),
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                 textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                               ),
                             ),
                           ),
                           const SizedBox(height: 32),
                        ],

                        // Related notes
                        if (related.isNotEmpty) ...[
                          Divider(color: _kSidebarBorder),
                          const SizedBox(height: 16),
                          const Text('Related Notes',
                              style: TextStyle(
                                  color: _kTextCream,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          ...related.take(5).map((r) => InkWell(
                                onTap: () =>
                                    setState(() => _openedNote = r.data),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Text(
                                    r.data.title,
                                    style: const TextStyle(
                                      color: _kAccentGold,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                      decorationColor: _kAccentGold,
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breadcrumb(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: onTap != null ? _kTextMuted : _kTextCream.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ─── Graph Painter ──────────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  final List<_GraphNode> nodes;
  final List<_GraphEdge> edges;
  final Offset offset;
  final double scale;
  final _GraphNode? selectedNode;
  final _GraphNode? hoveredNode;
  final List<String> highlightedNodeIds;
  final String? activeAnalysis;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    required this.offset,
    required this.scale,
    this.selectedNode,
    this.hoveredNode,
    this.highlightedNodeIds = const [],
    this.activeAnalysis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final hasHighlights = highlightedNodeIds.isNotEmpty;

    // ── Draw Edges ──
    for (var edge in edges) {
      if (edge.source == null || edge.target == null) continue;

      final isSelectedEdge = selectedNode != null &&
          (edge.sourceId == selectedNode!.data.id ||
              edge.targetId == selectedNode!.data.id);

      final isHighlightedEdge = hasHighlights &&
          highlightedNodeIds.contains(edge.sourceId) &&
          highlightedNodeIds.contains(edge.targetId);

      // Edge paint with per-edge opacity and color
      final Paint paint;
      if (isSelectedEdge) {
        paint = Paint()
          ..color = _kAccentGold.withValues(alpha: 0.5)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;
      } else if (isHighlightedEdge) {
        paint = Paint()
          ..color = _kAccentPurple.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
      } else {
        final dimFactor = hasHighlights ? 0.08 : 1.0;
        paint = Paint()
          ..color = edge.edgeColor.withValues(alpha: edge.opacity * dimFactor)
          ..strokeWidth = isSelectedEdge ? 1.5 : 0.6
          ..style = PaintingStyle.stroke;
      }

      canvas.drawLine(
        Offset(edge.source!.x, edge.source!.y),
        Offset(edge.target!.x, edge.target!.y),
        paint,
      );

      // Edge labels when zoomed in enough
      if (scale > 1.5 && edge.label.isNotEmpty && (isSelectedEdge || isHighlightedEdge)) {
        final midX = (edge.source!.x + edge.target!.x) / 2;
        final midY = (edge.source!.y + edge.target!.y) / 2;
        final displayLabel = edge.label.startsWith('shared_topic:')
            ? edge.label.replaceFirst('shared_topic:', '# ')
            : edge.label;

        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 7,
        ))
          ..pushStyle(ui.TextStyle(
            color: _kTextMuted.withValues(alpha: 0.7),
          ))
          ..addText(displayLabel.length > 20
              ? '${displayLabel.substring(0, 20)}…'
              : displayLabel);
        final paragraph = builder.build()
          ..layout(const ui.ParagraphConstraints(width: 120));
        canvas.drawParagraph(
          paragraph,
          Offset(midX - paragraph.width / 2, midY - 5),
        );
      }
    }

    // ── Draw Nodes ──
    for (var node in nodes) {
      final isSelected = selectedNode?.data.id == node.data.id;
      final isHovered = hoveredNode?.data.id == node.data.id;
      final isConnected = selectedNode != null &&
          edges.any((e) =>
              (e.sourceId == selectedNode!.data.id &&
                  e.targetId == node.data.id) ||
              (e.targetId == selectedNode!.data.id &&
                  e.sourceId == node.data.id));
      final isHighlighted =
          highlightedNodeIds.contains(node.data.id);

      // Dim logic: dim if there's a selection/highlight and this node isn't relevant
      final bool isDimmed;
      if (hasHighlights) {
        isDimmed = !isHighlighted && !isSelected;
      } else if (selectedNode != null) {
        isDimmed = !isSelected && !isConnected;
      } else {
        isDimmed = false;
      }

      // ── Analysis highlight glow ──
      if (isHighlighted && activeAnalysis != null) {
        final glowColor = activeAnalysis == 'bridges'
            ? _kAccentAmber
            : activeAnalysis == 'hubs'
                ? _kAccentGreen
                : _kAccentPurple;
        final glowPaint = Paint()
          ..color = glowColor.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        canvas.drawCircle(
            Offset(node.x, node.y), node.radius + 8, glowPaint);
      }

      // Glow for selected
      if (isSelected) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(
            Offset(node.x, node.y), node.radius + 6, glowPaint);
      }

      // Node fill
      final alpha = isDimmed ? 0.15 : 1.0;
      final fillPaint = Paint()
        ..color = node.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(node.x, node.y), node.radius, fillPaint);

      // MOC gold ring (always visible)
      if (node.data.type == BrainWeaveNodeType.moc) {
        final ringPaint = Paint()
          ..color = _kNodeMoc.withValues(alpha: isDimmed ? 0.2 : 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(
            Offset(node.x, node.y), node.radius + 3, ringPaint);
      }

      // Selection/hover ring
      if (isSelected || isHovered) {
        final ringPaint = Paint()
          ..color = Colors.white.withValues(alpha: isSelected ? 0.9 : 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(
            Offset(node.x, node.y), node.radius + 3, ringPaint);
      }

      // Analysis highlight ring
      if (isHighlighted && !isSelected) {
        final ringPaint = Paint()
          ..color = _kAccentPurple.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(
            Offset(node.x, node.y), node.radius + 3, ringPaint);
      }
      
      // ── Asset Icon Drawing ──
      // If the node type is 'asset' or 'research', try to draw an indicator icon
      if (node.data.type == BrainWeaveNodeType.asset || (node.data.type == BrainWeaveNodeType.atomic && node.data.topics.contains('research'))) {
         final isVideo = node.data.topics.contains('video') || (node.data.metadata != null && node.data.metadata!['assetType'] == 'video');
         final isImage = node.data.topics.contains('image') || (node.data.metadata != null && node.data.metadata!['assetType'] == 'image');
         final isPdf = node.data.topics.contains('report') || (node.data.metadata != null && node.data.metadata!['pdfUrl'] != null);
         
         String iconText = '';
         if (isVideo) iconText = '▶️';
         else if (isImage) iconText = '🖼️';
         else if (isPdf) iconText = '📄';
         
         if (iconText.isNotEmpty) {
           final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: node.radius * 0.9,
           ))
              ..pushStyle(ui.TextStyle(color: Colors.white.withValues(alpha: isDimmed ? 0.3 : 0.85)))
              ..addText(iconText);
           final paragraph = builder.build()
              ..layout(ui.ParagraphConstraints(width: node.radius * 2));
              
           canvas.drawParagraph(
              paragraph,
              Offset(node.x - node.radius, node.y - paragraph.height / 2),
           );
         }
      }

      // ── Labels ──
      // Show labels for: MOCs (always), selected, hovered, connected,
      // highlighted, or all nodes when zoomed past 1.3x
      final showLabel = node.data.type == BrainWeaveNodeType.moc ||
          isSelected ||
          isHovered ||
          isConnected ||
          isHighlighted ||
          scale >= 1.3;

      if (showLabel && !isDimmed) {
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: node.data.type == BrainWeaveNodeType.moc ? 10 : 9,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ))
          ..pushStyle(ui.TextStyle(
            color: _kTextCream.withValues(
                alpha: isSelected || isHighlighted ? 0.95 : 0.55),
          ))
          ..addText(node.data.title.length > 28
              ? '${node.data.title.substring(0, 28)}…'
              : node.data.title);
        final paragraph = builder.build()
          ..layout(const ui.ParagraphConstraints(width: 160));
        canvas.drawParagraph(
          paragraph,
          Offset(
              node.x - paragraph.width / 2, node.y + node.radius + 4),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) => true;
}
