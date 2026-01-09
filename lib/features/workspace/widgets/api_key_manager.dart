import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// API key manager dialog
class APIKeyManager extends StatelessWidget {
  final String appId;

  const APIKeyManager({
    super.key,
    required this.appId,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('API Key Manager'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage your API keys for backend service access.'),
            const SizedBox(height: 20),
            _buildAPIKeyItem(context, 'app-xxx-1234567890'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Generate new API key
              },
              icon: const Icon(Icons.add),
              label: const Text('Generate New Key'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildAPIKeyItem(BuildContext context, String key) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API key copied')),
              );
            },
            tooltip: 'Copy key',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: () {
              // TODO: Revoke key
            },
            tooltip: 'Revoke key',
          ),
        ],
      ),
    );
  }
}
