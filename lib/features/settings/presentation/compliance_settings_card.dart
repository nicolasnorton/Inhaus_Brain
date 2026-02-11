import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audit_log_service.dart';

class ComplianceSettingsCard extends ConsumerWidget {
  const ComplianceSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: Colors.blueAccent),
                SizedBox(width: 12),
                Text(
                  'Privacy & Compliance (LOPDP)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'In compliance with Ecuador\'s Organic Law on Personal Data Protection (LOPDP) and GDPR, you have the following rights:',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.download_for_offline_outlined, color: Colors.white54),
              title: const Text('Export My Data', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('Download a copy of all your personal data and campaign history.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: ElevatedButton(
                onPressed: () => _handleDataExport(context, ref),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.withOpacity(0.1), foregroundColor: Colors.blueAccent),
                child: const Text('Request'),
              ),
            ),
            const Divider(color: Colors.white10, height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
              title: const Text('Right to be Forgotten', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('Request deletion of your account and all associated data.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: TextButton(
                onPressed: () => _handleDataDeletionRequest(context, ref),
                child: const Text('Request Deletion', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDataExport(BuildContext context, WidgetRef ref) {
    ref.read(auditLogServiceProvider).log(
      action: 'compliance/data_export_requested',
      isCritical: true,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export request received. You will receive an email with your data package within 48 hours.'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _handleDataDeletionRequest(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete your account, campaign history, and created assets. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(auditLogServiceProvider).log(
                action: 'compliance/data_deletion_requested',
                isCritical: true,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deletion request submitted for manual review.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Request Deletion'),
          ),
        ],
      ),
    );
  }
}
