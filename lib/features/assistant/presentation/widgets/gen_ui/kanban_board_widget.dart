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
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns.map((col) {
                  final colTitle = col['title'] ?? 'Column';
                  final cardsRaw = col['cards'] as List?;
                  final cards = cardsRaw?.map((card) {
                    if (card is String) return {'title': card, 'description': null, 'tag': null, 'priority': null};
                    if (card is Map) {
                      return {
                        'title': card['title']?.toString() ?? card['content']?.toString() ?? card['description']?.toString() ?? card.toString(),
                        'description': card['description']?.toString(),
                        'tag': card['tag']?.toString() ?? card['label']?.toString(),
                        'priority': card['priority']?.toString(),
                      };
                    }
                    return {'title': card.toString(), 'description': null, 'tag': null, 'priority': null};
                  }).toList() ?? [];
                  
                  final color = _getColumnColor(colTitle);

                  return Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Column Header
                        Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              colTitle, 
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13, letterSpacing: 0.3),
                            )),
                            if (cards.isNotEmpty)
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                 decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                 child: Text('${cards.length}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                               )
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Cards — use simple Column with mainAxisSize.min instead of Expanded + ListView
                        ...cards.map((cardData) {
                          return _buildCard(cardData, color);
                        }),
                        if (cards.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withOpacity(0.03), style: BorderStyle.solid),
                            ),
                            child: const Text('No items', style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> cardData, Color columnColor) {
    final title = cardData['title'] ?? '';
    final description = cardData['description'];
    final tag = cardData['tag'];
    final priority = cardData['priority'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D333B),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (tag != null || priority != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: columnColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tag, style: TextStyle(fontSize: 10, color: columnColor, fontWeight: FontWeight.w600)),
                  ),
                if (priority != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(priority, style: TextStyle(fontSize: 10, color: _getPriorityColor(priority), fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    final p = priority.toLowerCase();
    if (p.contains('high') || p.contains('urgent') || p.contains('critical')) return Colors.redAccent;
    if (p.contains('medium') || p.contains('normal')) return Colors.orangeAccent;
    if (p.contains('low')) return Colors.greenAccent;
    return Colors.blueGrey;
  }

  Color _getColumnColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('todo') || t.contains('to do') || t.contains('backlog')) return Colors.blueAccent;
    if (t.contains('progress') || t.contains('doing') || t.contains('active')) return Colors.orangeAccent;
    if (t.contains('done') || t.contains('complete') || t.contains('finished')) return Colors.greenAccent;
    if (t.contains('review') || t.contains('testing') || t.contains('qa')) return Colors.purpleAccent;
    if (t.contains('block') || t.contains('stuck')) return Colors.redAccent;
    return Colors.grey;
  }
}
