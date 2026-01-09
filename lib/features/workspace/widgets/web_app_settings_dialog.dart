import 'package:flutter/material.dart';

/// Web app settings dialog
class WebAppSettingsDialog extends StatelessWidget {
  const WebAppSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Web App Settings'),
      content: const SizedBox(
        width: 500,
        child: Text('Web app settings configuration coming soon...'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
