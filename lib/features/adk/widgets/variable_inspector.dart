import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workflow_execution_provider.dart';

class VariableInspector extends ConsumerWidget {
  const VariableInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(workflowExecutionProvider);
    final variables = execState.cachedVariables;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.troubleshoot, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 8),
          const Text('Variables', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const VerticalDivider(color: Colors.white10, indent: 8, endIndent: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: variables.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final key = variables.keys.elementAt(index);
                final value = variables[key];
                return _buildVariableChip(key, value);
              },
            ),
          ),
          if (variables.isEmpty)
            const Text('No variables cached yet', style: TextStyle(fontSize: 11, color: Colors.white24)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => ref.read(workflowExecutionProvider.notifier).clear(),
            icon: const Icon(Icons.clear_all, size: 14),
            label: const Text('Clear', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableChip(String key, dynamic value) {
    String typeStr = value.runtimeType.toString();
    String valueStr = value.toString();
    if (value is Map || value is List) {
       valueStr = '{...}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            key,
            style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.w500),
          ),
          const Text(' = ', style: TextStyle(fontSize: 11, color: Colors.white24)),
          Text(
            valueStr,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
