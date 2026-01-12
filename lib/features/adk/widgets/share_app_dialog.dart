import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ShareAppDialog extends StatefulWidget {
  final String appId;
  final String appName;

  const ShareAppDialog({super.key, required this.appId, required this.appName});

  @override
  State<ShareAppDialog> createState() => _ShareAppDialogState();
}

class _ShareAppDialogState extends State<ShareAppDialog> {
  bool _isPublic = false;
  bool _showWatermark = true;
  String _theme = 'Dark';

  @override
  Widget build(BuildContext context) {
    final shareUrl = 'https://brain.inhaus.ai/share/${widget.appId}';
    final embedCode = '<iframe src="$shareUrl" width="100%" height="600" frameborder="0"></iframe>';

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Row(
        children: [
          const Icon(Icons.rocket_launch, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text('Publish "${widget.appName}"', style: const TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchTile(
                'Public Access',
                'Anyone with the link can use this app',
                _isPublic,
                (val) => setState(() => _isPublic = val),
              ),
              const Divider(color: Colors.white10, height: 32),
              const Text('CONFIGURATIONS', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildThemeSelector(),
              _buildSwitchTile(
                'Show Watermark',
                'Inhaus Brain branding in footer',
                _showWatermark,
                (val) => setState(() => _showWatermark = val),
              ),
              const SizedBox(height: 24),
              const Text('SHARE LINK', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildCopyField(shareUrl),
              const SizedBox(height: 24),
              const Text('EMBED CODE', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildCopyField(embedCode, isLong: true),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            // Save publish settings logic
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Publish settings saved!')),
            );
          },
          child: const Text('Save Settings'),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: Colors.blueAccent),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Expanded(child: Text('App Theme', style: TextStyle(color: Colors.white))),
          DropdownButton<String>(
            value: _theme,
            dropdownColor: const Color(0xFF252525),
            style: const TextStyle(color: Colors.white),
            underline: Container(height: 1, color: Colors.white10),
            items: ['Light', 'Dark', 'Custom'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (val) => setState(() => _theme = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyField(String text, {bool isLong = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
              maxLines: isLong ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: Colors.blueAccent),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
    );
  }
}
