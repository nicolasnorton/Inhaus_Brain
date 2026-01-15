import 'package:flutter/material.dart';
import '../models/app_type_models.dart';

/// Widget for selecting start node type in workflows
class StartNodeSelector extends StatelessWidget {
  final StartNodeType? selectedType;
  final ValueChanged<StartNodeType> onTypeSelected;
  final bool showWarning;

  const StartNodeSelector({
    super.key,
    this.selectedType,
    required this.onTypeSelected,
    this.showWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Start Node Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                context: context,
                type: StartNodeType.userInput,
                icon: Icons.person_outline,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTypeCard(
                context: context,
                type: StartNodeType.trigger,
                icon: Icons.schedule,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        
        if (showWarning) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFBBF24),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'User Input and Trigger Start nodes are mutually exclusive. To switch between them, right-click the current start node > Change Node.',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF92400E),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        if (selectedType == StartNodeType.userInput) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only workflows started by User Input can be published as standalone web apps or MCP servers, exposed through backend service APIs, or used as tools in other INHAUS BRAIN applications.',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1E40AF),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeCard({
    required BuildContext context,
    required StartNodeType type,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedType == type;

    return InkWell(
      onTap: () => onTypeSelected(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              type.displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            
            // Description
            Text(
              type.description,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
