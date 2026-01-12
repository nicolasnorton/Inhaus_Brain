import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/globals.dart';

class MCPServerConfigDialog extends StatefulWidget {
  final String appId;
  final String appName;

  const MCPServerConfigDialog({super.key, required this.appId, required this.appName});

  @override
  State<MCPServerConfigDialog> createState() => _MCPServerConfigDialogState();
}

class _MCPServerConfigDialogState extends State<MCPServerConfigDialog> {
  bool _isEnabled = false;
  String _accessToken = 'sk_mcp_live_482910384';
  int _port = 3000;

  @override
  Widget build(BuildContext context) {
    final configSnippet = '''
{
  "mcpServers": {
    "${widget.appName.toLowerCase().replaceAll(' ', '_')}": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-inhaus", "--app-id", "${widget.appId}"],
      "env": {
        "INHAUS_API_KEY": "$_accessToken"
      }
    }
  }
}''';

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Row(
        children: [
          const Icon(Icons.dns, color: Colors.tealAccent),
          const SizedBox(width: 12),
          Text('MCP Server: ${widget.appName}', style: const TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchTile(
                'Enable MCP Interface',
                'Expose this workflow as an MCP tool for Claude/IDE',
                _isEnabled,
                (val) => setState(() => _isEnabled = val),
              ),
              const SizedBox(height: 24),
              const Text('DEPLOYMENT CONFIGURATION', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildConfigField('Server Port (Local)', _port.toString(), (val) => setState(() => _port = int.tryParse(val) ?? 3000)),
              _buildConfigField('Access Token', _accessToken, (val) => setState(() => _accessToken = val), isSecret: true),
              const SizedBox(height: 24),
              const Text('CLAUDE DESKTOP CONFIG', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildCodeSnippet(configSnippet),
              const SizedBox(height: 12),
              const Text('Add this snippet to your claude_desktop_config.json to use this tool locally.', 
                  style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
             Navigator.pop(context);
             scaffoldMessengerKey.currentState?.showSnackBar(
               const SnackBar(content: Text('MCP Server configuration updated!')),
             );
          },
          child: const Text('Update Server'),
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
        Switch(value: value, onChanged: onChanged, activeColor: Colors.tealAccent),
      ],
    );
  }

  Widget _buildConfigField(String label, String value, Function(String) onChanged, {bool isSecret = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        onChanged: onChanged,
        obscureText: isSecret,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildCodeSnippet(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          Text(
            code,
            style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.copy, size: 16, color: Colors.white38),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Copied Configuration')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
