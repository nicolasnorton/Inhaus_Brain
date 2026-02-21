import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../../core/mcp/tools/stitch_tools.dart';
import '../../../../../core/services/stitch_service.dart';

class StitchCodeExportWidget extends ConsumerWidget {
  final Map<String, dynamic> data;
  final Function(String, Map<String, dynamic>)? onAction;

  const StitchCodeExportWidget({
    super.key, 
    required this.data, 
    this.onAction
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = data['code'] as String? ?? '// No code available';
    final language = data['language'] as String? ?? 'html';
    final filename = data['filename'] as String? ?? 'screen.html';
    final projectId = data['project_id'] as String?;
    final screenId = data['screen_id'] as String?;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E1E1E), // VS Code Dark bg
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF252526),
            child: Row(
              children: [
                const Icon(Icons.code, size: 16, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  filename,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                  tooltip: 'Copy Code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, size: 16, color: Colors.white54),
                  tooltip: 'Download',
                  onPressed: () {
                    // Actual file download handling would go here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download not implemented yet')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Code Area
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFFD4D4D4), // VS Code default text color
                  height: 1.4,
                ),
              ),
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF252526),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                     if (projectId != null && screenId != null) {
                       onAction?.call('apply_to_blackboard', {
                         'project_id': projectId,
                         'screen_id': screenId,
                         'code': code
                       });
                     }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Apply to Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
