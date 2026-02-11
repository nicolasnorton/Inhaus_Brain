import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MonacoEditorWidget extends StatefulWidget {
  final String code;
  final String language;

  const MonacoEditorWidget({
    super.key,
    required this.code,
    this.language = 'javascript',
  });

  @override
  State<MonacoEditorWidget> createState() => _MonacoEditorWidgetState();
}

class _MonacoEditorWidgetState extends State<MonacoEditorWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
      
    // specific platform Tweaks if needed, but keep it simple for web
    // Background color might not be supported on all web implementations or requires different handling
    // _controller.setBackgroundColor(const Color(0xFF1E1E1E)); 
    
    _loadMonaco();
  }

  @override
  void didUpdateWidget(MonacoEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code || oldWidget.language != widget.language) {
      _loadMonaco();
    }
  }

  void _loadMonaco() {
    final escapedCode = widget.code.replaceAll("'", "\\'").replaceAll("\n", "\\n").replaceAll("\r", "");
    final html = """
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
    <style type="text/css">
        html, body, #container {
            width: 100%;
            height: 100%;
            margin: 0;
            padding: 0;
            overflow: hidden;
            background-color: #1E1E1E;
        }
    </style>
</head>
<body>
<div id="container"></div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.44.0/min/vs/loader.min.js"></script>
<script>
    require.config({ paths: { 'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.44.0/min/vs' }});
    require(['vs/editor/editor.main'], function() {
        var editor = monaco.editor.create(document.getElementById('container'), {
            value: '$escapedCode',
            language: '${widget.language}',
            theme: 'vs-dark',
            automaticLayout: true,
            fontSize: 14,
            minimap: { enabled: false },
            readOnly: true,
            scrollBeyondLastLine: false,
        });
    });
</script>
</body>
</html>
""";
    _controller.loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        Positioned(
          top: 10,
          right: 10,
          child: FloatingActionButton.small(
            backgroundColor: Colors.blueAccent.withOpacity(0.8),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied to clipboard!'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  width: 200,
                ),
              );
            },
            child: const Icon(Icons.copy, size: 18, color: Colors.white),
            tooltip: 'Copy Code',
          ),
        ),
      ],
    );
  }
}
