import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/web_research_service.dart';

class ResearchWorkbench extends StatelessWidget {
  const ResearchWorkbench({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: WebResearchService.statusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 'Search complete.' || snapshot.data == 'Scraping complete.') {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Research Agent Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.data!,
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const FaIcon(FontAwesomeIcons.magnifyingGlassChart, size: 16, color: Colors.white24),
            ],
          ),
        );
      },
    );
  }
}
