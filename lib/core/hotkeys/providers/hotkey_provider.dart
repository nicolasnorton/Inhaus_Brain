import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hotkey_models.dart';

/// Provider for hotkey bindings
final hotkeyBindingsProvider =
    StateNotifierProvider<HotkeyBindingsNotifier, List<HotkeyBinding>>((ref) {
  return HotkeyBindingsNotifier();
});

/// Provider for hotkey actions
final hotkeyActionsProvider = StateProvider<Map<String, HotkeyAction>>((ref) {
  return {};
});

/// State notifier for hotkey bindings
class HotkeyBindingsNotifier extends StateNotifier<List<HotkeyBinding>> {
  HotkeyBindingsNotifier() : super(DefaultHotkeys.bindings);

  /// Add or update a binding
  void setBinding(HotkeyBinding binding) {
    // Remove existing binding for this action
    state = state.where((b) => b.actionId != binding.actionId).toList();
    // Add new binding
    state = [...state, binding];
  }

  /// Remove a binding
  void removeBinding(String actionId) {
    state = state.where((b) => b.actionId != actionId).toList();
  }

  /// Reset to defaults
  void resetToDefaults() {
    state = DefaultHotkeys.bindings;
  }

  /// Get binding for action
  HotkeyBinding? getBinding(String actionId) {
    try {
      return state.firstWhere((b) => b.actionId == actionId);
    } catch (e) {
      return null;
    }
  }
}
