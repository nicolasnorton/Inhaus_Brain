import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CanvasContentType {
  empty,
  html,
  markdown,
  code,
  image,
  video,
  custom, // For GenUI widgets
}

class CanvasState {
  final CanvasContentType type;
  final String? content; // HTML string, Code string, Markdown string, or URL
  final Map<String, dynamic>? metadata; // For GenUI data, language for code, etc.
  final String? title;

  final bool isMobileCanvasOpen;

  const CanvasState({
    this.type = CanvasContentType.empty,
    this.content,
    this.metadata,
    this.title,
    this.isMobileCanvasOpen = false,
  });

  CanvasState copyWith({
    CanvasContentType? type,
    String? content,
    Map<String, dynamic>? metadata,
    String? title,
    bool? isMobileCanvasOpen,
  }) {
    return CanvasState(
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      title: title ?? this.title,
      isMobileCanvasOpen: isMobileCanvasOpen ?? this.isMobileCanvasOpen,
    );
  }
}

class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(const CanvasState());
  
  void toggleMobileCanvas(bool isOpen) {
    state = state.copyWith(isMobileCanvasOpen: isOpen);
  }

  void showHtml(String html, {String? title}) {
    state = CanvasState(
      type: CanvasContentType.html,
      content: html,
      title: title ?? 'Preview',
      isMobileCanvasOpen: true, // Auto-open on mobile when content is set
    );
  }

  void showCode(String code, {String language = 'dart', String? title}) {
    state = CanvasState(
      type: CanvasContentType.code,
      content: code,
      metadata: {'language': language},
      title: title ?? 'Code snippet',
      isMobileCanvasOpen: true,
    );
  }

  void showMarkdown(String markdown, {String? title}) {
    state = CanvasState(
      type: CanvasContentType.markdown,
      content: markdown,
      title: title ?? 'Document',
      isMobileCanvasOpen: true,
    );
  }

  void showImage(String url, {String? title}) {
    state = CanvasState(
      type: CanvasContentType.image,
      content: url,
      title: title ?? 'Image',
      isMobileCanvasOpen: true,
    );
  }
  
  void showGenUI(Map<String, dynamic> data, {String? title}) {
    state = CanvasState(
      type: CanvasContentType.custom,
      metadata: data,
      title: title ?? 'Interactive Component',
      isMobileCanvasOpen: true,
    );
  }

  void clear() {
    state = const CanvasState(isMobileCanvasOpen: false);
  }
}

final canvasProvider = StateNotifierProvider<CanvasNotifier, CanvasState>((ref) {
  return CanvasNotifier();
});
