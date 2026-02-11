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
  final bool isPinned;
  final List<CanvasState> pinnedItems;

  const CanvasState({
    this.type = CanvasContentType.empty,
    this.content,
    this.metadata,
    this.title,
    this.isMobileCanvasOpen = false,
    this.isPinned = false,
    this.pinnedItems = const [],
  });

  CanvasState copyWith({
    CanvasContentType? type,
    String? content,
    Map<String, dynamic>? metadata,
    String? title,
    bool? isMobileCanvasOpen,
    bool? isPinned,
    List<CanvasState>? pinnedItems,
  }) {
    return CanvasState(
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      title: title ?? this.title,
      isMobileCanvasOpen: isMobileCanvasOpen ?? this.isMobileCanvasOpen,
      isPinned: isPinned ?? this.isPinned,
      pinnedItems: pinnedItems ?? this.pinnedItems,
    );
  }
}

class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(const CanvasState());
  
  void toggleMobileCanvas(bool isOpen) {
    state = state.copyWith(isMobileCanvasOpen: isOpen);
  }

  void togglePin() {
    final newPinned = !state.isPinned;
    List<CanvasState> newPinnedItems = List.from(state.pinnedItems);
    
    if (newPinned) {
      // Add current state (without pinnedItems list to avoid recursion/bloat) to pinnedItems
      final itemToPin = CanvasState(
        type: state.type,
        content: state.content,
        metadata: state.metadata,
        title: state.title,
      );
      newPinnedItems.add(itemToPin);
    } else {
      // Remove current item from pinned items based on content/title match
      newPinnedItems.removeWhere((item) => item.content == state.content && item.title == state.title);
    }

    state = state.copyWith(isPinned: newPinned, pinnedItems: newPinnedItems);
  }

  void showHtml(String html, {String? title}) {
    state = state.copyWith(
      type: CanvasContentType.html,
      content: html,
      title: title ?? 'Preview',
      isMobileCanvasOpen: true,
      isPinned: state.pinnedItems.any((item) => item.content == html),
    );
  }

  void showCode(String code, {String language = 'dart', String? title}) {
    state = state.copyWith(
      type: CanvasContentType.code,
      content: code,
      metadata: {'language': language},
      title: title ?? 'Code snippet',
      isMobileCanvasOpen: true,
      isPinned: state.pinnedItems.any((item) => item.content == code),
    );
  }

  void showMarkdown(String markdown, {String? title}) {
    state = state.copyWith(
      type: CanvasContentType.markdown,
      content: markdown,
      title: title ?? 'Document',
      isMobileCanvasOpen: true,
      isPinned: state.pinnedItems.any((item) => item.content == markdown),
    );
  }

  void showImage(String url, {String? title}) {
    state = state.copyWith(
      type: CanvasContentType.image,
      content: url,
      title: title ?? 'Image',
      isMobileCanvasOpen: true,
      isPinned: state.pinnedItems.any((item) => item.content == url),
    );
  }
  
  void showGenUI(Map<String, dynamic> data, {String? title}) {
    state = state.copyWith(
      type: CanvasContentType.custom,
      metadata: data,
      title: title ?? 'Interactive Component',
      isMobileCanvasOpen: true,
      isPinned: false, // GenUI items usually new
    );
  }

  void clear() {
    state = state.copyWith(
      type: CanvasContentType.empty,
      content: null,
      metadata: null,
      title: null,
      isPinned: false,
    );
  }
}

final canvasProvider = StateNotifierProvider<CanvasNotifier, CanvasState>((ref) {
  return CanvasNotifier();
});
