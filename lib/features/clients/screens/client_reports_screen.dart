import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:inhaus_brain/features/reports/models/report_model.dart';
import 'package:inhaus_brain/features/reports/providers/reports_provider.dart';

class ClientReportsScreen extends ConsumerWidget {
  final String clientId;

  const ClientReportsScreen({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(clientReportsProvider(clientId));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateReportDialog(context, ref),
        label: const Text('New Report'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.purpleAccent,
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined, size: 48, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('No reports generated yet.', style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportCard(report: report);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  void _showCreateReportDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2128),
        title: const Text('New Report', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Report Title',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                final newReport = Report(
                  id: const Uuid().v4(),
                  clientId: clientId,
                  // userId: 'user-1', // Removed
                  title: titleController.text.trim(),
                  // status: ReportStatus.draft, // Removed
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  sources: [],
                  // sections: [], // Removed
                );

                await ref.read(reportsServiceProvider).createReport(newReport);
                if (context.mounted) {
                  Navigator.pop(context);
                  context.push('/reports/${newReport.id}');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.analytics, color: Colors.purpleAccent),
        ),
        title: Text(
          report.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Generated on ${DateFormat.yMMMd().format(report.createdAt)}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {
          context.push('/reports/${report.id}');
        },
      ),
    );
  }
}
