import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../../services/avatar_service.dart';

class DialogueSceneWidget extends ConsumerStatefulWidget {
  final String? initialUrl;
  final String? htmlContent;
  final Map<String, dynamic> data;

  const DialogueSceneWidget({
    super.key,
    this.initialUrl,
    this.htmlContent,
    this.data = const {},
  });

  @override
  ConsumerState<DialogueSceneWidget> createState() => _DialogueSceneWidgetState();
}

class _DialogueSceneWidgetState extends ConsumerState<DialogueSceneWidget> {
  late final WebViewController _controller;
  String? _lastHtml;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
    
    _loadContent();
  }

  @override
  void didUpdateWidget(DialogueSceneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _loadContent();
    }
  }

  void _loadContent() {
    final payload = widget.data;
    final initialUrl = widget.initialUrl ?? payload['initial_url'];
    
    if (initialUrl != null) {
      _controller.loadRequest(Uri.parse(initialUrl));
      return;
    }

    final htmlContent = widget.htmlContent ?? payload['html_content'] ?? payload['content'];
    if (htmlContent != null) {
      _controller.loadHtmlString(htmlContent);
      return;
    }

    // Generate HTML using AvatarService if personas are provided
    if (payload['personas'] != null) {
      final avatarService = ref.read(avatarServiceProvider);
      final html = avatarService.getDialogueSceneHtml(
        personas: List<Map<String, dynamic>>.from(payload['personas']),
        initialMessage: payload['text'] ?? payload['message'] ?? '...',
        environmentId: payload['environment_id'] ?? 'office',
        cameraAnchor: payload['camera_anchor'] ?? 'default',
      );
      
      if (html != _lastHtml) {
        _lastHtml = html;
        _controller.loadHtmlString(html);
      }
    }
  }

  void _handleCommand(Map<String, dynamic> command) {
    final action = command['action'];
    final params = command['params'] ?? {};

    switch (action) {
      case 'set_speaker':
        if (params['speaker_id'] != null) {
          _controller.runJavaScript('window.setActiveSpeaker("${params['speaker_id']}");');
        }
        break;
      case 'set_camera':
        if (params['anchor'] != null) {
          _controller.runJavaScript('window.setCameraAnchor("${params['anchor']}");');
        }
        break;
      case 'trigger_gesture':
        if (params['speaker_id'] != null && params['gesture'] != null) {
          _controller.runJavaScript('window.setGesture("${params['speaker_id']}", "${params['gesture']}");');
        }
        break;
      case 'set_text':
        if (params['text'] != null) {
          _controller.runJavaScript('window.setDialogueText("${params['text']}");');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for real-time commands
    // dialogueSceneCommandProvider removed for stability in production build for now or until defined

    return Container(
      height: 400, // Fixed height for dialogue scenes
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _controller),
    );
  }
}
