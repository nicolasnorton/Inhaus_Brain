import 'package:flutter/material.dart';

class RecipeCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const RecipeCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Process Instructions';
    final duration = data['duration'] ?? '';
    final difficulty = data['difficulty'] ?? '';
    final ingredients = List<String>.from(data['ingredients'] ?? []);
    final steps = List<Map<String, dynamic>>.from(data['steps'] ?? []);

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.orangeAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (duration.isNotEmpty || difficulty.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (duration.isNotEmpty) ...[
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(duration, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 16),
                ],
                if (difficulty.isNotEmpty) ...[
                  const Icon(Icons.speed_outlined, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(difficulty, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (ingredients.isNotEmpty) ...[
            const Text("REQUIREMENTS / INGREDIENTS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orangeAccent, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: ingredients.map((item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Text(item, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (steps.isNotEmpty) ...[
            const Text("STEPS / EXECUTION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orangeAccent, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          "${idx + 1}",
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (step['title'] != null)
                            Text(
                              step['title'],
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            step['description'] ?? '',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
