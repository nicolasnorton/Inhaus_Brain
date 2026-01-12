import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monitor_models.dart';
import '../providers/monitor_provider.dart';
import '../widgets/annotation_dialog.dart';

class LogsScreen extends ConsumerWidget {
  final String appId;

  const LogsScreen({super.key, required this.appId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(appLogsProvider(appId));
    final search = ref.watch(logSearchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1116),
        elevation: 0,
        title: const Text('Execution Logs', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white70),
            onPressed: () {
              // TODO: Implement export
            },
            tooltip: 'Export Logs',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, ref, search),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: logsAsync.when(
              data: (logs) => _buildLogsTable(context, ref, logs),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, LogSearchState search) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => ref.read(logSearchProvider.notifier).state = search.copyWith(query: val),
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1C2128),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          _buildLevelFilter(ref, search),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.date_range, size: 16),
            label: const Text('Custom Range'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelFilter(WidgetRef ref, LogSearchState search) {
    return PopupMenuButton<LogLevel?>(
      initialValue: search.level,
      onSelected: (val) => ref.read(logSearchProvider.notifier).state = search.copyWith(level: val, clearLevel: val == null),
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('All Levels')),
        const PopupMenuItem(value: LogLevel.info, child: Text('Info')),
        const PopupMenuItem(value: LogLevel.warning, child: Text('Warning')),
        const PopupMenuItem(value: LogLevel.error, child: Text('Error')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Text(search.level?.displayName ?? 'All Levels', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.filter_list, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTable(BuildContext context, WidgetRef ref, List<LogEntry> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.white10),
            SizedBox(height: 16),
            Text('No logs found matching your filters', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
      itemBuilder: (context, index) {
        final log = logs[index];
        return InkWell(
          onTap: () => _showLogDetails(context, log),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: log.level.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.level.displayName,
                    style: TextStyle(color: log.level.color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    log.message,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  log.traceId ?? '',
                  style: const TextStyle(color: Colors.white10, fontSize: 11, fontFamily: 'monospace'),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.rate_review_outlined, size: 18, color: Colors.white24),
                  onPressed: () => _showAnnotationDialog(context, log),
                  tooltip: 'Add Annotation',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogDetails(BuildContext context, LogEntry log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Log Details', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(log.traceId ?? '', style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontFamily: 'monospace')),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Timestamp', log.timestamp.toIso8601String()),
            _buildDetailRow('Level', log.level.displayName),
            _buildDetailRow('Message', log.message),
            if (log.metadata != null) ...[
              const SizedBox(height: 16),
              const Text('Metadata', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  log.metadata.toString(),
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  void _showAnnotationDialog(BuildContext context, LogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AnnotationDialog(log: log),
    );
  }
}
