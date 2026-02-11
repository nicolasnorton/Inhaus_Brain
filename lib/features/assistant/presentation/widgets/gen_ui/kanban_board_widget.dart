import 'package:flutter/material.dart';

class KanbanBoardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const KanbanBoardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Kanban Board';
    final columns = List<Map<String, dynamic>>.from(data['columns'] ?? []);

    return Container(
      width: double.infinity,
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
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columns.map((col) {
                final colTitle = col['title'] ?? 'Column';
                final cardsRaw = col['cards'] as List?;
                final cards = cardsRaw?.map((card) {
                  if (card is String) return card;
                  if (card is Map) return card['title']?.toString() ?? card['content']?.toString() ?? card['description']?.toString() ?? card.toString();
                  return card.toString();
                }).toList() ?? [];
                
                final color = _getColumnColor(colTitle);

                return Container(
                  width: 250, // Slightly wider for better readability
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(colTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13))),
                          if (cards.isNotEmpty)
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                               child: Text('${cards.length}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                             )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: cards.length,
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D333B),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                                ],
                                border: Border.all(color: Colors.white.withOpacity(0.05))
                              ),
                              child: Text(card, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColumnColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('todo') || t.contains('to do')) return Colors.blueAccent;
    if (t.contains('progress') || t.contains('doing')) return Colors.orangeAccent;
    if (t.contains('done') || t.contains('complete')) return Colors.greenAccent;
    if (t.contains('review')) return Colors.purpleAccent;
    return Colors.grey;
  }
}
