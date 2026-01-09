import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/command_models.dart';

/// Provider for all commands
final commandsProvider = StateProvider<List<Command>>((ref) {
  return [];
});

/// Provider for command history
final commandHistoryProvider =
    StateNotifierProvider<CommandHistoryNotifier, List<CommandHistoryEntry>>(
        (ref) {
  return CommandHistoryNotifier();
});

/// Provider for command palette visibility
final commandPaletteVisibleProvider = StateProvider<bool>((ref) => false);

/// Provider for command search query
final commandSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered commands
final filteredCommandsProvider = Provider<List<Command>>((ref) {
  final commands = ref.watch(commandsProvider);
  final query = ref.watch(commandSearchQueryProvider);

  if (query.isEmpty) {
    return commands;
  }

  // Score and sort commands by match quality
  final scored = commands
      .map((cmd) => MapEntry(cmd, cmd.matchScore(query)))
      .where((entry) => entry.value > 0)
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return scored.map((e) => e.key).toList();
});

/// Provider for recent commands
final recentCommandsProvider = Provider<List<Command>>((ref) {
  final history = ref.watch(commandHistoryProvider);
  final commands = ref.watch(commandsProvider);

  // Get last 5 unique commands
  final recentIds = <String>{};
  final recent = <Command>[];

  for (final entry in history.reversed) {
    if (recentIds.contains(entry.commandId)) continue;
    
    final command = commands.where((c) => c.id == entry.commandId).firstOrNull;
    if (command != null) {
      recent.add(command);
      recentIds.add(entry.commandId);
    }

    if (recent.length >= 5) break;
  }

  return recent;
});

/// State notifier for command history
class CommandHistoryNotifier extends StateNotifier<List<CommandHistoryEntry>> {
  CommandHistoryNotifier() : super([]);

  /// Add command to history
  void addCommand(String commandId) {
    state = [
      CommandHistoryEntry(
        commandId: commandId,
        executedAt: DateTime.now(),
      ),
      ...state,
    ];

    // Keep only last 50 entries
    if (state.length > 50) {
      state = state.sublist(0, 50);
    }
  }

  /// Clear history
  void clear() {
    state = [];
  }
}
