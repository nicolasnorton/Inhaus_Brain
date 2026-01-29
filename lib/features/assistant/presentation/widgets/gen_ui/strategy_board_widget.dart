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
    final pillars = List<Map<String, dynamic>>.from(data['pillars'] ?? []);

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF14181F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (objectives.isNotEmpty) ...[
            const Text("CORE OBJECTIVES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ...objectives.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(o, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                ],
              ),
            )),
            const SizedBox(height: 24),
          ],

          if (pillars.isNotEmpty) ...[
             const Text("STRATEGIC PILLARS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1.2)),
             const SizedBox(height: 12),
             SingleChildScrollView(
               scrollDirection: Axis.horizontal,
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: pillars.map((p) => _buildPillarCard(p)).toList(),
               ),
             ),
             const SizedBox(height: 24),
          ],

          if (milestones.isNotEmpty) ...[
            const Text("ROADMAP MILESTONES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ...milestones.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(m['date'] ?? '', style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white10,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(m['label'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildPillarCard(Map<String, dynamic> pillar) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pillar['title'] ?? 'Pillar',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            pillar['description'] ?? '',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.4),
          ),
          if (pillar['kpis'] != null) ...[
            const SizedBox(height: 12),
            ...List<String>.from(pillar['kpis']).map((kpi) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                   const Icon(Icons.analytics_outlined, size: 12, color: Colors.blueAccent),
                   const SizedBox(width: 6),
                   Expanded(child: Text(kpi, style: const TextStyle(color: Colors.white38, fontSize: 11))),
                ],
              ),
            )),
          ]
        ],
      ),
    );
  }
}
