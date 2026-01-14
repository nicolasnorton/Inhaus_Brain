import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/command_models.dart';
import '../providers/command_provider.dart';

/// Command palette widget (Cmd+K)
class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _keyboardFocusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Auto-focus search input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _executeCommand(Command command) {
    // Add to history
    ref.read(commandHistoryProvider.notifier).addCommand(command.id);
    
    // Execute action
    command.action();
    
    // Close palette
    ref.read(commandPaletteVisibleProvider.notifier).state = false;
    Navigator.of(context).pop();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final filteredCommands = ref.read(filteredCommandsProvider);
    final recentCommands = ref.read(recentCommandsProvider);
    final displayCommands = _searchController.text.isEmpty
        ? recentCommands
        : filteredCommands;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % displayCommands.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex =
            (_selectedIndex - 1 + displayCommands.length) % displayCommands.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (displayCommands.isNotEmpty) {
        _executeCommand(displayCommands[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      ref.read(commandPaletteVisibleProvider.notifier).state = false;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredCommands = ref.watch(filteredCommandsProvider);
    final recentCommands = ref.watch(recentCommandsProvider);
    final searchQuery = _searchController.text;

    final displayCommands = searchQuery.isEmpty ? recentCommands : filteredCommands;

    return RawKeyboardListener(
      focusNode: _keyboardFocusNode,
      onKey: _handleKeyEvent,
      child: GestureDetector(
        onTap: () {
          ref.read(commandPaletteVisibleProvider.notifier).state = false;
          Navigator.of(context).pop();
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when clicking inside
              child: Container(
                width: 600,
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search input
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search commands...',
                          prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          ref.read(commandSearchQueryProvider.notifier).state = value;
                          setState(() {
                            _selectedIndex = 0;
                          });
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // Commands list
                    Flexible(
                      child: displayCommands.isEmpty
                          ? _buildEmptyState(theme)
                          : _buildCommandsList(displayCommands, theme),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FontAwesomeIcons.magnifyingGlass,
            size: 48,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            'No commands found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandsList(List<Command> commands, ThemeData theme) {
    // Group commands by category if not searching
    final isSearching = _searchController.text.isNotEmpty;

    if (isSearching) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: commands.length,
        itemBuilder: (context, index) {
          return _buildCommandItem(commands[index], index, theme);
        },
      );
    }

    // Show recent commands
    return ListView.builder(
      shrinkWrap: true,
      itemCount: commands.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Recent',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        return _buildCommandItem(commands[index - 1], index - 1, theme);
      },
    );
  }

  Widget _buildCommandItem(Command command, int index, ThemeData theme) {
    final isSelected = index == _selectedIndex;

    return InkWell(
      onTap: () => _executeCommand(command),
      onHover: (hovering) {
        if (hovering) {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected
            ? theme.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Row(
          children: [
            // Icon
            if (command.icon != null)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    command.icon!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FontAwesomeIcons.bolt,
                  size: 14,
                  color: theme.primaryColor,
                ),
              ),
            const SizedBox(width: 12),
            // Name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (command.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      command.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Shortcut
            if (command.shortcut != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  command.shortcut!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
