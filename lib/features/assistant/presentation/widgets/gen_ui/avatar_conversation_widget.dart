import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AvatarConversationWidget extends StatelessWidget {
  final String speakerName;
  final String text;
  final String? avatarUrl;
  final bool isRightAligned;

  const AvatarConversationWidget({
    super.key,
    required this.speakerName,
    required this.text,
    this.avatarUrl,
    this.isRightAligned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            isRightAligned ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isRightAligned) _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: isRightAligned
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  speakerName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRightAligned
                        ? Colors.blueAccent.withValues(alpha: 0.2)
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(12).copyWith(
                      topLeft: !isRightAligned ? Radius.zero : null,
                      topRight: isRightAligned ? Radius.zero : null,
                    ),
                    border: Border.all(
                      color: isRightAligned
                          ? Colors.blueAccent.withValues(alpha: 0.4)
                          : Colors.white24,
                    ),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ).animate().fade(duration: 300.ms).slideX(begin: isRightAligned ? 0.1 : -0.1),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isRightAligned) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[800],
        image: avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
        border: Border.all(color: Colors.white24),
      ),
      child: avatarUrl == null
          ? const Icon(Icons.person, color: Colors.white54)
          : null,
    );
  }
}
