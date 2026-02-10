import 'package:flutter/material.dart';

class WordCloudWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const WordCloudWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Keywords';
    final List<dynamic> words = data['words'] ?? []; // list of {text, weight/value}

    // Sort by weight if possible
    final sortedWords = List.from(words);
    sortedWords.sort((a, b) => ((b['value'] ?? 0) as num).compareTo((a['value'] ?? 0) as num));

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: sortedWords.map<Widget>((w) {
                final text = w['text'] ?? '';
                final double value = (w['value'] ?? 1).toDouble();
                // Map value 1-100 to font size 12-48
                final fontSize = 12.0 + (value / 100.0 * 36.0).clamp(0, 36);
                final opacity = 0.4 + (value / 100.0 * 0.6).clamp(0, 0.6);
                
                return Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: _getColor(value).withOpacity(opacity),
                    fontWeight: value > 50 ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(double value) {
    if (value > 80) return Colors.redAccent;
    if (value > 60) return Colors.orangeAccent;
    if (value > 40) return Colors.amberAccent;
    if (value > 20) return Colors.blueAccent;
    return Colors.cyanAccent;
  }
}
