import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workflow_execution_models.dart';
import '../providers/workflow_execution_provider.dart';

/// Dropdown selector for variables with categorization and search
class VariableSelector extends ConsumerStatefulWidget {
  final ValueChanged<VariableReference> onVariableSelected;
  final List<VariableCategory>? filterCategories;

  const VariableSelector({
    super.key,
    required this.onVariableSelected,
    this.filterCategories,
  });

  @override
  ConsumerState<VariableSelector> createState() => _VariableSelectorState();
}

class _VariableSelectorState extends ConsumerState<VariableSelector> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final availableVariables = ref.watch(availableVariablesProvider);
    final filteredVariables = _filterVariables(availableVariables);

    return PopupMenuButton<VariableReference>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Icon(
          Icons.code,
          size: 16,
          color: Color(0xFF6B7280),
        ),
      ),
      tooltip: 'Insert Variable',
      onSelected: widget.onVariableSelected,
      itemBuilder: (context) {
        return [
          // Search field
          PopupMenuItem<VariableReference>(
            enabled: false,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search variables...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          const PopupMenuDivider(),
          
          // Categorized variables
          ...filteredVariables.entries.expand((entry) {
            final category = entry.key;
            final variables = entry.value;
            
            if (variables.isEmpty) return <PopupMenuEntry<VariableReference>>[];
            
            return [
              // Category header
              PopupMenuItem<VariableReference>(
                enabled: false,
                child: Text(
                  category.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              
              // Variables in category
              ...variables.map((variable) => PopupMenuItem<VariableReference>(
                    value: variable,
                    child: _buildVariableItem(variable),
                  )),
              
              const PopupMenuDivider(),
            ];
          }),
        ];
      },
    );
  }

  Widget _buildVariableItem(VariableReference variable) {
    return Row(
      children: [
        // Icon based on category
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _getCategoryColor(variable.category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            _getCategoryIcon(variable.category),
            size: 14,
            color: _getCategoryColor(variable.category),
          ),
        ),
        const SizedBox(width: 8),
        
        // Variable name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                variable.displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
              if (variable.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  variable.description!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        // Data type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            variable.dataType,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Map<VariableCategory, List<VariableReference>> _filterVariables(
    List<VariableReference> variables,
  ) {
    final filtered = variables.where((v) {
      // Filter by category if specified
      if (widget.filterCategories != null &&
          !widget.filterCategories!.contains(v.category)) {
        return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return v.displayName.toLowerCase().contains(_searchQuery) ||
            (v.description?.toLowerCase().contains(_searchQuery) ?? false);
      }
      
      return true;
    }).toList();

    // Group by category
    final grouped = <VariableCategory, List<VariableReference>>{};
    for (final variable in filtered) {
      grouped.putIfAbsent(variable.category, () => []).add(variable);
    }

    return grouped;
  }

  IconData _getCategoryIcon(VariableCategory category) {
    switch (category) {
      case VariableCategory.system:
        return Icons.settings_outlined;
      case VariableCategory.input:
        return Icons.input_outlined;
      case VariableCategory.output:
        return Icons.output_outlined;
      case VariableCategory.conversation:
        return Icons.chat_bubble_outline;
      case VariableCategory.environment:
        return Icons.lock_outline;
    }
  }

  Color _getCategoryColor(VariableCategory category) {
    switch (category) {
      case VariableCategory.system:
        return const Color(0xFF8B5CF6);
      case VariableCategory.input:
        return const Color(0xFF3B82F6);
      case VariableCategory.output:
        return const Color(0xFF10B981);
      case VariableCategory.conversation:
        return const Color(0xFFF59E0B);
      case VariableCategory.environment:
        return const Color(0xFFEF4444);
    }
  }
}
