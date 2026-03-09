import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BriansThoughtsWidget extends StatelessWidget {
  final List<String> thoughts;

  const BriansThoughtsWidget({super.key, required this.thoughts});

  @override
  Widget build(BuildContext context) {
    if (thoughts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            childrenPadding: const EdgeInsets.all(16),
            leading: const FaIcon(FontAwesomeIcons.brain, size: 16, color: Colors.purpleAccent),
            title: const Text(
              "Brian's Thoughts",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            children: thoughts.map((thought) {
               // Attempt to pretty print the JSON
               String displayText = thought;
               try {
                  final decoded = jsonDecode(thought);
                  displayText = const JsonEncoder.withIndent('  ').convert(decoded);
               } catch (_) {}
               
               return Container(
                 width: double.infinity,
                 margin: const EdgeInsets.only(bottom: 8),
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.black.withValues(alpha: 0.3),
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                 ),
                 child: Text(
                   displayText,
                   style: const TextStyle(
                     fontFamily: 'monospace',
                     fontSize: 11,
                     color: Colors.cyanAccent,
                     height: 1.4,
                   ),
                 ),
               );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
