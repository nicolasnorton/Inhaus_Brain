import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/mcp/tools/stitch_tools.dart';
import '../../../../../core/services/stitch_service.dart';
import 'stitch_design_preview_widget.dart';

class StitchDesignCarouselWidget extends ConsumerWidget {
  final Map<String, dynamic> data;
  final Function(String, Map<String, dynamic>)? onAction;

  const StitchDesignCarouselWidget({
    super.key, 
    required this.data, 
    this.onAction
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "items" is a List of Maps: [{screen_id, image_url, name, project_id, ...}]
    final items = data['items'] as List<dynamic>? ?? [];
    final projectId = data['project_id'] as String?;

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1, // +1 for "Add New"
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          if (index == items.length) {
            // Add New Screen Card
            return _buildAddCard(projectId);
          }

          final item = items[index] as Map<String, dynamic>;
          final screenData = {
            'image_url': item['image_url'],
            'screen_id': item['id'],
            'project_id': projectId,
            'status': item['status'] ?? 'view',
          };
          
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            child: StitchDesignPreviewWidget(
              data: screenData,
              onAction: onAction,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddCard(String? projectId) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: () {
          if (projectId != null) {
            onAction?.call('add_screen', {'project_id': projectId});
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.purpleAccent, size: 32),
              SizedBox(height: 8),
              Text(
                'Add Screen',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
