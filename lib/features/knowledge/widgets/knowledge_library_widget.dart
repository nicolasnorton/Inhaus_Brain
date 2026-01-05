import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../providers/knowledge_provider.dart';
import '../models/knowledge_source.dart';

class KnowledgeLibraryWidget extends ConsumerStatefulWidget {
  const KnowledgeLibraryWidget({super.key});

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

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(knowledgeProvider);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
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
                  'CONTEXT BOARD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white54,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                )
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
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _isAdding = !_isAdding),
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text('Add Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                          foregroundColor: Colors.blueAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addFileSource,
                        icon: const Icon(Icons.upload_file, size: 16),
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          foregroundColor: Colors.white,
                        ),
                      ),
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
      case KnowledgeSourceType.file:
      case KnowledgeSourceType.pdf:
      case KnowledgeSourceType.text:
        icon = FontAwesomeIcons.fileLines;
        color = Colors.orangeAccent;
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
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
            onPressed: () => ref.read(knowledgeProvider.notifier).removeSource(source.id),
          ),
        ],
      ),
    );
  }
}
