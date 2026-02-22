import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ag_ui/ag_ui.dart' hide State;
import '../providers/widget_storage_provider.dart';
import '../models/composer_gallery_templates.dart';
import '../../assistant/presentation/widgets/gen_ui/gen_ui_renderer.dart';

class ComposerGalleryScreen extends ConsumerWidget {
  const ComposerGalleryScreen({super.key});

  Future<void> _cloneTemplate(BuildContext context, WidgetRef ref, GalleryTemplate template) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
      
      final notifier = ref.read(widgetStorageProvider.notifier);
      final newId = await notifier.saveWidget(template.name, template.jsonSchema);
      
      // hide loading
      if (context.mounted) Navigator.pop(context);
      // close the preview modal
      if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
      
      // Navigate to editor
      if (context.mounted) context.go('/composer/editor/\$newId');
      
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating widget: \$e')),
        );
      }
    }
  }

  void _showPreviewModal(BuildContext context, WidgetRef ref, GalleryTemplate template) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA), // Soft background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Colors.black12)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        template.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          side: const BorderSide(color: Colors.black12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _cloneTemplate(context, ref, template),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open in widget editor'),
                      ),
                    ],
                  ),
                ),
                // Split Pane
                Expanded(
                  child: Row(
                    children: [
                      // Left: Live Preview
                      Expanded(
                        flex: 5,
                        child: Container(
                          color: const Color(0xFFF0F2F5),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 400),
                                padding: const EdgeInsets.all(32),
                                child: GenUIRenderer(
                                  payload: jsonDecode(template.jsonSchema),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, color: Colors.black12),
                      // Right: JSON Schema view
                      Expanded(
                        flex: 4,
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFAFAFA),
                                  border: Border(bottom: BorderSide(color: Colors.black12)),
                                ),
                                child: const Text(
                                  'Components Schema',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: SelectableText(
                                    template.jsonSchema,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Gallery',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                   ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a pre-built template to start customizing in the Editor.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 0.85,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final template = composerGalleryTemplates[index];
                  return _TemplateCard(
                    template: template,
                    onTap: () => _showPreviewModal(context, ref, template),
                  );
                },
                childCount: composerGalleryTemplates.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 64)),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final GalleryTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live Preview Thumbnail
            Expanded(
              flex: 3,
              child: Container(
                color: const Color(0xFFF0F2F5),
                child: ClipRect(
                  child: AbsorbPointer( // Prevents interaction with inner widgets
                    child: Transform.scale(
                      scale: 0.65, // Scale down to fit as a thumbnail
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: GenUIRenderer(
                            payload: jsonDecode(template.jsonSchema),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Info Area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        template.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
