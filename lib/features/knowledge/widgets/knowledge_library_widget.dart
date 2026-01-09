import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../providers/knowledge_provider.dart';
import '../models/knowledge_source.dart';
import '../../campaigns/models/campaign.dart';
import '../../chat/providers/chat_provider.dart';

class KnowledgeLibraryWidget extends ConsumerStatefulWidget {
  final void Function(String kbName)? onSelectKB;
  
  const KnowledgeLibraryWidget({super.key, this.onSelectKB});

  @override
  ConsumerState<KnowledgeLibraryWidget> createState() => _KnowledgeLibraryWidgetState();
}

class _KnowledgeLibraryWidgetState extends ConsumerState<KnowledgeLibraryWidget> {
  final _urlController = TextEditingController();
  bool _isAdding = false;

  void _addUrlSource() {
    if (_urlController.text.isEmpty) return;

    final newSource = KnowledgeSource(
      id: const Uuid().v4(),
      title: _urlController.text, // Simplified title for now
      content: _urlController.text,
      type: KnowledgeSourceType.url,
      createdAt: DateTime.now(),
    );

    ref.read(knowledgeProvider.notifier).addSource(newSource);
    _urlController.clear();
    setState(() => _isAdding = false);
  }

  // Placeholder for file picking logic
  void _addFileSource() async {
     // TODO: Implement file picker
     // For now, simulate adding a text file
     final newSource = KnowledgeSource(
      id: const Uuid().v4(),
      title: 'Brand_Guidelines_2026.pdf',
      content: 'Simulated content of brand guidelines...',
      type: KnowledgeSourceType.file,
      createdAt: DateTime.now(),
      metadata: {'fileSize': '2.4MB'},
    );
    ref.read(knowledgeProvider.notifier).addSource(newSource);
  }

  void _addImageSource() async {
    // Mock adding an image asset
    final newSource = KnowledgeSource(
      id: const Uuid().v4(),
      title: 'Coffee_Ad_Variation_A.png',
      content: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', // Mock 1x1 transparent pixel
      type: KnowledgeSourceType.image,
      createdAt: DateTime.now(),
      metadata: {'dimensions': '1024x1024'},
    );
    ref.read(knowledgeProvider.notifier).addSource(newSource);
  }

  void _addDriveSource() async {
     // TODO: Implement Google Picker API
     // Mock behaviour
     final newSource = KnowledgeSource(
      id: const Uuid().v4(),
      title: 'Campaign_Brief_v3.gdoc',
      content: 'https://docs.google.com/document/d/mock-doc-id',
      type: KnowledgeSourceType.googleDrive,
      createdAt: DateTime.now(),
      metadata: {'owner': 'client@inhaus.ai'},
    );
    ref.read(knowledgeProvider.notifier).addSource(newSource);
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(knowledgeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'KNOWLEDGE BASE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: sources.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sources.length,
                    itemBuilder: (context, index) => _buildSourceItem(sources[index]),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Column(
              children: [
                if (_isAdding) ...[
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'Paste URL...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, color: Colors.blueAccent),
                        onPressed: _addUrlSource,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    autofocus: true,
                    onSubmitted: (_) => _addUrlSource(),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    _buildActionButton(
                      onPressed: () => setState(() => _isAdding = !_isAdding),
                      icon: Icons.link,
                      label: 'Add Link',
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      onPressed: _addFileSource,
                      icon: Icons.upload_file,
                      label: 'Upload',
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      onPressed: _addImageSource,
                      icon: Icons.image,
                      label: 'Image',
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      onPressed: _addDriveSource,
                      icon: FontAwesomeIcons.googleDrive,
                      label: 'Drive',
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(icon, size: 16, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.layerGroup, size: 48, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text(
            'No Active Context',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add URLs or files to ground the AI agents.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceItem(KnowledgeSource source) {
    IconData icon;
    Color color;

    switch (source.type) {
      case KnowledgeSourceType.url:
        icon = FontAwesomeIcons.globe;
        color = Colors.blueAccent;
        break;
      case KnowledgeSourceType.googleDrive:
        icon = FontAwesomeIcons.googleDrive;
        color = Colors.greenAccent;
        break;
      case KnowledgeSourceType.file:
      case KnowledgeSourceType.pdf:
      case KnowledgeSourceType.text:
        icon = FontAwesomeIcons.fileLines;
        color = Colors.orangeAccent;
        break;
      case KnowledgeSourceType.image:
        icon = FontAwesomeIcons.image;
        color = Colors.purpleAccent;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  source.type.name.toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
              ],
            ),
          ),
          if (source.type == KnowledgeSourceType.image)
            IconButton(
              icon: const Icon(Icons.psychology, size: 16, color: Colors.purpleAccent),
              tooltip: 'Analyze with Vision Agent',
              onPressed: () {
                ref.read(chatProvider.notifier).sendMessage(
                  'Analyze this visual asset: ${source.title}',
                  attachments: [
                    Attachment(
                      id: const Uuid().v4(),
                      type: AttachmentType.image,
                      url: source.content,
                      name: source.title,
                      createdAt: DateTime.now(),
                    )
                  ],
                );
                Navigator.pop(context);
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
            onPressed: () => ref.read(knowledgeProvider.notifier).removeSource(source.id),
          ),
        ],
      ),
    );
  }
}
