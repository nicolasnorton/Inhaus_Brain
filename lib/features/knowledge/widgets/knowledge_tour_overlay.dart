import 'package:flutter/material.dart';

class KnowledgeTourOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const KnowledgeTourOverlay({super.key, required this.onDismiss});

  @override
  State<KnowledgeTourOverlay> createState() => _KnowledgeTourOverlayState();
}

class _KnowledgeTourOverlayState extends State<KnowledgeTourOverlay> {
  int _currentStep = 0;
  final List<TourStep> _steps = [
    TourStep(
      title: 'Welcome to Knowledge Hub',
      description: 'Centralize your agency intelligence here. Connect documents, websites, and ad platforms.',
      targetAlign: Alignment.center,
    ),
    TourStep(
      title: 'Quick Create',
      description: 'Use the Quick Create flow to transform a single file into a searchable Knowledge Base in seconds.',
      targetAlign: Alignment.topLeft,
    ),
    TourStep(
      title: 'Retrieval Sandbox',
      description: 'Test how your AI agents see the data. Tune top-k and reranking parameters for better accuracy.',
      targetAlign: Alignment.bottomRight,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2128),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)),
                        child: Text('${_currentStep + 1} / ${_steps.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      IconButton(onPressed: widget.onDismiss, icon: const Icon(Icons.close, color: Colors.white38, size: 18)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(step.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(step.description, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: () => setState(() => _currentStep--),
                          child: const Text('Previous', style: TextStyle(color: Colors.white38)),
                        ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentStep < _steps.length - 1) {
                            setState(() => _currentStep++);
                          } else {
                            widget.onDismiss();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        child: Text(_currentStep < _steps.length - 1 ? 'Next' : 'Finish'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TourStep {
  final String title;
  final String description;
  final Alignment targetAlign;

  TourStep({required this.title, required this.description, required this.targetAlign});
}
