import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../providers/knowledge_provider.dart';
import '../models/knowledge_source.dart';
import '../models/knowledge_api_models.dart';
import '../screens/document_detail_screen.dart';
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
    final selectedDatasetId = ref.watch(selectedDatasetIdProvider);
    
    // If a dataset is selected, show its documents
    if (selectedDatasetId != null) {
      return _buildDocumentList(selectedDatasetId);
    }

    // Otherwise show the list of knowledge bases
    return _buildKnowledgeBaseList();
  }

  Widget _buildKnowledgeBaseList() {
    final kbAsync = ref.watch(knowledgeBasesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('KNOWLEDGE BASES'),
        const Divider(height: 1),
        Expanded(
          child: kbAsync.when(
            data: (kbs) => kbs.isEmpty
                ? _buildEmptyState('No Knowledge Bases', 'Create a new dataset to get started.')
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: kbs.length,
                    itemBuilder: (context, index) => _buildKBItem(kbs[index]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
          ),
        ),
        _buildActionToolbar(),
      ],
    );
  }

  final Set<String> _selectedDocIds = {};

  Widget _buildDocumentList(String datasetId) {
    final docsAsync = ref.watch(documentsProvider(datasetId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('DOCUMENTS'),
        const Divider(height: 1),
        if (_selectedDocIds.isNotEmpty) _buildBulkToolbar(datasetId),
        Expanded(
          child: docsAsync.when(
            data: (docs) => docs.isEmpty
                ? _buildEmptyState('No Documents', 'Upload files or add text to this knowledge base.')
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) => _buildDocumentItem(datasetId, docs[index]),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
          ),
        ),
        _buildActionToolbar(),
      ],
    );
  }

  Widget _buildBulkToolbar(String datasetId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedDocIds.length} items selected',
            style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _selectedDocIds.clear()),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _bulkDelete(datasetId),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              foregroundColor: Colors.redAccent,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkDelete(String datasetId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        title: const Text('Delete Documents', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete ${_selectedDocIds.length} documents?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(knowledgeApiServiceProvider);
        for (final id in _selectedDocIds) {
          await service.deleteDocument(datasetId: datasetId, documentId: id);
        }
        ref.invalidate(documentsProvider(datasetId));
        setState(() => _selectedDocIds.clear());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documents deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
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

  Widget _buildActionToolbar() {
    return Container(
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
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.layerGroup, size: 48, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKBItem(KnowledgeBase kb) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ref.read(selectedDatasetIdProvider.notifier).state = kb.id;
          if (widget.onSelectKB != null) widget.onSelectKB!(kb.name);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(FontAwesomeIcons.database, size: 16, color: Colors.orangeAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kb.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${kb.documentCount} Documents • ${kb.wordCount} Words',
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String datasetId, KnowledgeDocument doc) {
    final isSelected = _selectedDocIds.contains(doc.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (_selectedDocIds.isNotEmpty) {
            setState(() {
              if (isSelected) {
                _selectedDocIds.remove(doc.id);
              } else {
                _selectedDocIds.add(doc.id);
              }
            });
          } else {
            _showDocumentDetail(datasetId, doc);
          }
        },
        onLongPress: () {
          setState(() {
            _selectedDocIds.add(doc.id);
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              if (_selectedDocIds.isNotEmpty) ...[
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.blueAccent : Colors.white10,
                  size: 20,
                ),
                const SizedBox(width: 16),
              ],
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(FontAwesomeIcons.fileLines, size: 16, color: Colors.blueAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc.tokens} Tokens • ${doc.wordCount} Words',
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(doc.indexingStatus),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.greenAccent;
        break;
      case 'indexing':
        color = Colors.blueAccent;
        break;
      case 'error':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.white38;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showDocumentDetail(String datasetId, KnowledgeDocument doc) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF0F1116),
        child: DocumentDetailScreen(datasetId: datasetId, document: doc),
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
