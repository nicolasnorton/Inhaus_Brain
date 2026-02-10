import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class MindMapWidget extends StatefulWidget {
  final Map<String, dynamic> data;

  const MindMapWidget({super.key, required this.data});

  @override
  State<MindMapWidget> createState() => _MindMapWidgetState();
}

class _MindMapWidgetState extends State<MindMapWidget> {
  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  void initState() {
    super.initState();
    _buildGraph();
    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  void _buildGraph() {
    final nodesJson = widget.data['nodes'] as List<dynamic>? ?? [];
    final edgesJson = widget.data['edges'] as List<dynamic>? ?? [];

    final Map<int, Node> nodeMap = {};

    for (var n in nodesJson) {
      final id = n['id'] as int;
      final node = Node.Id(id);
      nodeMap[id] = node;
      graph.addNode(node);
    }

    for (var e in edgesJson) {
      final source = nodeMap[e['source']];
      final target = nodeMap[e['target']];
      if (source != null && target != null) {
        graph.addEdge(source, target);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (graph.nodeCount() == 0) return const SizedBox.shrink();

    return Container(
      height: 400,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.data['title'] ?? 'Mind Map', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 12),
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.01,
              maxScale: 5.6,
              child: GraphView(
                graph: graph,
                algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
                paint: Paint()
                  ..color = Colors.white24
                  ..strokeWidth = 1
                  ..style = PaintingStyle.stroke,
                builder: (Node node) {
                  final id = node.key?.value as int?;
                  final nodeData = (widget.data['nodes'] as List).firstWhere((element) => element['id'] == id, orElse: () => {});
                  final label = nodeData['label'] ?? 'Node $id';
                  final colorHex = nodeData['color'];
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _parseColor(colorHex) ?? const Color(0xFF2D333B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    if (hex.startsWith('#')) {
      try {
        return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {}
    }
    return null;
  }
}
