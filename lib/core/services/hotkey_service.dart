import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Type for hotkey callbacks
typedef HotkeyAction = void Function(BuildContext context);

/// Hotkey model
class Hotkey {
  final LogicalKeyboardKey key;
  final bool control;
  final bool shift;
  final bool alt;
  final bool meta;
  final String label;
  final String description;

  const Hotkey({
    required this.key,
    this.control = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
    required this.label,
    required this.description,
  });

  bool matches(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return false;
    
    // Check key
    if (event.logicalKey != key) return false;
    
    // Check modifiers
    // On Mac, Meta is usually Cmd. On others, Control is primary.
    // We handle "primary" modifier (Cmd on Mac, Ctrl on others)
    final isMac = RawKeyEventDataMacOs == event.data.runtimeType; // Basic check
    
    if (control && !event.isControlPressed) return false;
    if (shift && !event.isShiftPressed) return false;
    if (alt && !event.isAltPressed) return false;
    if (meta && !event.isMetaPressed) return false;
    
    return true;
  }

  String get shortcutText {
    final buffer = StringBuffer();
    if (meta) buffer.write('⌘ ');
    if (control) buffer.write('⌃ ');
    if (shift) buffer.write('⇧ ');
    if (alt) buffer.write('⌥ ');
    buffer.write(key.keyLabel);
    return buffer.toString();
  }
}

/// Provider for registering global hotkeys
final hotkeyProvider = Provider((ref) => HotkeyService());

class HotkeyService {
  final Map<Hotkey, HotkeyAction> _registry = {};

  void register(Hotkey hotkey, HotkeyAction action) {
    _registry[hotkey] = action;
  }

  void unregister(Hotkey hotkey) {
    _registry.remove(hotkey);
  }

  bool handleKeyEvent(RawKeyEvent event, BuildContext context) {
    for (final entry in _registry.entries) {
      if (entry.key.matches(event)) {
        entry.value(context);
        return true;
      }
    }
    return false;
  }

  List<Hotkey> get allHotkeys => _registry.keys.toList();
}

/// A widget that listens for global hotkeys
class GlobalHotkeyListener extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalHotkeyListener({super.key, required this.child});

  @override
  ConsumerState<GlobalHotkeyListener> createState() => _GlobalHotkeyListenerState();
}

class _GlobalHotkeyListenerState extends ConsumerState<GlobalHotkeyListener> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'GlobalHotkeyNode');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(hotkeyProvider);

    return Focus(
      focusNode: _focusNode,
      // autofocus: true, // Removed to prevent RenderBox was not laid out error on Chrome startup
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          if (service.handleKeyEvent(event, context)) {
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
