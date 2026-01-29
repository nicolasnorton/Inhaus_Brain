import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inhaus_brain/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../providers/knowledge_provider.dart';
import '../models/knowledge_source.dart';
import '../models/knowledge_api_models.dart';
import '../screens/document_detail_screen.dart';
import 'add_source_dialog.dart';
import '../../campaigns/models/campaign.dart';
import '../../chat/providers/chat_provider.dart';

class KnowledgeLibraryWidget extends ConsumerStatefulWidget {
  final void Function(String kbName)? onSelectKB;
  
  const KnowledgeLibraryWidget({super.key, this.onSelectKB});

  @override
  ConsumerState<KnowledgeLibraryWidget> createState() => _KnowledgeLibraryWidgetState();
}

class _KnowledgeLibraryWidgetState extends ConsumerState<KnowledgeLibraryWidget> {
  void _onSourceAdded(KnowledgeSource source) {
    ref.read(knowledgeProvider.notifier).addSource(source);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Source added: ${source.title}')),
      );
    }
  }

  void _showAddSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSourceDialog(onSourceAdded: _onSourceAdded),
    );
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
        _buildHeader(AppLocalizations.of(context)!.knowledgeBases),
        const Divider(height: 1),
        Expanded(
          child: kbAsync.when(
            data: (kbs) => kbs.isEmpty
                ? _buildEmptyState(AppLocalizations.of(context)!.noKnowledgeBases, AppLocalizations.of(context)!.createDatasetMsg)
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
        _buildHeader(AppLocalizations.of(context)!.documentsLabel),
        const Divider(height: 1),
        if (_selectedDocIds.isNotEmpty) _buildBulkToolbar(datasetId),
        Expanded(
          child: docsAsync.when(
            data: (docs) => docs.isEmpty
                ? _buildEmptyState(AppLocalizations.of(context)!.noDocuments, AppLocalizations.of(context)!.uploadFilesMsg)
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
            AppLocalizations.of(context)!.itemsSelected(_selectedDocIds.length),
            style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _selectedDocIds.clear()),
            icon: const Icon(Icons.close, size: 16),
            label: Text(AppLocalizations.of(context)!.cancel),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _bulkDelete(datasetId),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(AppLocalizations.of(context)!.deleteLabel),
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
        title: Text(AppLocalizations.of(context)!.deleteDocuments, style: const TextStyle(color: Colors.white)),
        content: Text(AppLocalizations.of(context)!.deleteDocumentsConfirm(_selectedDocIds.length), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.deleteLabel, style: const TextStyle(color: Colors.redAccent)),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.documentsDeleted)));
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
      child: Center(
        child: ElevatedButton.icon(
          onPressed: _showAddSourceDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Add Source", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1)),
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const FaIcon(FontAwesomeIcons.layerGroup, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _showAddSourceDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Create First Knowledge Base"),
            ),
          ],
        ),
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
                      AppLocalizations.of(context)!.kbStats(kb.documentCount, kb.wordCount),
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
                      AppLocalizations.of(context)!.tokensWords(doc.tokens, doc.wordCount),
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
      case KnowledgeSourceType.audio:
        icon = FontAwesomeIcons.music;
        color = Colors.pinkAccent;
        break;
      case KnowledgeSourceType.youtube:
        icon = FontAwesomeIcons.youtube;
        color = Colors.redAccent;
        break;
      case KnowledgeSourceType.gmail:
        icon = Icons.mail_outline;
        color = Colors.orangeAccent;
        break;
      case KnowledgeSourceType.googleWorkspace:
        icon = FontAwesomeIcons.google;
        color = Colors.blueAccent;
        break;
      case KnowledgeSourceType.googleAds:
        icon = FontAwesomeIcons.google;
        color = Colors.blueAccent;
        break;
      case KnowledgeSourceType.ga4:
        icon = FontAwesomeIcons.chartLine;
        color = Colors.cyanAccent;
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
              tooltip: AppLocalizations.of(context)!.analyzeVisionAgent,
              onPressed: () {
                ref.read(chatProvider.notifier).sendMessage(
                  AppLocalizations.of(context)!.analyzeVisualAsset(source.title),
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
