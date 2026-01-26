import 'package:flutter/material.dart';
import 'package:ag_ui/ag_ui.dart';

class StrategyBoardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const StrategyBoardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Strategic Plan';
    final objectives = List<String>.from(data['objectives'] ?? []);
    final milestones = List<Map<String, dynamic>>.from(data['milestones'] ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128), // Dark surface
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          if (objectives.isNotEmpty) ...[
            const Text("Objectives", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
            const SizedBox(height: 8),
            ...objectives.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(o, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],
          if (milestones.isNotEmpty) ...[
            const Text("Milestones", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
            const SizedBox(height: 8),
            ...milestones.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(m['date'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(m['label'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
