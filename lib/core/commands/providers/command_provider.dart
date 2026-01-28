import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../router/app_router.dart';
import '../../../features/workspace/providers/apps_provider.dart';
import '../models/command_models.dart';

/// Provider for all commands
final commandsProvider = Provider<List<Command>>((ref) {
  final apps = ref.watch(appsProvider);
  
  final commands = <Command>[
    Command(
      id: 'go-home',
      name: 'Go to Dashboard',
      description: 'Navigate to the main workspace dashboard',
      category: CommandCategory.navigation,
      icon: '🏠',
      action: () => ref.read(routerProvider).go('/'),
    ),
    Command(
      id: 'new-app',
      name: 'Create New App',
      description: 'Open the dialog to create a new application',
      category: CommandCategory.actions,
      icon: '➕',
      action: () {
        // This will need access to a BuildContext or a global navigation service.
        // For now, we'll assume the command palette handler handles navigation.
      },
    ),
  ];

  // Dynamic commands for apps
  for (final app in apps) {
    commands.add(
      Command(
        id: 'open-app-${app.id}',
        name: 'Open ${app.name}',
        description: 'Navigate to ${app.name} editor',
        category: CommandCategory.navigation,
        icon: app.type.icon,
        action: () => ref.read(routerProvider).go('/app-editor?id=${app.id}'),
        keywords: [app.name, app.type.name, 'open', 'edit'],
      ),
    );
  }

  return commands;
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
