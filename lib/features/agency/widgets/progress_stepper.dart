import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/task_polling_service.dart';

class ProgressStepper extends ConsumerWidget {
  final TaskProgress progress;

  const ProgressStepper({super.key, required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (progress.isCancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 12),
            Text("Campaign Generation Cancelled", style: TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStep("Research Phase", progress.researchProgress),
        const SizedBox(height: 12),
        _buildStep("Strategy Phase", progress.strategyProgress),
        const SizedBox(height: 12),
        _buildStep("Creative Generation", progress.creativeProgress),
      ],
    );
  }

  Widget _buildStep(String label, double stepProgress) {
    // stepProgress: 0.0 (pending), 0.1-0.9 (active), 1.0 (done)
    Color color;
    IconData icon;
    
    if (stepProgress >= 1.0) {
      color = Colors.greenAccent;
      icon = Icons.check_circle;
    } else if (stepProgress > 0.0) {
      color = Colors.orangeAccent;
      icon = Icons.sync; // spinning logic handled usually by animations, keep simple for now
    } else {
      color = Colors.grey.shade700;
      icon = Icons.circle_outlined;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: stepProgress > 0 ? Colors.white : Colors.grey)),
              if (stepProgress > 0 && stepProgress < 1.0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: LinearProgressIndicator(
                    value: stepProgress, 
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 2,
                  ),
                )
            ],
          ),
        )
      ],
    );
  }
}
