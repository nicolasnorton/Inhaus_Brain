import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DialogueSceneWidget extends StatefulWidget {
  final String? initialUrl;
  final String? htmlContent;

  const DialogueSceneWidget({
    super.key,
    this.initialUrl,
    this.htmlContent,
  });

  @override
  State<DialogueSceneWidget> createState() => _DialogueSceneWidgetState();
}

class _DialogueSceneWidgetState extends State<DialogueSceneWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
    
    if (widget.initialUrl != null) {
      _controller.loadRequest(Uri.parse(widget.initialUrl!));
    } else if (widget.htmlContent != null) {
      _controller.loadHtmlString(widget.htmlContent!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _controller),
    );
  }
}
