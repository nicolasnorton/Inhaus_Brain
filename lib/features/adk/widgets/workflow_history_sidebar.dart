import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/version_control_service.dart';
import '../../../core/models/version_control_models.dart';
import 'package:intl/intl.dart';

class WorkflowHistorySidebar extends ConsumerWidget {
  final String appId;
  final VoidCallback onClose;
  final Function(WorkflowCommit) onRollback;

  const WorkflowHistorySidebar({
    super.key,
    required this.appId,
    required this.onClose,
    required this.onRollback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(versionControlProvider).where((c) => c.appId == appId).toList();
    final theme = Theme.of(context);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(left: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: history.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) => _buildCommitItem(context, history[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 12),
          const Text(
            'Version History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white38),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildCommitItem(BuildContext context, WorkflowCommit commit) {
    final dateStr = DateFormat('MMM d, HH:mm').format(commit.timestamp);

    return InkWell(
      onTap: () => onRollback(commit),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                  child: Text(commit.author[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                ),
                const SizedBox(width: 8),
                Text(commit.author, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              commit.message,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    commit.id.substring(0, 8),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.white38),
                  ),
                ),
                const Spacer(),
                const Text('Restore', style: TextStyle(fontSize: 11, color: Colors.blueAccent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          Text('No versions yet', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}
