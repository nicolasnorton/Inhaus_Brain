import 'package:flutter/material.dart';
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
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E1E1E));
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
    return WebViewWidget(controller: _controller);
  }
}
