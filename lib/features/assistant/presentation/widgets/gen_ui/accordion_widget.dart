import 'package:flutter/material.dart';

class AccordionWidget extends StatefulWidget {
  final Map<String, dynamic> data;

  const AccordionWidget({super.key, required this.data});

  @override
  State<AccordionWidget> createState() => _AccordionWidgetState();
}

class _AccordionWidgetState extends State<AccordionWidget> {
  final List<bool> _isExpanded = [];

  @override
  void initState() {
    super.initState();
    final items = widget.data['items'] as List<dynamic>? ?? [];
    _isExpanded.addAll(List.generate(items.length, (index) => false));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] ?? 'Summary';
    final items = widget.data['items'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D333B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: ExpansionTile(
                  title: Text(item['title'] ?? 'Section', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  iconColor: Colors.blueAccent,
                  collapsedIconColor: Colors.white54,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(item['content'] ?? '', style: const TextStyle(color: Colors.white70, height: 1.5)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
