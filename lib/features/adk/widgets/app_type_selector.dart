import 'package:flutter/material.dart';
import '../models/app_type_models.dart';

/// Widget for selecting app type during app creation
class AppTypeSelector extends StatefulWidget {
  final AppType? selectedType;
  final ValueChanged<AppType> onTypeSelected;

  const AppTypeSelector({
    super.key,
    this.selectedType,
    required this.onTypeSelected,
  });

  @override
  State<AppTypeSelector> createState() => _AppTypeSelectorState();
}

class _AppTypeSelectorState extends State<AppTypeSelector> {
  bool _showLegacyTypes = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recommended types
        const Text(
          'RECOMMENDED',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: AppType.workflow,
                icon: Icons.account_tree,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTypeCard(
                type: AppType.chatflow,
                icon: Icons.chat_bubble_outline,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Legacy types toggle
        InkWell(
          onTap: () => setState(() => _showLegacyTypes = !_showLegacyTypes),
          child: Row(
            children: [
              Text(
                'MORE BASIC APP TYPES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _showLegacyTypes ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: const Color(0xFF6B7280),
              ),
            ],
          ),
        ),
        
        if (_showLegacyTypes) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTypeCard(
                  type: AppType.chatbot,
                  icon: Icons.smart_toy_outlined,
                  color: const Color(0xFF8B5CF6),
                  isLegacy: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTypeCard(
                  type: AppType.agent,
                  icon: Icons.psychology_outlined,
                  color: const Color(0xFFA855F7),
                  isLegacy: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTypeCard(
                  type: AppType.textGenerator,
                  icon: Icons.description_outlined,
                  color: const Color(0xFF10B981),
                  isLegacy: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These app types run on the same workflow engine underneath, but comes with simpler legacy interfaces.',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
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
    required AppType type,
    required IconData icon,
    required Color color,
    bool isLegacy = false,
  }) {
    final isSelected = widget.selectedType == type;

    return InkWell(
      onTap: () => widget.onTypeSelected(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              type.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              type.description,
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
