import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/widget_storage_provider.dart';
import '../models/a2ui_widget_model.dart';
import 'package:intl/intl.dart';

class ComposerSidebar extends ConsumerWidget {
  const ComposerSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final widgetsAsync = ref.watch(widgetStorageProvider);

    return Container(
      width: 250,
      color: const Color(0xFF1B1D22), // Matching typical dark sidebar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.wandMagicSparkles, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 12),
                Text(
                  'A2UI COMPOSER',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
          
          // Main Nav Links
          _buildNavLink(
            context,
            icon: FontAwesomeIcons.plus,
            label: 'Create',
            route: '/composer/editor',
            currentLocation: location,
          ),
          _buildNavLink(
            context,
            icon: FontAwesomeIcons.borderAll,
            label: 'Gallery',
            route: '/composer/gallery',
            currentLocation: location,
          ),
          _buildNavLink(
            context,
            icon: FontAwesomeIcons.cubes,
            label: 'Components',
            route: '/composer/components',
            currentLocation: location,
          ),
          _buildNavLink(
            context,
            icon: FontAwesomeIcons.icons,
            label: 'Icons',
            route: '/composer/icons',
            currentLocation: location,
          ),
          
          const Divider(color: Colors.white10, height: 32),
          
          // Widgets Section Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'Widgets',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          // Saved Widgets List
          Expanded(
            child: widgetsAsync.when(
              data: (widgets) {
                if (widgets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No widgets saved yet.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: widgets.length,
                  itemBuilder: (context, index) {
                    final widget = widgets[index];
                    final isSelected = location == '/composer/editor/\${widget.id}';
                    return _buildWidgetListItem(context, widget, isSelected);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading widgets: $e', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required String currentLocation,
  }) {
    // If routing directly to /composer/editor without an ID, highlight 'Create'
    // If routing to /composer/editor/id, do NOT highlight 'Create' (that highlights the widget list item instead)
    bool isSelected = false;
    if (route == '/composer/editor') {
      isSelected = currentLocation == '/composer/editor'; // strict match to avoid matching /composer/editor/123
    } else {
      isSelected = currentLocation.startsWith(route);
    }

    final color = isSelected ? Colors.blueAccent : Colors.white70;
    final bgColor = isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            context.go(route);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              FaIcon(icon, size: 16, color: color),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetListItem(BuildContext context, A2uiWidgetModel widget, bool isSelected) {
    final color = isSelected ? Colors.blueAccent : Colors.white70;
    final bgColor = isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent;
    final dateStr = DateFormat('MMM d, h:mm a').format(widget.updatedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            context.go('/composer/editor/\${widget.id}');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: TextStyle(
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Updated $dateStr',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
