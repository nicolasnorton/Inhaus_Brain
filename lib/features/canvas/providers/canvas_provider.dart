import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/local_persistence_service.dart';

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
  final bool isDesktopCanvasOpen; // New state for desktop
  final bool isPinned;
  final List<CanvasState> pinnedItems;

  const CanvasState({
    this.type = CanvasContentType.empty,
    this.content,
    this.metadata,
    this.title,
    this.isMobileCanvasOpen = false,
    this.isDesktopCanvasOpen = false, // Default to closed on desktop
    this.isPinned = false,
    this.pinnedItems = const [],
  });

  CanvasState copyWith({
    CanvasContentType? type,
    String? content,
    Map<String, dynamic>? metadata,
    String? title,
    bool? isMobileCanvasOpen,
    bool? isDesktopCanvasOpen,
    bool? isPinned,
    List<CanvasState>? pinnedItems,
  }) {
    return CanvasState(
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      title: title ?? this.title,
      isMobileCanvasOpen: isMobileCanvasOpen ?? this.isMobileCanvasOpen,
      isDesktopCanvasOpen: isDesktopCanvasOpen ?? this.isDesktopCanvasOpen,
      isPinned: isPinned ?? this.isPinned,
      pinnedItems: pinnedItems ?? this.pinnedItems,
    );
  }

  factory CanvasState.fromJson(Map<String, dynamic> json) {
    return CanvasState(
      type: CanvasContentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => CanvasContentType.empty,
      ),
      content: json['content'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      title: json['title'] as String?,
      isMobileCanvasOpen: json['isMobileCanvasOpen'] as bool? ?? false,
      isDesktopCanvasOpen: json['isDesktopCanvasOpen'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      pinnedItems: (json['pinnedItems'] as List<dynamic>?)
              ?.map((e) => CanvasState.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'content': content,
      'metadata': metadata,
      'title': title,
      'isMobileCanvasOpen': isMobileCanvasOpen,
      'isDesktopCanvasOpen': isDesktopCanvasOpen,
      'isPinned': isPinned,
      'pinnedItems': pinnedItems.map((e) => e.toJson()).toList(),
    };
  }
}

class CanvasNotifier extends StateNotifier<CanvasState> {
  final LocalPersistenceService _persistence;

  CanvasNotifier(this._persistence) : super(const CanvasState()) {
    _loadPinnedItems();
  }

  Future<void> _loadPinnedItems() async {
    final items = await _persistence.getPinnedItems();
    if (items.isNotEmpty) {
      final pinnedStates = items.map((data) => CanvasState.fromJson(Map<String, dynamic>.from(data))).toList();
      state = state.copyWith(pinnedItems: pinnedStates);
    }
  }

  Future<void> _savePinnedItems() async {
    final items = state.pinnedItems.map((s) => s.toJson()).toList();
    await _persistence.savePinnedItems(items);
  }
  
  void toggleMobileCanvas(bool isOpen) {
    state = state.copyWith(isMobileCanvasOpen: isOpen);
  }

  void toggleDesktopCanvas(bool isOpen) {
    state = state.copyWith(isDesktopCanvasOpen: isOpen);
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
    _savePinnedItems();
  }

  void showHtml(String html, {String? title}) {
    state = state.copyWith(
      type: CanvasContentType.html,
      content: html,
      title: title ?? 'Preview',
      isMobileCanvasOpen: true,
      isDesktopCanvasOpen: true,
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
      isDesktopCanvasOpen: true,
      isPinned: state.pinnedItems.any((item) => item.content == code),
    );
  }

  void showMarkdown(String markdown, {String? title}) {
    state = state.copyWith(
      type: CanvasContentType.markdown,
      content: markdown,
      title: title ?? 'Document',
      isMobileCanvasOpen: true,
      isDesktopCanvasOpen: true,
      isPinned: state.pinnedItems.any((item) => item.content == markdown),
    );
  }

  void showImage(String url, {String? title}) {
    state = state.copyWith(
      type: CanvasContentType.image,
      content: url,
      title: title ?? 'Image',
      isMobileCanvasOpen: true,
      isDesktopCanvasOpen: true,
      isPinned: state.pinnedItems.any((item) => item.content == url),
    );
  }
  
  void showVideo(String url, {String? title}) {
    state = state.copyWith(
      type: CanvasContentType.video,
      content: url,
      title: title ?? 'Video',
      isMobileCanvasOpen: true,
      isDesktopCanvasOpen: true,
      isPinned: state.pinnedItems.any((item) => item.content == url),
    );
  }
  
  void showGenUI(Map<String, dynamic> data, {String? title}) {
    state = state.copyWith(
      type: CanvasContentType.custom,
      metadata: data,
      title: title ?? 'Interactive Component',
      isMobileCanvasOpen: true,
      isDesktopCanvasOpen: true,
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
      isMobileCanvasOpen: false,
      isDesktopCanvasOpen: true, // Reset to default true for next time?
    );
  }
}

final canvasProvider = StateNotifierProvider<CanvasNotifier, CanvasState>((ref) {
  final persistence = ref.watch(persistenceServiceProvider);
  return CanvasNotifier(persistence);
});
