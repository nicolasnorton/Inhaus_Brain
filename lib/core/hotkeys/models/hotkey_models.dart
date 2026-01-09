import 'package:flutter/services.dart';

/// Hotkey category
enum HotkeyCategory {
  global,
  canvas,
  node,
  navigation;

  String get displayName {
    switch (this) {
      case HotkeyCategory.global:
        return 'Global';
      case HotkeyCategory.canvas:
        return 'Canvas';
      case HotkeyCategory.node:
        return 'Node';
      case HotkeyCategory.navigation:
        return 'Navigation';
    }
  }
}

/// Hotkey action
class HotkeyAction {
  final String id;
  final String name;
  final String description;
  final HotkeyCategory category;
  final VoidCallback action;

  const HotkeyAction({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.action,
  });
}

/// Hotkey binding
class HotkeyBinding {
  final String actionId;
  final Set<LogicalKeyboardKey> keys;
  final bool ctrl;
  final bool shift;
  final bool alt;
  final bool meta;

  const HotkeyBinding({
    required this.actionId,
    required this.keys,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });

  /// Check if this binding matches a key event
  bool matches(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return false;

    // Check modifiers
    if (ctrl != event.isControlPressed) return false;
    if (shift != event.isShiftPressed) return false;
    if (alt != event.isAltPressed) return false;
    if (meta != event.isMetaPressed) return false;

    // Check key
    return keys.contains(event.logicalKey);
  }

  /// Display string for UI
  String get displayString {
    final parts = <String>[];
    if (meta) parts.add('⌘');
    if (ctrl) parts.add('Ctrl');
    if (alt) parts.add('Alt');
    if (shift) parts.add('Shift');
    
    for (final key in keys) {
      parts.add(_keyLabel(key));
    }
    
    return parts.join('+');
  }

  String _keyLabel(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.keyK) return 'K';
    if (key == LogicalKeyboardKey.keyS) return 'S';
    if (key == LogicalKeyboardKey.keyN) return 'N';
    if (key == LogicalKeyboardKey.keyP) return 'P';
    if (key == LogicalKeyboardKey.keyF) return 'F';
    if (key == LogicalKeyboardKey.keyZ) return 'Z';
    if (key == LogicalKeyboardKey.keyA) return 'A';
    if (key == LogicalKeyboardKey.keyD) return 'D';
    if (key == LogicalKeyboardKey.keyG) return 'G';
    if (key == LogicalKeyboardKey.keyL) return 'L';
    if (key == LogicalKeyboardKey.keyI) return 'I';
    if (key == LogicalKeyboardKey.keyV) return 'V';
    if (key == LogicalKeyboardKey.keyT) return 'T';
    if (key == LogicalKeyboardKey.keyE) return 'E';
    if (key == LogicalKeyboardKey.keyR) return 'R';
    if (key == LogicalKeyboardKey.comma) return ',';
    if (key == LogicalKeyboardKey.slash) return '/';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.delete) return 'Delete';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.digit0) return '0';
    return key.keyLabel;
  }

  Map<String, dynamic> toJson() => {
        'action_id': actionId,
        'keys': keys.map((k) => k.keyId).toList(),
        'ctrl': ctrl,
        'shift': shift,
        'alt': alt,
        'meta': meta,
      };

  factory HotkeyBinding.fromJson(Map<String, dynamic> json) {
    return HotkeyBinding(
      actionId: json['action_id'] as String,
      keys: (json['keys'] as List)
          .map((id) => LogicalKeyboardKey.findKeyByKeyId(id as int))
          .whereType<LogicalKeyboardKey>()
          .toSet(),
      ctrl: json['ctrl'] as bool? ?? false,
      shift: json['shift'] as bool? ?? false,
      alt: json['alt'] as bool? ?? false,
      meta: json['meta'] as bool? ?? false,
    );
  }
}

/// Default hotkey bindings
class DefaultHotkeys {
  static List<HotkeyBinding> get bindings => [
        // Global shortcuts
        HotkeyBinding(
          actionId: 'open_command_palette',
          keys: {LogicalKeyboardKey.keyK},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'save',
          keys: {LogicalKeyboardKey.keyS},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'new_app',
          keys: {LogicalKeyboardKey.keyN},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'quick_open',
          keys: {LogicalKeyboardKey.keyP},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'find',
          keys: {LogicalKeyboardKey.keyF},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'settings',
          keys: {LogicalKeyboardKey.comma},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'undo',
          keys: {LogicalKeyboardKey.keyZ},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'redo',
          keys: {LogicalKeyboardKey.keyZ},
          meta: true,
          shift: true,
        ),
        HotkeyBinding(
          actionId: 'close_dialog',
          keys: {LogicalKeyboardKey.escape},
        ),
        
        // Canvas shortcuts
        HotkeyBinding(
          actionId: 'zoom_in',
          keys: {LogicalKeyboardKey.equal},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'zoom_out',
          keys: {LogicalKeyboardKey.minus},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'reset_zoom',
          keys: {LogicalKeyboardKey.digit0},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'select_all',
          keys: {LogicalKeyboardKey.keyA},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'delete_selected',
          keys: {LogicalKeyboardKey.delete},
        ),
        HotkeyBinding(
          actionId: 'duplicate_selected',
          keys: {LogicalKeyboardKey.keyD},
          meta: true,
        ),
        HotkeyBinding(
          actionId: 'group_selected',
          keys: {LogicalKeyboardKey.keyG},
          meta: true,
        ),
        
        // Node shortcuts
        HotkeyBinding(
          actionId: 'add_llm_node',
          keys: {LogicalKeyboardKey.keyL},
        ),
        HotkeyBinding(
          actionId: 'add_knowledge_node',
          keys: {LogicalKeyboardKey.keyK},
        ),
        HotkeyBinding(
          actionId: 'add_ifelse_node',
          keys: {LogicalKeyboardKey.keyI},
        ),
        HotkeyBinding(
          actionId: 'add_variable_node',
          keys: {LogicalKeyboardKey.keyV},
        ),
        HotkeyBinding(
          actionId: 'add_tool_node',
          keys: {LogicalKeyboardKey.keyT},
        ),
        HotkeyBinding(
          actionId: 'add_end_node',
          keys: {LogicalKeyboardKey.keyE},
        ),
      ];
}
