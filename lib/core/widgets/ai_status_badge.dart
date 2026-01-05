import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/edge_ai_service.dart';

class AIStatusBadge extends ConsumerWidget {
  const AIStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proximity = ref.watch(aiProximityProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColor(proximity).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getColor(proximity).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(proximity), size: 14, color: _getColor(proximity)),
          const SizedBox(width: 6),
          Text(
            _getLabel(proximity),
            style: TextStyle(
              color: _getColor(proximity),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(AIProximity proximity) {
    switch (proximity) {
      case AIProximity.local:
        return Colors.greenAccent;
      case AIProximity.cloud:
        return Colors.blueAccent;
      case AIProximity.simulated:
        return Colors.purpleAccent;
    }
  }

  IconData _getIcon(AIProximity proximity) {
    switch (proximity) {
      case AIProximity.local:
        return Icons.memory;
      case AIProximity.cloud:
        return Icons.cloud_queue;
      case AIProximity.simulated:
        return Icons.auto_awesome;
    }
  }

  String _getLabel(AIProximity proximity) {
    switch (proximity) {
      case AIProximity.local:
        return 'ON-DEVICE AI';
      case AIProximity.cloud:
        return 'CLOUD AI';
      case AIProximity.simulated:
        return 'EDGE AGENT';
    }
  }
}
