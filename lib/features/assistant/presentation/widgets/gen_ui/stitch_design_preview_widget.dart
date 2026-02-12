import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/mcp/tools/stitch_tools.dart';
import '../../../../../core/services/stitch_service.dart';
import '../gen_ui_message_bubble.dart';

class StitchDesignPreviewWidget extends ConsumerWidget {
  final Map<String, dynamic> data;
  final Function(String, Map<String, dynamic>)? onAction;

  const StitchDesignPreviewWidget({
    super.key, 
    required this.data, 
    this.onAction
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = data['image_url'] as String?;
    final screenId = data['screen_id'] as String?;
    final projectId = data['project_id'] as String?;
    final status = data['status'] as String? ?? 'generated';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: const Color(0xFF1E2128), // Dark theme default
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.black12,
            child: Row(
              children: [
                const Icon(Icons.brush, size: 16, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                Text(
                  'Stitch Design Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white70, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Image Preview
          AspectRatio(
            aspectRatio: 16 / 9,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, loading) {
                      if (loading == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white24, size: 48),
                          SizedBox(height: 8),
                          Text('Preview not available', style: TextStyle(color: Colors.white24)),
                        ],
                      ),
                    ),
                  )
                : const Center(
                    child: Text('Generate a design to see preview', style: TextStyle(color: Colors.white24)),
                  ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.code,
                  label: 'View Code',
                  onTap: () {
                    // Trigger agent to get code
                    if (screenId != null && projectId != null) {
                       // We can't directly trigger the agent from here easily without a callback to the chat
                       // For GenUI, usually we return an action. 
                       // Currently specialized to just print, but ideally sends a message.
                       onAction?.call('view_code', {
                         'project_id': projectId, 
                         'screen_id': screenId
                       });
                    }
                  },
                ),
                _ActionButton(
                  icon: Icons.auto_fix_high,
                  label: 'Refine',
                  onTap: () {
                     onAction?.call('refine', {
                       'project_id': projectId,
                        'screen_id': screenId
                     });
                  },
                ),
                _ActionButton(
                  icon: Icons.palette,
                  label: 'Extract Style',
                  onTap: () {
                     onAction?.call('extract_style', {
                       'project_id': projectId,
                       'screen_id': screenId
                     });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
