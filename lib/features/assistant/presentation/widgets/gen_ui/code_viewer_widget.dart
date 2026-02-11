import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeViewerWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const CodeViewerWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Extract data with safe fallbacks
    final String language = (data['language'] as String?)?.toLowerCase() ?? 'text';
    final String rawCode = data['code'] ?? '// No code provided';
    final String title = data['title'] ?? 'Code Snippet';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // VS Code like background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF2D2D2D), // Slightly lighter header
            child: Row(
              children: [
                Icon(_getIconForLanguage(language), size: 16, color: _getColorForLanguage(language)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto', 
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    language.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.content_copy, size: 14, color: Colors.white54),
                    tooltip: 'Copy Code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: rawCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          width: 200, 
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Code Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                rawCode,
                style: const TextStyle(
                  fontFamily: 'monospace', // Or specific monospaced font if available
                  fontSize: 13,
                  color: Color(0xFFD4D4D4), // VS Code default text color
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForLanguage(String language) {
    switch (language) {
      case 'dart': return Icons.flutter_dash;
      case 'python': return Icons.code; 
      case 'javascript':
      case 'js': return Icons.javascript;
      case 'html': return Icons.html;
      case 'css': return Icons.css;
      case 'json': return Icons.data_object;
      case 'sql': return Icons.storage;
      case 'bash':
      case 'sh': return Icons.terminal;
      default: return Icons.code;
    }
  }

  Color _getColorForLanguage(String language) {
    switch (language) {
      case 'dart': return Colors.blueAccent;
      case 'python': return Colors.yellow; 
      case 'javascript':
      case 'js': return Colors.amber;
      case 'html': return Colors.orange;
      case 'css': return Colors.blue;
      case 'json': return Colors.greenAccent;
      case 'sql': return Colors.purpleAccent;
      case 'bash':
      case 'sh': return Colors.grey;
      default: return Colors.white54;
    }
  }
}
