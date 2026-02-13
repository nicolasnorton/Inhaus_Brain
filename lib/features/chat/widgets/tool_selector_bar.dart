import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/chat_models.dart';

class ToolSelectorBar extends StatelessWidget {
  final ToolMode selectedMode;
  final ValueChanged<ToolMode> onModeChanged;

  const ToolSelectorBar({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(
            context,
            mode: ToolMode.chat,
            label: 'Chat',
            icon: FontAwesomeIcons.message,
            isSelected: selectedMode == ToolMode.chat,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            mode: ToolMode.image,
            label: 'Image',
            icon: FontAwesomeIcons.image,
            isSelected: selectedMode == ToolMode.image,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            mode: ToolMode.video,
            label: 'Video',
            icon: FontAwesomeIcons.video,
            isSelected: selectedMode == ToolMode.video,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            mode: ToolMode.code,
            label: 'Code',
            icon: FontAwesomeIcons.code,
            isSelected: selectedMode == ToolMode.code,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required ToolMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final color = isSelected ? Colors.blueAccent : Colors.white24;
    final bgColor = isSelected ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.transparent;
    final borderColor = isSelected ? Colors.blueAccent : Colors.white10;

    return InkWell(
      onTap: () => onModeChanged(mode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blueAccent : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
