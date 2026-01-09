import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Embed code generator dialog
class EmbedCodeGenerator extends StatefulWidget {
  const EmbedCodeGenerator({super.key});

  @override
  State<EmbedCodeGenerator> createState() => _EmbedCodeGeneratorState();
}

class _EmbedCodeGeneratorState extends State<EmbedCodeGenerator> {
  String _embedType = 'chatWidget';
  String _position = 'bottomRight';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Embed on Website'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Embed Type'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRadioOption('Chat Widget', 'chatWidget'),
                const SizedBox(width: 20),
                _buildRadioOption('Inline Frame', 'iframe'),
              ],
            ),
            if (_embedType == 'chatWidget') ...[
              const SizedBox(height: 20),
              const Text('Widget Position'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _position,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'bottomRight',
                    child: Text('Bottom Right'),
                  ),
                  DropdownMenuItem(
                    value: 'bottomLeft',
                    child: Text('Bottom Left'),
                  ),
                  DropdownMenuItem(
                    value: 'topRight',
                    child: Text('Top Right'),
                  ),
                  DropdownMenuItem(
                    value: 'topLeft',
                    child: Text('Top Left'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _position = value);
                  }
                },
              ),
            ],
            const SizedBox(height: 20),
            const Text('Embed Code'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _generateEmbedCode(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _generateEmbedCode()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Embed code copied to clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Code'),
                  ),
                ],
              ),
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

  Widget _buildRadioOption(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _embedType,
          onChanged: (val) {
            if (val != null) {
              setState(() => _embedType = val);
            }
          },
        ),
        Text(label),
      ],
    );
  }

  String _generateEmbedCode() {
    if (_embedType == 'chatWidget') {
      return '''
<script>
  window.difyChatbotConfig = {
    token: 'YOUR_TOKEN',
    containerProps: {
      style: {
        ${_position.contains('Right') ? 'right' : 'left'}: '20px',
        ${_position.contains('bottom') ? 'bottom' : 'top'}: '20px'
      }
    }
  }
</script>
<script src="https://udify.app/embed.min.js" defer></script>
''';
    } else {
      return '''
<iframe 
  src="https://udify.app/chatbot/YOUR_APP_TOKEN"
  width="100%" 
  height="600"
  frameborder="0">
</iframe>
''';
    }
  }
}
