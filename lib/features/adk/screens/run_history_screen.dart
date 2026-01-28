import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workflow_execution_provider.dart';
import '../models/workflow_execution_models.dart';
import 'package:intl/intl.dart';

class RunHistoryScreen extends ConsumerWidget {
  final String appId;

  const RunHistoryScreen({super.key, required this.appId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(workflowExecutionProvider);
    final logs = execState.lastRunLogs.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Run History', style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: logs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: logs.length,
              itemBuilder: (context, index) => _buildLogItem(context, logs[index]),
            ),
    );
  }

  Widget _buildLogItem(BuildContext context, RunLog log) {
    final dateStr = DateFormat('MMM d, HH:mm:ss').format(log.timestamp);
    final color = _getStatusColor(log.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(_getStatusIcon(log.status), color: color, size: 18),
            const SizedBox(width: 12),
            Text(log.nodeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Text(dateStr, style: const TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, left: 30),
          child: Row(
            children: [
              Text('${log.executionTimeMs}ms', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(width: 12),
              if (log.tokenUsage != null)
                Text('${log.tokenUsage} tokens', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Inputs', log.inputs),
                const SizedBox(height: 16),
                _buildSection('Outputs', log.outputs ?? {}),
                if (log.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorSection(log.errorMessage!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            data.isEmpty ? 'None' : data.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection(String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Error', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            error,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          const Text('No run logs found for this app', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Color _getStatusColor(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.success: return Colors.greenAccent;
      case ExecutionStatus.error: return Colors.redAccent;
      case ExecutionStatus.running: return Colors.blueAccent;
      default: return Colors.white24;
    }
  }

  IconData _getStatusIcon(ExecutionStatus status) {
    switch (status) {
      case ExecutionStatus.success: return Icons.check_circle;
      case ExecutionStatus.error: return Icons.error;
      case ExecutionStatus.running: return Icons.sync;
      default: return Icons.help;
    }
  }
}
